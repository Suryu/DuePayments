//
//  DictionaryMappable.swift
//  yanosik
//
//  Created by Paweł Wojtkowiak on 24.02.2017.
//  Copyright © 2017 Dawid Nowicki. All rights reserved.
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// Two-way dictionary object mapping. Comprises of two protocols
// which allow your type to be mappable:
// - FlatDictionaryMappable
// - DictionaryMappable
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// ** FLAT DICTIONARY MAPPABLE
//   - does not require init(_:) to be implemented and thus
//   can easily be used with Core Data NSManagedObjects
//   - does not support nested DictionaryMappable
//
// * Requires implementation of:
//   mutating func fromDictionary(_ dict: [String: Any])
//   func toDictionary() -> [String: Any]
//
// ** DICTIONARY MAPPABLE
//   - does support nested dictionaries mapping to vars which are also mappable
//   - requires init(_:) to be implemented - has default implementation which
//   creates an object by calling fromDictionary(_:)
//
// * Requires implementation of:
//   mutating func fromDictionary(_ dict: [String: Any])
//   func toDictionary() -> [String: Any]
//   init()
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// To conform to either FlatDictionaryMappable or DictionaryMappable, your type
// is required to implement the following functions:
//
// mutating func fromDictionary(_ dict: [String: Any])
//   Responsible for writing dict contents to the object. Use <-- operator
//   to easily bridge between dictionary values and variables.
//
// func toDictionary() -> [String: Any]
//   Responsible for generating a dictionary containing data from your object.
//   Use --> operator to easily bridge between object data and dictionary values.
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// Usage example:
//
// struct myType: DictionaryMappable {
//
//     var example: String?
//
//     mutating func fromDictionary(_ dict: [String: Any]) {
//         example <-- dict["exampleKey"]
//     }
//
//     func toDictionary() -> [String: Any] {
//         var dict: [String: Any] = [:]
//         example --> dict["exampleKey"]
//     }
// }
//
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// Operators <-- and --> were introduced to ease bridging as well as for the sake of
// concise and clean code. Apart from basic type casting and optional handling,
// they also support nested DictionaryMappable object/array of objects handling
// and automatic Date() <-> timestamp conversion.
//
// Tested with: Int, Int?, NSNumber, NSNumber?, String, String?, [String], [String]?,
// [String: Int], [String: Int]?, Date?, DictionaryMappable struct inside DictionaryMappable,
// DictionaryMappable struct array inside DictionaryMappable
//
// Author: Paweł Wojtkowiak
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

import Foundation

public protocol FlatDictionaryMappable
{
    mutating func fromDictionary(_ dict: [String: Any])
    func toDictionary() -> [String: Any]
    
    // implemented by default
    mutating func fromDictionary(_ dict: Any?)
}

public protocol DictionaryMappable: FlatDictionaryMappable
{
    init()
    
    // is implemented with fromDictionary by default
    init(_ dict: [String: Any])
}

precedencegroup DictMapPrecedence
    {
    lowerThan: NilCoalescingPrecedence
}

infix operator <--: DictMapPrecedence
infix operator -->: DictMapPrecedence

public func <--(left: inout Any, right: Any)
{
    left = right
}

// DictionaryMappable objects

// from

public func <--<T: DictionaryMappable>(left: inout T?, right: Any?)
{
    if let unwrappedDict = right,
        let dict = unwrappedDict as? [String: Any]
    {
        left = T(dict)
    }
}

public func <--<T: DictionaryMappable>(left: inout T, right: Any?)
{
    if let unwrappedDict = right,
        let dict = unwrappedDict as? [String: Any]
    {
        left = T(dict)
    }
}

// to
public func --><T: DictionaryMappable>(left: T?, right: inout Any?)
{
    right = left?.toDictionary()
}

public func --><T: DictionaryMappable>(left: T, right: inout Any?)
{
    right = left.toDictionary()
}

// sequences of DictionaryMappable

// to

public func --><T: Sequence>(left: T?, right: inout Any?) where T.Iterator.Element: DictionaryMappable
{
    right = left?.map { $0.toDictionary() }
}

public func --><T: Sequence>(left: T, right: inout Any?) where T.Iterator.Element: DictionaryMappable
{
    right = left.map { $0.toDictionary() }
}

// from

public func <--<T: Sequence>(left: inout T?, right: Any?) where T.Iterator.Element: DictionaryMappable
{
    if let right = right as? Array<[String: Any]>,
        T.self is Array<T.Iterator.Element>.Type
    {
        var outputs: [T.Iterator.Element] = []
        
        for item in right
        {
            outputs.append(T.Iterator.Element.init(item))
        }
        
        left = outputs as? T
    }
}

public func <--<T: Sequence>(left: inout T, right: Any?) where T.Iterator.Element: DictionaryMappable
{
    if let right = right as? Array<[String: Any]>,
        T.self is Array<T.Iterator.Element>.Type
    {
        var outputs: [T.Iterator.Element] = []
        
        for item in right
        {
            outputs.append(T.Iterator.Element.init(item))
        }
        
        left = outputs as! T
    }
}

// flat mapping

public func <--<T>(left: inout T, right: Any?)
{
    mapDictionary(&left, right)
}

public func --><T>(left: T, right: inout Any?)
{
    mapDictionary(&right, left)
}

public extension Bool
{
    init?(_ valueOpt: NSNumber?)
    {
        guard let value = valueOpt else { return nil }
        self.init(value)
    }
}

public func mapDictionary<T>(_ left: inout T, _ right: Any?)
{
    if let right = right
    {
        if let newLeft = right as? T
        {
            if right is Date
            {
                left = Int((right as! Date).timeIntervalSince1970) as! T
            }
            else
            {
                left = newLeft
            }
        }
        else
        {
            if T.self == Optional<Date>.self && right is NSNumber
            {
                left = Date(timeIntervalSince1970: (right as! NSNumber).doubleValue as TimeInterval) as! T
            }
            else
            {
                print("⛔️ Could not convert value of type \(type(of: right)) to \(T.self)")
            }
        }
    }
}

extension FlatDictionaryMappable
{
    mutating func fromDictionary(_ dict: Any?)
    {
        if let dict = dict,
            dict is [String: Any]
        {
            fromDictionary(dict as! [String: Any])
        }
    }
}

extension DictionaryMappable
{
    init(_ dict: [String: Any])
    {
        self.init()
        fromDictionary(dict)
    }
}
