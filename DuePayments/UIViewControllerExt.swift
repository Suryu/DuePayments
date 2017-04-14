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
    
    func startBlockingActivity() {
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
    
    func stopBlockingActivity() {
        let view = UIApplication.shared.keyWindow?.viewWithTag(1)
        let indicator = UIApplication.shared.keyWindow?.viewWithTag(2) as? UIActivityIndicatorView
        indicator?.stopAnimating()
        
        view?.removeFromSuperview()
    }
}
