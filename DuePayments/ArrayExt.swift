//
//  ArrayExt.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 20.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation

extension Array {
    func appending(_ e: Element) -> [Element] {
        var array = self
        array.append(e)
        return array
    }
    
    func withoutLast() -> [Element] {
        var array = self
        array.removeLast()
        return array
    }
}
