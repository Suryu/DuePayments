//
//  AddPaymentViewController.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 31.03.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import UIKit

class AddPaymentViewController: UITableViewController {
    
    static let DefaultRowHeight = 50.0
    
    enum ActionType {
        case add
        case edit
    }
    
    var actionType: ActionType = .add
    var path: [String] = []
    var initialName: String = ""
    var editedPayment: Payment = Payment()
    var payment: Payment? {
        return PaymentProvider.shared.root.getPayment(atPath: path)
    }
    var callback: ((Payment, [String]) -> ())?
    
    let currencyPickerDelegate = CurrencyPickerDelegateClass()
    var availableParents: [String] {
        var prettyName = (payment?.name ?? "None".localized)
        if prettyName == "root" {
            prettyName = "None".localized
        }
        
        var parents = ["<\(prettyName)>"]
        parents.append(contentsOf: payment?.payments.map { $0.name } ?? [])
        
        if actionType == .edit {
            if let idx = parents.index(of: initialName) {
                parents.remove(at: idx)
            }
            if path.count > 0 {
                parents.insert("<\("MoveUp".localized)>", at: 1)
            }
        }
        return parents
    }
    var currentParentRow = 0
    var picker: PickerLayerViewController?
    
    var hasSubpayments: Bool {
        return editedPayment.payments.count > 0
    }
    
    var rowsVisibility: [Bool] {
        return [true, !hasSubpayments, true]
    }
    
    var rowHeights: [Double] {
        let defaultHeights = rowsVisibility.map {
            $0 ? AddPaymentViewController.DefaultRowHeight : 0.0
        }
        return defaultHeights
    }
    
    @IBOutlet weak var priceCell: UITableViewCell!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var currencyPicker: UIPickerView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var parentPaymentNameLabel: UILabel!
    
    override func viewDidLoad() {
        currencyPicker.dataSource = currencyPickerDelegate
        currencyPicker.delegate = currencyPickerDelegate
        
        nameTextField.delegate = self
        priceTextField.delegate = self
        
        if actionType == .edit {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            
            initialName = editedPayment.name
            nameTextField.text = editedPayment.name
            
            if editedPayment.payments.count == 0 {
                priceTextField.text = formatter.string(from: NSNumber(value: editedPayment.value))
            }
            
            priceCell.isHidden = hasSubpayments
        }
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        doneButton.isEnabled = validate()
        picker = PickerLayerViewController.instantiate(storyboard: "Main", identifier: "pickerLayer")
        
        if availableParents.count > 0 {
            parentPaymentNameLabel.text = availableParents[0]
        }
    }
    
    @IBAction func nameDidChange(_ sender: UITextField) {
        doneButton.isEnabled = validate()
    }
    
    @IBAction func chooseParentPaymentTap(_ sender: UIButton) {
        guard let picker = picker else {
            return
        }
        view.endEditing(true)
        picker.options = availableParents
        picker.callback = { [weak self] index, option in
            self?.currentParentRow = index
            self?.parentPaymentNameLabel.text = self?.availableParents[index]
            self?.picker?.view.removeFromSuperview()
            self?.picker?.removeFromParentViewController()
        }
        
        //picker.view.center.y = UIScreen.main.bounds.size.height / 2
//        picker.view.frame.origin.y = 0.0
            //picker.view.center.y -= navigationController?.navigationBar.frame.size.height ?? 0.0
        
        if let parentViewController = UIApplication.shared.keyWindow?.rootViewController {
            
            picker.willMove(toParentViewController: parentViewController)
            picker.beginAppearanceTransition(true, animated: true)
            parentViewController.view.addSubview(picker.view)
            picker.endAppearanceTransition()
            parentViewController.addChildViewController(picker)
            picker.didMove(toParentViewController: parentViewController)
            
            parentViewController.view.bringSubview(toFront: picker.view)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if rowHeights.count > indexPath.row {
            return CGFloat(rowHeights[indexPath.row])
        } else {
            return CGFloat(AddPaymentViewController.DefaultRowHeight)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var result = "Details".localized
        if initialName != "" {
            result += " (\(initialName))"
        }
        return result
    }
}

extension String {
    func toPriceValue() -> Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        if let price = formatter.number(from: self)
        {
            return price.doubleValue
        }
        
        return nil
    }
}

extension AddPaymentViewController {
    func validate() -> Bool {
//        guard priceCell.isHidden || priceTextField.text?.toPriceValue() != nil else {
//            return false
//        }
        
        guard let nameText = nameTextField.text,
            nameText != "" else {
            return false
        }
        
        return true
    }
}

extension AddPaymentViewController {
    
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        guard validate() else {
            return
        }
        
        var childPath = path
        
        editedPayment.name = nameTextField.text ?? ""
        editedPayment.value = priceTextField.text?.toPriceValue() ?? 0.0
        
        if (currentParentRow != 0) {
            if actionType == .edit && currentParentRow == 1 && path.count > 0 {
                childPath.removeLast()
            } else {
                childPath.append(availableParents[currentParentRow])
            }
        }
        
        if actionType == .add {
            var nodePath = childPath
            nodePath.append(editedPayment.name)
            guard PaymentProvider.shared.root.getPayment(atPath: nodePath) == nil else {
                UIAlertController(errorMessage: "PaymentExists".localized).present()
                return
            }
        }
        
        callback?(editedPayment, childPath)
        _ = navigationController?.popViewController(animated: true)
    }
    
}

extension AddPaymentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField === nameTextField {
            priceTextField.becomeFirstResponder()
        }
        
        return true
    }
}

class CurrencyPickerDelegateClass: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let currentLocale = Locale(identifier: "pl_PL")
    var availableCurrencies: [String?] = []
    
    override init() {
        super.init()
        availableCurrencies = [currentLocale.currencySymbol]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableCurrencies.count
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //MARK: Delegates
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return availableCurrencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.black
        pickerLabel.text = availableCurrencies[row]
        // pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 15)
        pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 16) // In this use your custom font
        pickerLabel.textAlignment = .right
        return pickerLabel
    }

}
