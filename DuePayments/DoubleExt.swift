//
//  DoubleExt.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 01.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation

extension Double {
    
    func toCurrencyString(localeIdentifier: String) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: localeIdentifier)
        return formatter.string(from: self as NSNumber)
    }
    
}
