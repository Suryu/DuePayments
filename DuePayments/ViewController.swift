//
//  ViewController.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 31.03.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import UIKit

class PaymentsTableViewController: UIViewController {
    private typealias `Self` = PaymentsTableViewController
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addPaymentButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var refreshControl: UIRefreshControl!
    
    var path: [String] = []
    var payment: Payment? {
        return Payments.shared.root?.getPayment(atPath: path)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Payments.shared.root == nil {
            fetchPayments()
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
        
        navigationItem.backBarButtonItem?.title = "Back".localized
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        paymentsUpdated(upload: false)
    }
    
    func refresh(_ sender:AnyObject) {
        fetchPayments()
    }

}

extension PaymentsTableViewController {
    
    @IBAction func addPayment(_ sender: UIBarButtonItem) {
        let vc = AddPaymentViewController.instantiate(storyboard: "Main", identifier: "AddPaymentViewController")
        vc.path = path
        vc.actionType = .add
        vc.callback = { [weak self] payment, parentPath in
            guard let strongSelf = self else {
                return
            }
            
            guard let parentPayment = Payments.shared.root?.getPayment(atPath: parentPath) else {
                print("This payment does not exist!")
                return
            }
            
            if parentPath.count > strongSelf.path.count && parentPayment.value > 0.0 {
                // value was not 0 - move to subpayments with the same name
                var newParentPayment = parentPayment
                newParentPayment.value = 0.0
                var oldParentPayment = parentPayment
                oldParentPayment.payments = []
                
                newParentPayment.payments.append(oldParentPayment)
                Payments.shared.root?.replace(with: newParentPayment, atPath: parentPath)
            }
            Payments.shared.root?.add(newPayment: payment, atPath: parentPath)
            strongSelf.paymentsUpdated()
            
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func deleteItem(row: Int) {
        guard let name = payment?.payments[row].name else {
            return
        }
        
        var pathToRemove = path
        pathToRemove.append(name)
        let removedItem = Payments.shared.root?.remove(atPath: pathToRemove)
        if removedItem == nil {
            print("No items removed - path not found?")
        }
        
        paymentsUpdated()
    }
    
    func editItem(row: Int) {
        guard let payment = payment else {
            return
        }
        var oldPath = path
        oldPath.append(payment.payments[row].name)
        
        let vc = AddPaymentViewController.instantiate(storyboard: "Main", identifier: "AddPaymentViewController")
        vc.path = path
        vc.actionType = .edit
        vc.editedPayment = payment.payments[row]
        vc.callback = { [weak self] editedPayment, parentPath in
            
            guard let strongSelf = self else {
                return
            }
            
            if parentPath == strongSelf.path {
                Payments.shared.root?.replace(with: editedPayment, atPath: oldPath)
            } else {
                Payments.shared.root?.remove(atPath: oldPath)
                
                guard let parentPayment = Payments.shared.root?.getPayment(atPath: parentPath) else {
                    print("This payment does not exist!")
                    return
                }
                
                if parentPath.count > strongSelf.path.count && parentPayment.value > 0.0 {
                    // value was not 0 - move to subpayments with the same name
                    var newParentPayment = parentPayment
                    newParentPayment.value = 0.0
                    var oldParentPayment = parentPayment
                    oldParentPayment.payments = []
                    
                    newParentPayment.payments.append(oldParentPayment)
                    Payments.shared.root?.replace(with: newParentPayment, atPath: parentPath)
                }
                
                Payments.shared.root?.add(newPayment: editedPayment, atPath: parentPath)
            }
            
            strongSelf.paymentsUpdated()
            
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func fetchPayments() {
        activityIndicator.startAnimating()
        Payments.shared.download() { [weak self] in
            
            self?.activityIndicator.stopAnimating()
            self?.refreshControl.endRefreshing()
            self?.paymentsUpdated(upload: false)
        }
    }
    
    func paymentsUpdated(upload: Bool = true) {
        
        let finish = { [weak self] in
            if self?.payment == nil || self?.payment?.name == "root" {
                self?.title = "\("Total".localized): \(self?.payment?.totalValue.toCurrencyString(localeIdentifier: "pl_PL") ?? "-")"
            } else {
                self?.title = "\(self?.payment?.name ?? "") (\(self?.payment?.totalValue.toCurrencyString(localeIdentifier: "pl_PL") ?? "-"))"
            }
        }
        
        tableView.reloadData()
        
        if upload {
            startBlockingTask()
            
            Payments.shared.upload() { [weak self] in
                self?.stopBlockingTask()
                
                if let payment = self?.payment,
                    payment.payments.count == 0,
                    let navigationController = self?.navigationController,
                    navigationController.viewControllers.count > 1 {
                    
                    if let topVC = navigationController.viewControllers[navigationController.viewControllers.count - 1] as? PaymentsTableViewController {
                        topVC.paymentsUpdated(upload: false)
                    }
                    _ = navigationController.popViewController(animated: true)
                }
                
                finish()
            }
        } else {
            finish()
        }
    }
    
    func startBlockingTask() {
        guard UIApplication.shared.keyWindow?.viewWithTag(1) == nil else {
            // already loading
            return
        }
        
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.black
        view.alpha = 0.6
        view.tag = 1
        let loader = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        loader.hidesWhenStopped = true
        loader.startAnimating()
        loader.tag = 2
        loader.sizeToFit()
        loader.center = view.center
        view.addSubview(loader)
        UIApplication.shared.keyWindow?.addSubview(view)
    }
    
    func stopBlockingTask() {
        let view = UIApplication.shared.keyWindow?.viewWithTag(1)
        let indicator = UIApplication.shared.keyWindow?.viewWithTag(2) as? UIActivityIndicatorView
        indicator?.stopAnimating()
        
        view?.removeFromSuperview()
    }
}

extension PaymentsTableViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payment?.payments.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCell") as? PaymentCell else {
            fatalError("Reusable cell 'PaymentCell' not available")
        }
        
        guard let payment = payment else {
            fatalError("This payment does not exist.")
        }
        
        guard indexPath.row < payment.payments.count else {
            fatalError("Trying to produce a cell for non existing payment")
        }
        
        let currentPayment = payment.payments[indexPath.row]
        
        cell.nameLabel.text = currentPayment.name
        
        let totalValue = currentPayment.totalValue
        if totalValue > 0 {
            cell.priceLabel.text = totalValue.toCurrencyString(localeIdentifier: "pl_PL")
        } else {
            cell.priceLabel.text = ""
        }
        cell.accessoryType = currentPayment.payments.isEmpty ? .none : .disclosureIndicator
        cell.selectionStyle = currentPayment.payments.isEmpty ? .none : .default
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let payment = payment else {
            return
        }
        
        guard indexPath.row < payment.payments.count else {
            return
        }
        
        let currentPayment = payment.payments[indexPath.row]
        
        guard currentPayment.payments.count > 0 else {
            return
        }
        
        let vc = PaymentsTableViewController.instantiate(storyboard: "Main", identifier: "PaymentsTableViewController")
        vc.path = path
        vc.path.append(currentPayment.name)
        print(vc.path)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteItem = UITableViewRowAction(style: .destructive, title: "Delete".localized) { [weak self] (action, indexPath) in
            self?.deleteItem(row: indexPath.row)
        }
        let editItem = UITableViewRowAction(style: .normal, title: "Edit".localized) { [weak self] (action, indexPath) in
            self?.editItem(row: indexPath.row)
        }
        return [deleteItem, editItem]
    }
}

