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
    var payments: [Payment] = []
    var value = 0.0
    var totalValue: Double {
        return payments.reduce(value) { result, payment in
            return result + payment.totalValue
        }
    }

    private static var idCounter: Int = 0
    
    static func setCurrent(id: Int) {
        idCounter = id
    }
    
    static func nextId() -> Int {
        idCounter += 1
        return idCounter
    }
    
    
    init() {
        
    }
    
    init(name: String, value: Double) {
        self.name = name
        self.value = value
        self.payments = []
    }
    
    init(name: String, payments: [Payment]) {
        self.name = name
        self.value = 0.0
        self.payments = payments
    }
    
    mutating func fromDictionary(_ dict: [String: Any]) {
        id <-- (dict["id"] ?? Payment.nextId())
        name <-- dict["name"]
        payments <-- dict["payments"]
        value <-- dict["value"]
        
        Payment.idCounter = max(id, Payment.idCounter)
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        id --> dict["id"]
        name --> dict["name"]
        payments --> dict["payments"]
        value --> dict["value"]
        
        return dict
    }
    
    func getPayment(atPath path: [String]) -> Payment? {
        guard path.count != 0 else {
            return self
        }
        
        for payment in payments {
            if payment.name == path[0] {
                return payment.getPayment(atPath: Array(path.dropFirst()))
            }
        }
        
        return nil
    }
    
    @discardableResult
    mutating func add(newPayment: Payment, atPath path: [String]) -> Bool {
        if path.count == 0 {
            payments.append(newPayment)
            return true
        }
        
        guard let idx = payments.index(where: { $0.name == path[0] }) else {
            print("First path item in \(path) not found.")
            return false
        }
        
        return payments[idx].add(newPayment: newPayment, atPath: Array(path.dropFirst()))
    }
    
    @discardableResult
    mutating func remove(atPath path: [String]) -> Bool {
       
        guard path.count != 0 else {
            print("No items specified for removal.")
            return false
        }
        
        guard let idx = payments.index(where: { $0.name == path[0] }) else {
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
    mutating func replace(with payment: Payment, atPath path: [String]) -> Bool {
        
        guard path.count != 0 else {
            print("No items specified for removal.")
            return false
        }
        
        guard let idx = payments.index(where: { $0.name == path[0] }) else {
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
