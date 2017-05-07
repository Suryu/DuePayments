//
//  AppSettings.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 02.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation

extension DefaultsKeys {
    static let updateAfterEachChange = DefaultsKey<Bool?>("updateAfterEachChange")
    static let listId = DefaultsKey<String?>("listIdentifier")
}

// MARK: GeneralSettings

struct GeneralSettings: SettingsSet {
    let rawValue: Int
    
    static let updateAfterEachChange = GeneralSettings(rawValue: 1 << 0)
    static var listId = ""
    
    func store() {
        Defaults[.updateAfterEachChange] = self[.updateAfterEachChange]
    }
    
    mutating func load() {
        self[.updateAfterEachChange] = Defaults[.updateAfterEachChange] ?? true
    }
}

// MARK: AppSettings
final class AppSettings {
    
    static let shared = AppSettings()
    var generalSettings: GeneralSettings = [.updateAfterEachChange]
    var lists: [PaymentListEntity] = []
    var listId = ""
    var incrementer: Int = 0
    
    func addList(name: String, listId: String) {
        // old way
        //lists[name] = listId
        // new way
        PaymentListsModel.shared.add(listID: listId, name: name)
        loadLists()
    }
    
    func store() {
        generalSettings.store()
        
        // old way
        //Defaults[.lists] = lists as [String: Any]
        Defaults[.listId] = listId
    }
    
    func load() {
        generalSettings.load()
        
        listId = Defaults[.listId] ?? ""
        loadLists()
    }
    
    func loadLists() {
        lists = PaymentListsModel.shared.load()
        
        print("Loaded lists: \(lists)")
    }
}


// MARK: Settings protocol

protocol SettingsSet: OptionSet {}

extension SettingsSet {
    subscript(_ member: Element) -> Bool {
        get {
            return self.contains(member)
        }
        set {
            if newValue && !self.contains(member) {
                self.insert(member)
            }
            
            if !newValue && self.contains(member) {
                self.remove(member)
            }
        }
    }
}
