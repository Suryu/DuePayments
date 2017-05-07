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
    
    // list
    @IBOutlet weak var changeListButton: UIButton!
    @IBOutlet weak var listNameLabel: UILabel!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var identifierStackView: UIStackView!
    @IBOutlet weak var renameListButton: UIButton!
    @IBOutlet weak var removeListButton: UIButton!
    
    // general
    @IBOutlet weak var lastUpdateInfo: UILabel!
    @IBOutlet weak var autoUpdateSwitch: UISwitch!
    
    @IBOutlet weak var separator1: UIView!
    @IBOutlet weak var separator2: UIView!
    
    override func viewDidLoad() {
        tableView.contentInset = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height, left: 0, bottom: 0, right: 0)
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        separator1.layer.cornerRadius = 2
        separator2.layer.cornerRadius = 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let timestamp = PaymentProvider.shared.metadata.current?["lastUpload"]["timestamp"].double
        let user = PaymentProvider.shared.metadata.current?["lastUpload"]["user"].string
        
        if let timestamp = timestamp, let user = user {
            setLastUpdateText(timestamp: timestamp, user: user)
        }
        
        loadSettings()
        
        settingsUpdated()
    }
    
    @IBAction func listIdEntered(_ sender: UITextField) {
        if let listId = sender.text, sender.text != "" {
            AppSettings.shared.listId = listId
            
            let lists = AppSettings.shared.lists
            if !lists.contains { $0.listID == listId } {
                
                let inputHandler = { listName in
                    AppSettings.shared.addList(name: listName, listId: listId)
                }
                
                inputAlert(title: "NewList".localized,
                           message: "EnterListName".localized,
                           placeholder: "ListNamePlaceholder".localized,
                           defaultText: "\("List".localized) \(AppSettings.shared.lists.count + 1)",
                    handler: inputHandler).present()
            }
            AppSettings.shared.store()
        }
    }
    
    @IBAction func updateAfterEachChangeSwitched(_ sender: UISwitch) {
        AppSettings.shared.generalSettings[.updateAfterEachChange] = autoUpdateSwitch.isOn
        AppSettings.shared.generalSettings.store()
    }
    
    @IBAction func listIdentifierHelpTapped(_ sender: UIButton) {
        UIAlertController(title: "ListIdentifier".localized, message: "ListIdentifierDescription".localized).present()
    }
    
    @IBAction func createNewListTapped(_ sender: UIButton) {
        
        let inputHandler: (String) -> () = { [weak self] listName in
            guard listName != "" else {
                return
            }
            
            self?.createNewList(name: listName)
        }
        
        inputAlert(title: "NewList".localized,
                   message: "EnterListName".localized,
                   placeholder: "ListNamePlaceholder".localized,
                   defaultText: "",
            handler: inputHandler).present()
        // default text: "\("List".localized) \(AppSettings.shared.lists.count + 1)"
    }
    
    @IBAction func addListTapped(_ sender: UIButton) {
        
        let inputHandler: (String, String) -> () = { [weak self] listID, listName in
            guard listID.characters.count > 0 && listName.characters.count > 0 else {
                // No name/ID specified
                return
            }
            
            if let listWithSameID = AppSettings.shared.lists.first(where: { $0.listID == listID }) {
                UIAlertController(errorMessage: "List already exists with name".localized + " \"\(listWithSameID.name)\"").present()
                return
            }
            
            AppSettings.shared.addList(name: listName, listId: listID)
            AppSettings.shared.listId = listID
            AppSettings.shared.store()
            self?.settingsUpdated()
        }
        
        let alert = UIAlertController(title: "AddList".localized,
                                      message: "AddListMessage".localized,
                                      preferredStyle: .alert)
        
        let addAction = UIAlertAction(title: "OK", style: .default, handler: { _ in inputHandler(alert.textFields?.first?.text ?? "", alert.textFields?.last?.text ?? "") })
        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        alert.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = .whileEditing
            textField.text = ""
            textField.placeholder = "AddListIDPlaceholder".localized
        })
        
        alert.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = .whileEditing
            textField.text = ""
            textField.placeholder = "AddListNamePlaceholder".localized
        })
        
        alert.present()
        
    }
    
    @IBAction func changeListTapped(_ sender: UIButton) {
        
        let lists = AppSettings.shared.lists
        let picker = PickerLayerViewController.instantiate()
        
        for list in lists {
            picker.options.append(PickerOption(title: list.name, object: list))
        }
        picker.defaultOptionIndex = lists.index { $0.listID == AppSettings.shared.listId }
        
        picker.callback = { [weak self] list in
            guard let list = list as? PaymentListEntity else {
                fatalError("Selected list is not PaymentListEntity")
            }
            
            AppSettings.shared.listId = list.listID
            AppSettings.shared.store()
            self?.settingsUpdated()
            picker.close()
        }
        picker.show()
        
    }
    
    @IBAction func renameListTapped(_ sender: UIButton) {
        
        let inputHandler: (String) -> () = { [weak self] listName in
            guard listName != "" else {
                return
            }
            
            AppSettings.shared.renameCurrentList(newName: listName)
            self?.settingsUpdated()
        }
        
        inputAlert(title: "Rename".localized,
                   message: "RenameMessage".localized,
                   placeholder: "ListNamePlaceholder".localized,
                   defaultText: "",
                   handler: inputHandler).present()
        
    }
    
    @IBAction func removeListTapped(_ sender: UIButton) {
        
        let listID = AppSettings.shared.listId
        guard let listEntity = AppSettings.shared.lists.first(where: { $0.listID == listID }) else {
            print("FATAL ERROR: List name does not exist!")
            return
        }
        let listName = listEntity.name
        
        let removeHandler = { [weak self] in
            AppSettings.shared.removeCurrentList()
            AppSettings.shared.listId = AppSettings.shared.lists.first?.listID ?? ""
            AppSettings.shared.store()
            self?.settingsUpdated()
        }
        
        // alert stuff
        
        let confirmAlert = UIAlertController(title: "AreYouSure".localized,
                                             message: "WillRemoveList".localized + " \"\(listName)\" (" + "ID".localized + ": \(listID))?",
            preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes".localized,
                                      style: .default,
                                      handler: { _ in removeHandler() })
        let noAction = UIAlertAction(title: "No".localized, style: .cancel)
        
        confirmAlert.addAction(yesAction)
        confirmAlert.addAction(noAction)
        confirmAlert.present()
    }
}

extension SettingsTableViewController {
    func loadSettings() {
        AppSettings.shared.load()
        autoUpdateSwitch.isOn = AppSettings.shared.generalSettings[.updateAfterEachChange]
    }
    
    func setLastUpdateText(timestamp: TimeInterval, user: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
        lastUpdateInfo.text = "\("LastUpdate".localized): \(dateString) (\(user))"
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
            
            AppSettings.shared.addList(name: listName, listId: listId)
            AppSettings.shared.listId = listId
            AppSettings.shared.store()
            
            self?.settingsUpdated()
        }
    }
    
    func inputAlert(title: String, message: String, placeholder: String, defaultText: String? = "", handler: @escaping (String) -> ()) -> UIAlertController {
        
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        
        let addAction = UIAlertAction(title: "OK", style: .default, handler: { _ in handler(alert.textFields?.first?.text ?? "") })
        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        alert.addTextField(configurationHandler: { textField in
            textField.clearButtonMode = .whileEditing
            textField.text = defaultText
            textField.placeholder = placeholder
        })
        
        return alert
    }
    
    func settingsUpdated() {
        let listID = AppSettings.shared.listId

        identifierStackView.isHidden = listID.isEmpty
        
        if let listEntity = AppSettings.shared.lists.first(where: { $0.listID == listID }) {
            listNameLabel.text = listEntity.name
            identifierLabel.text = "Identifier".localized + ": " + listID
        } else {
            // no lists available
            listNameLabel.text = "-"
            identifierLabel.text = ""
        }
        
        changeListButton.isEnabled = (AppSettings.shared.lists.count > 0)
        renameListButton.isEnabled = (AppSettings.shared.listId != "")
        removeListButton.isEnabled = (AppSettings.shared.listId != "")
    }
}
