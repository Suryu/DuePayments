//
//  AddPaymentViewController.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 31.03.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import UIKit

enum PaymentParentType {
    case normal
    case current
    case moveUp
}

struct PaymentParent {
    var id: Int
    var path: [Int]
    var displayedName: String
    var type: PaymentParentType
    
    init(id: Int, path: [Int], displayedName: String, type: PaymentParentType = .normal) {
        self.id = id
        self.path = path
        self.displayedName = displayedName
        self.type = type
    }
    
    static func current(with payment: Payment, path: [Int]) -> PaymentParent {
        let currentPaymentName = payment.isRoot ? "-" : "\("Current".localized) (\(payment.displayName))"
        return PaymentParent(id: payment.id,
                             path: path,
                             displayedName: currentPaymentName,
                             type: .current)
    }
    
    static func moveUp(with payment: Payment, path: [Int]) -> PaymentParent {
        var displayedName = "\("Move up".localized)"
        if !payment.isRoot {
            displayedName += " (\(payment.displayName))"
        }
        return PaymentParent(id: payment.id,
                             path: path,
                             displayedName: displayedName,
            type: .moveUp)
    }
}

class AddPaymentViewController: UITableViewController {
    
    static let DefaultRowHeight = 50.0
    
    enum ActionType {
        case add
        case edit
    }
    
    var actionType: ActionType = .add
    var payment: Payment?
    
    var parentPath: [Int] = []
    var parentPayment: Payment? {
        return PaymentProvider.shared.root.getPayment(atPath: parentPath)
    }
    var action: ((Payment, [Int]) -> ())?
    
    let currencyPickerDelegate = CurrencyPickerDelegateClass()
    var availableParents: [PaymentParent] = []
    var currentParentIndex: Int = 0
    
    var hasSubpayments: Bool {
        return payment?.hasSubpayments ?? false
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
    
    @IBOutlet weak var chooseSubpaymentButton: UIButton!
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
        
        if let payment = payment,
            actionType == .edit {
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .none
            
            nameTextField.text = payment.name
            
            if !payment.hasSubpayments {
                priceTextField.text = formatter.string(from: NSNumber(value: payment.value))
            }
            
            priceCell.isHidden = hasSubpayments
        }
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        doneButton.isEnabled = validate()
        
        if availableParents.count > 0 {
            parentPaymentNameLabel.text = availableParents.first?.displayedName ?? "-"
        }
        
        chooseSubpaymentButton.isHidden = (availableParents.count < 2)
    }
    
    @IBAction func nameDidChange(_ sender: UITextField) {
        doneButton.isEnabled = validate()
    }
    
    @IBAction func chooseParentPaymentTap(_ sender: UIButton) {
        view.endEditing(true)
        
        let picker = PickerLayerViewController.instantiate()
        for parent in availableParents {
            picker.options.append(PickerOption(title: parent.displayedName, object: parent, bolded: parent.type != .normal))
        }
        picker.defaultOptionIndex = currentParentIndex
        picker.callback = { [weak self] object in
            guard let object = object as? PaymentParent,
                let idx = self?.availableParents.index(where: { $0.id == object.id }) else {
                fatalError("object not a payment. WTF?")
            }
            self?.currentParentIndex = idx
            self?.parentPaymentNameLabel.text = self?.availableParents[idx].displayedName
            picker.close()
        }
        
        picker.show()
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
        if let payment = payment {
            result += " (\(payment.name))"
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
        
        if actionType == .add {
            payment = Payment.new()
        }
        
        guard var editedPayment = payment else {
            return
        }
        
        let parent = availableParents[currentParentIndex]
        
        editedPayment.name = nameTextField.text ?? ""
        editedPayment.value = priceTextField.text?.toPriceValue() ?? 0.0
        
        var didChange = true
        if let payment = payment,
            editedPayment.name == payment.name,
            editedPayment.value == payment.value,
            parent.type == .current {
            didChange = false
        }
    
        if didChange {
            payment = editedPayment
            action?(payment!, parent.path)
        }
        
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
