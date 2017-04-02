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

class SettingsTableViewController: UITableViewController {
    
    // TODO:
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
    
    @IBOutlet weak var lastUpdateInfo: UILabel!
    
    override func viewDidLoad() {
        tableView.contentInset = UIEdgeInsets(top: UIApplication.shared.statusBarFrame.size.height, left: 0, bottom: 0, right: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let timestamp = Payments.shared.lastDownloadMetadata?["lastUpload"]["timestamp"].double
        let user = Payments.shared.lastDownloadMetadata?["lastUpload"]["user"]
        
        if let timestamp = timestamp, let user = user {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateString = dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
            lastUpdateInfo.text = "\("LastUpdate".localized): \(dateString) (\(user))"
        }
    }
    
    @IBAction func updateAfterEachChangeSwitched(_ sender: UISwitch) {
        AppSettings.shared.updateAfterEachChange = sender.isOn
    }
}
