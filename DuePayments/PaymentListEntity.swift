//
//  PaymentList.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 24.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class PaymentListsModel {
    static let shared = PaymentListsModel()
    var currentOrderID: Int?
    
    func add(_ list: PaymentListEntity) {
        let realm = try! Realm()
        try! realm.write {
            realm.add(list)
        }
    }
    
    func add(listID: String, name: String) {
        if currentOrderID == nil {
            currentOrderID = load().count
        }
        
        guard let currentOrderID = currentOrderID else {
            fatalError("wtf? db not initialized? currentorderid not available")
        }
        
        add(PaymentListEntity(listID: listID, orderID: currentOrderID, name: name))
        self.currentOrderID = currentOrderID + 1
    }
    
    func rename(withID listID: String, newName: String) {
        if let list = load().first(where: { $0.listID == listID }) {
            let realm = try! Realm()
            try! realm.write {
                list.name = newName
            }
        }
    }
    
    func delete(withID listID: String) {
        if let list = load().first(where: { $0.listID == listID }) {
            let realm = try! Realm()
            try! realm.write {
                realm.delete(list)
            }
        }
    }
    
    func load() -> [PaymentListEntity] {
        let realm = try! Realm()
        let objects = Array(realm.objects(PaymentListEntity.self))
        return objects
//        let nonDuplicateObjects = removeDuplicates(objects)
//        
//        try! realm.write {
//            realm.deleteAll()
//            realm.add(nonDuplicateObjects)
//        }
//        return nonDuplicateObjects
    }
    
//    func removeDuplicates(_ src: [PaymentListEntity]) -> [PaymentListEntity] {
//        var nonDuplicateObjects: [PaymentListEntity] = []
//        
//        for obj in src {
//            var exists = false
//            for objd in nonDuplicateObjects {
//                if obj.listID == objd.listID {
//                    exists = true
//                    break
//                }
//            }
//            if !exists {
//                nonDuplicateObjects.append(PaymentListEntity(obj))
//            }
//        }
//        
//        return nonDuplicateObjects
//    }
}

class PaymentListEntity: Object {
    // unique key = listID
    dynamic var listID = ""
    dynamic var orderID = 0
    dynamic var name = ""

    convenience init(listID: String, orderID: Int, name: String) {
        self.init()
        self.listID = listID
        self.orderID = orderID
        self.name = name
    }
    
    convenience init(_ obj: PaymentListEntity) {
        self.init()
        self.listID = obj.listID
        self.orderID = obj.orderID
        self.name = obj.name
    }
}
