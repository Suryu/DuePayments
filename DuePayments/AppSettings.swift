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
    static let lists = DefaultsKey<[String: Any]>("lists")
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
    var lists: [String: String] = [:]
    var listId = ""
    
    func addList(name: String, listId: String) {
        lists[name] = listId
    }
    
    func store() {
        generalSettings.store()
        
        Defaults[.lists] = lists as [String: Any]
        Defaults[.listId] = listId
    }
    
    func load() {
        generalSettings.load()
        
        listId = Defaults[.listId] ?? ""
        lists = Defaults[.lists] as! [String: String]
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
