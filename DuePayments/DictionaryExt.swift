//
//  Dictionary.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 02.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation

extension Dictionary where Value: Equatable {
    
    func key(for value: Value) -> Key? {
        return first(where: { $1 == value })?.key
    }
    
    
}
