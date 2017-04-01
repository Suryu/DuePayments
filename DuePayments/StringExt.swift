//
//  StringExt.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 01.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
