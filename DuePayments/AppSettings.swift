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

// MARK: GeneralSettings

struct GeneralSettings: SettingsSet {
    let rawValue: Int
    
    static let updateAfterEachChange = GeneralSettings(rawValue: 1 << 0)
    
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
    
    func store() {
        generalSettings.store()
    }
    
    func load() {
        generalSettings.load()
    }
}
