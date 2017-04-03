//
//  PaymentProvider.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 31.03.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON

enum SyncStatus {
    case ok
    case busyError
    case listIdNotEntered
    case isNotValid
    case errorCode(Int)
    case error
}

class PaymentProvider {
    
    //private static let jsonUrl = "https://api.myjson.com/bins/yax4f"
    //private static let metaJsonUrl = "https://api.myjson.com/bins/12vg1f"
    
    static let shared = PaymentProvider()    
    let metadata = Metadata()
    
    var root: Payment = Payment()
    var isBusy = false
    
    class Metadata {
        
        var last: JSON?
        
        var listId: String {
            return AppSettings.shared.listId
        }
        
        static func url(id: String) -> String {
            return "https://api.myjson.com/bins/\(id)"
        }
        
        var current: JSON {
            let dict: [String: Any] = [
                "lastUpload": [
                    "timestamp": Date().timeIntervalSince1970,
                    "user": UIDevice.current.name,
                ],
                "paymentsId": (last?["paymentsId"].string ?? "")
            ]
            return JSON(dict)
        }
        
        func download(completion: @escaping (SyncStatus, JSON?) -> ()) {
            
            guard listId != "" else {
                completion(.listIdNotEntered, nil)
                return
            }
            
            Alamofire.request(Metadata.url(id: listId)).response { response in
                print("Downloaded metadata")
                
                if let code = response.response?.statusCode, code != 200 {
                    print("Error: \(response.error)")
                    completion(.errorCode(code), nil)
                } else if let data = response.data,
                    let jsonString = String(data: data, encoding: String.Encoding.utf8) {
                    completion(.ok, JSON(parseJSON: jsonString))
                } else {
                    print("Error: \(response.error)")
                    completion(.error, nil)
                }
            }
        }
        
        func upload(completion: @escaping (SyncStatus, JSON?) -> ()) {
            guard listId != "" else {
                completion(.listIdNotEntered, nil)
                return
            }
            
            guard let dict = current.dictionaryObject else {
                print("invalid metadata for upload")
                completion(.error, nil)
                return
            }
            
            Alamofire.request(Metadata.url(id: listId), method: .put, parameters: dict, encoding: JSONEncoding.default).response { response in
            
                if response.error == nil {
                    print("Uploaded metadata")
                    completion(.ok, JSON(dict))
                } else if let code = response.response?.statusCode {
                    print("Error: \(response.error)")
                    completion(.errorCode(code), nil)
                } else {
                    print("Error: \(response.error)")
                    completion(.error, nil)
                }
                
            }
        }
        
    }
    
    func download(completion: @escaping (SyncStatus) -> ()) {
        guard !isBusy else {
            completion(.busyError)
            return
        }
        
        isBusy = true
        
        let finish = { [weak self] (status: SyncStatus) in
            self?.isBusy = false
            completion(status)
        }
        
        let downloadPayments = { [weak self] (paymentsId: String) in
            guard let strongSelf = self else {
                print("No strongself...")
                finish(.error)
                return
            }
            
            Alamofire.request(Metadata.url(id: paymentsId)).response { response in
                if let code = response.response?.statusCode, code != 200 {
                    print("Error: \(response.error)")
                    completion(.errorCode(code))
                } else if let data = response.data,
                    let jsonString = String(data: data, encoding: String.Encoding.utf8) {
                    strongSelf.root = Payment(jsonString: jsonString)
                    finish(.ok)
                } else {
                    print("Error: \(response.error)")
                    completion(.error)
                }
            }
        }
        
        metadata.download { [weak self] status, json in
            
            guard case .ok = status else {
                finish(status)
                return
            }
            
            guard let json = json else {
                finish(.isNotValid)
                return
            }
            
            guard let paymentsId = json["paymentsId"].string else {
                finish(.isNotValid)
                return
            }
            
            self?.metadata.last = json
            downloadPayments(paymentsId)
        }
    }
    
    func upload(completion: @escaping (SyncStatus) -> ()) {
        guard !isBusy else {
            completion(.busyError)
            return
        }
        
        isBusy = true
        
        let finish = { [weak self] (status: SyncStatus) in
            self?.isBusy = false
            completion(status)
        }
        
        guard metadata.last != nil else {
            UIAlertController(errorMessage: "PaymentsNotUpToDate".localized).present()
            finish(.error)
            return
        }
        
        let uploadPayments = { [weak self] (paymentsId: String) in
            
            guard let strongSelf = self else {
                print("No strongself...")
                finish(.error)
                return
            }
            
            Alamofire.request(Metadata.url(id: paymentsId), method: .put, parameters: strongSelf.root.toDictionary(), encoding: JSONEncoding.default).response { [weak self] response in
                
                if response.error != nil {
                    print("error from Alamofire put request")
                    finish(.error)
                    return
                }
                print("Uploaded")
                
                self?.metadata.upload { status, uploadedMd in
                    
                    guard case .ok = status else {
                        finish(status)
                        return
                    }
                    
                    guard let uploadedMd = uploadedMd else {
                        print("UploadedMd nil")
                        finish(.error)
                        return
                    }
                    
                    self?.metadata.last = uploadedMd
                    finish(.ok)
                }
            }
        }
        
        metadata.download { [weak self] status, md in
            
            guard case .ok = status else {
                finish(status)
                return
            }
            
            guard let md = md else {
                print("Could not download metadata.")
                finish(.isNotValid)
                return
            }
            guard let remoteTime = md["lastUpload"]["timestamp"].double else {
                print("No timestamp in metadata")
                finish(.isNotValid)
                return
            }
            
            guard let localTime = self?.metadata.last?["lastUpload"]["timestamp"].double else {
                print("no timestamp in last download metadata")
                finish(.isNotValid)
                return
            }
            
            guard let paymentsId = md["paymentsId"].string else {
                print("no paymentsId")
                finish(.isNotValid)
                return
            }
            
            if remoteTime <= localTime {
                uploadPayments(paymentsId)
            }
        }
    }
}
