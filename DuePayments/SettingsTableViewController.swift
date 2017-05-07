//
//  SettingsTableViewController.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 01.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class SettingsTableViewController: UITableViewController, UITextFieldDelegate {
    
    // TODO:
    // * list identifiers list
    // * list names
    // * allow non-unique names (use identifiers for entries?)
    // * currency choosing
    // * myjson.com addresses
    //     provide metadata address (which would also contain payments address)
    //     to join someone's payments.
    //     ? Maybe allow some encoded payments address url which could be decoded
    //     using somepassword (also in metadata)
    //     ? Maybe allow encoded paths (require password)?
    // * Allow different sync options? Manual only? Timed?
    // * Allow auto payment creation
    // * Allow payment cell moving or some hierarchy manager
    // * Payment reminders - local notification
    // * Payment categorization
    // * History, favourites? (quick payment links)
    
    @IBOutlet weak var listIdTextField: UITextField!
    @IBOutlet weak var lastUpdateInfo: UILabel!
    @IBOutlet weak var autoUpdateSwitch: UISwitch!
    
    override func viewDidLoad() {
        tableView.contentInset = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height, left: 0, bottom: 0, right: 0)
        listIdTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let timestamp = PaymentProvider.shared.metadata.current?["lastUpload"]["timestamp"].double
        let user = PaymentProvider.shared.metadata.current?["lastUpload"]["user"].string
        
        if let timestamp = timestamp, let user = user {
            setLastUpdateText(timestamp: timestamp, user: user)
        }
        
        loadSettings()
    }
    
    func loadSettings() {
        AppSettings.shared.load()
        autoUpdateSwitch.isOn = AppSettings.shared.generalSettings[.updateAfterEachChange]
        listIdTextField.text = AppSettings.shared.listId
    }
    
    func setLastUpdateText(timestamp: TimeInterval, user: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
        lastUpdateInfo.text = "\("LastUpdate".localized): \(dateString) (\(user))"
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == listIdTextField {
            if let listId = textField.text, textField.text != "" {
                AppSettings.shared.listId = listId
                AppSettings.shared.store()
            }
            
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    func createNewList(name: String?) {
        startBlockingActivity()
        PaymentProvider.shared.createNewPaymentsList { [weak self] listId in
            
            self?.stopBlockingActivity()
            
            guard let listId = listId else {
                UIAlertController(errorMessage: "CouldNotCreatePayments".localized).present()
                return
            }
            
            var listName = name ?? listId
            listName = (listName != "" ? listName : listId)
            
            self?.listIdTextField.text = listId
            AppSettings.shared.addList(name: listName, listId: listId)
            AppSettings.shared.listId = listId
            AppSettings.shared.store()
        }
    }
}

// MARK: IBActions

extension SettingsTableViewController {
    
    @IBAction func updateAfterEachChangeSwitched(_ sender: UISwitch) {
        AppSettings.shared.generalSettings[.updateAfterEachChange] = autoUpdateSwitch.isOn
        AppSettings.shared.generalSettings.store()
    }
    
    @IBAction func listIdentifierHelpTapped(_ sender: UIButton) {
        UIAlertController(title: "ListIdentifier".localized, message: "ListIdentifierDescription".localized).present()
    }
    
    @IBAction func createNewListTapped(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "NewList".localized,
                                      message: "EnterListName".localized,
                                      preferredStyle: .alert)
        
        let addAction = UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.createNewList(name: alert.textFields?.first?.text)
        })
        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        alert.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = .whileEditing
            textField.text = "\("List".localized) \(AppSettings.shared.lists.count + 1)"
            textField.placeholder = "ListNamePlaceholder".localized
        })
        
        alert.present()
    }
    
    @IBAction func ManageListsTapped(_ sender: UIButton) {
        
        let lists = AppSettings.shared.lists
        let picker = PickerLayerViewController.instantiate()
        
        for list in lists {
            picker.options.append(PickerOption(title: list.name, object: list))
        }
        picker.defaultOptionIndex = lists.index { $0.listID == listIdTextField.text }
        
        picker.callback = { [weak self] list in
            guard let list = list as? PaymentListEntity else {
                fatalError("Selected list is not PaymentListEntity")
            }
            
            self?.listIdTextField.text = list.listID
            AppSettings.shared.listId = list.listID
            AppSettings.shared.store()
            picker.close()
        }
        picker.show()
        
    }
}
