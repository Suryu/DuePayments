//
//  UIAlertControllerExt.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 03.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertAction {
    static let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
    static let cancel = UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil)
}

extension UIAlertController {
    
    convenience init(errorMessage: String) {
        self.init(title: "Error".localized, message: errorMessage, preferredStyle: .alert)
        addAction(.ok)
    }
    
    convenience init(title: String, message: String) {
        self.init(title: title, message: message, preferredStyle: .alert)
        addAction(.ok)
    }
    
    convenience init(title: String, message: String, actions: [UIAlertAction]) {
        self.init(title: title, message: message, preferredStyle: .alert)
        actions.forEach { self.addAction($0) }
    }
    
    func present() {
        UIApplication.shared.keyWindow?.rootViewController?.present(self, animated: true, completion: nil)
    }
}
