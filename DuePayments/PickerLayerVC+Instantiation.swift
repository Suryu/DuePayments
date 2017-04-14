//
//  File.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 09.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import UIKit

extension PickerLayerViewController {
    static func instantiate() -> PickerLayerViewController {
        return self.instantiate(storyboard: "Main", identifier: "pickerLayer")
    }
    
    func show() {
        if let parentViewController = UIApplication.shared.keyWindow?.rootViewController {
            
            willMove(toParentViewController: parentViewController)
            beginAppearanceTransition(true, animated: true)
            parentViewController.view.addSubview(view)
            endAppearanceTransition()
            parentViewController.addChildViewController(self)
            didMove(toParentViewController: parentViewController)
            
            parentViewController.view.bringSubview(toFront: self.view)
        }
    }
    
    func close() {
        view.removeFromSuperview()
        removeFromParentViewController()
    }
}
