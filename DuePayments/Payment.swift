//
//  Payment.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 31.03.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Payment: DictionaryMappable {
    
    var id: Int = 0
    var name: String = ""
    var displayName: String {
        return isRoot ? "None".localized : name
    }
    var payments: [Payment] = []
    var value = 0.0
    var totalValue: Double {
        return payments.reduce(value) { result, payment in
            return result + payment.totalValue
        }
    }
    var hasSubpayments: Bool {
        return payments.count > 0
    }
    var isRoot: Bool {
        return id == 0
    }

    private static var idCounter: Int = 0
    
    static func newRoot() -> Payment {
        var payment = Payment()
        payment.id = 0
        payment.name = "root"
        return payment
    }
    
    static func nextId() -> Int {
        defer { idCounter += 1 }
        return idCounter
    }
    
    static func new() -> Payment {
        var payment = Payment()
        payment.id = idCounter
        idCounter += 1
        return payment
    }
    
    init() {        
    }
    
    mutating func fromDictionary(_ dict: [String: Any]) {
        id <-- (dict["id"] ?? Payment.nextId())
        name <-- dict["name"]
        payments <-- dict["payments"]
        value <-- dict["value"]
        
        Payment.idCounter = max(id + 1, Payment.idCounter)
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        id --> dict["id"]
        name --> dict["name"]
        payments --> dict["payments"]
        value --> dict["value"]
        
        return dict
    }
    
    func findPath(forId id: Int, searchIn currentPath: [Int] = []) -> [Int]? {
        var result: [Int]?
        
        payments.forEach {
            if $0.id == id {
                result = currentPath
                result?.append(id)
                return
            } else if $0.payments.count > 0 {
                var subpath = currentPath
                subpath.append($0.id)
                if let findResult = findPath(forId: id, searchIn: subpath) {
                    result = findResult
                    return
                }
            }
        }
        
        return result
    }
    
    func getPayment(atPath path: [Int]) -> Payment? {
        guard path.count != 0 else {
            return self
        }
        
        for payment in payments {
            if payment.id == path[0] {
                return payment.getPayment(atPath: Array(path.dropFirst()))
            }
        }
        
        return nil
    }
    
    @discardableResult
    mutating func add(newPayment: Payment, atPath path: [Int]) -> Bool {
        if path.count == 0 {
            payments.append(newPayment)
            return true
        }
        
        guard let idx = payments.index(where: { $0.id == path[0] }) else {
            print("First path item in \(path) not found.")
            return false
        }
        
        return payments[idx].add(newPayment: newPayment, atPath: Array(path.dropFirst()))
    }
    
    @discardableResult
    mutating func remove(atPath path: [Int]) -> Bool {
       
        guard path.count != 0 else {
            print("No items specified for removal.")
            return false
        }
        
        guard let idx = payments.index(where: { $0.id == path[0] }) else {
            print("First path item in \(path) not found.")
            return false
        }
        
        if path.count == 1 {
            payments.remove(at: idx)
            return true
        }

        return payments[idx].remove(atPath: Array(path.dropFirst()))
    }
    
    @discardableResult
    mutating func replace(with payment: Payment, atPath path: [Int]) -> Bool {
        
        guard path.count != 0 else {
            print("No items specified for removal.")
            return false
        }
        
        guard let idx = payments.index(where: { $0.id == path[0] }) else {
            print("First path item in \(path) not found.")
            return false
        }
        
        if path.count == 1 {
            payments[idx] = payment
            return true
        }
        
        return payments[idx].replace(with: payment, atPath: Array(path.dropFirst()))
    }
    
    init(jsonString: String) {
        fromJSON(string: jsonString)
    }
}

extension Payment {
    mutating func loadTest() {
        guard let jsonFileUrl = Bundle.main.url(forResource: "test", withExtension: "json") else {
            print("Could not load test json from bundle")
            return
        }
        
        guard let testJsonString = try? String(contentsOf: jsonFileUrl) else {
            print("Could not load test json contents")
            return
        }
        
        fromJSON(string: testJsonString)
    }
    
    mutating func fromJSON(string: String) {
        
        guard let payment = JSON(parseJSON: string).dictionaryObject else {
            if JSON(parseJSON: string) == JSON.null {
                print("Not a JSON")
            } else {
                print("JSON is not a dictionary")
            }
            
            return
        }
        
        fromDictionary(payment)
    }
}
