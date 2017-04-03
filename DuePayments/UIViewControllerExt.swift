//
//  UIViewControllerExt.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 31.03.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    static func instantiate(storyboard: String, identifier: String) -> Self {
        return instantiateHelper(storyboard: storyboard, identifier: identifier)
    }
    
    private static func instantiateHelper<T>(storyboard: String, identifier: String) -> T {
        let storyboard = UIStoryboard(name: storyboard, bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: identifier) as! T
    }
    
}
