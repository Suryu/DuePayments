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


// bup: http://myjson.com/x8lq3

enum SyncStatus {
    case ok
    case busyError
    case listIdNotEntered
    case isNotValid
    case errorCode(Int)
    case error
}

extension SyncStatus {
    
    static let genericError = "GenericError"
    
    var errorMessage: String? {
        switch self {
        case .busyError, .ok:
            return nil
        case .listIdNotEntered:
            return "ListIdNotEntered".localized
        case .isNotValid:
            return "ListInvalid".localized
        case .errorCode(404), .errorCode(500):
            return "ListDoesNotExist".localized
        default:
            return "GenericError"
        }
    }
}


class JSONRequest {

    static var alamofireManager: Alamofire.SessionManager = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        return Alamofire.SessionManager(configuration: config)
    }()

    static func get(url: URLConvertible, handler: @escaping (Alamofire.DefaultDataResponse) -> Swift.Void) {
        alamofireManager.request(url).response(completionHandler: handler)
    }
    
    static func put(_ dict: [String: Any], url: URLConvertible, handler: @escaping (Alamofire.DefaultDataResponse) -> Swift.Void) {
        alamofireManager.request(url, method: .put, parameters: dict, encoding: JSONEncoding.default).response(completionHandler: handler)
    }
    
    static func post(_ dict: [String: Any], url: URLConvertible, handler: @escaping (Alamofire.DefaultDataResponse) -> Swift.Void) {
        alamofireManager.request(url, method: .post, parameters: dict, encoding: JSONEncoding.default).response(completionHandler: handler)
    }
    
}

class PaymentProvider {
    
    //private static let jsonUrl = "https://api.myjson.com/bins/yax4f"
    //private static let metaJsonUrl = "https://api.myjson.com/bins/12vg1f"
    static let baseURL = "https://api.myjson.com/bins"
    
    static let shared = PaymentProvider()    
    let metadata = Metadata()
    
    var root: Payment = Payment()
    var isBusy = false
    
    static func url(id: String) -> String {
        return "\(PaymentProvider.baseURL)/\(id)"
    }
    
    class Metadata {
        
        var last: JSON?
        
        var listId: String {
            return AppSettings.shared.listId
        }
        
        var current: JSON {
            return Metadata.toJSON(paymentsId: (last?["paymentsId"].string ?? ""))
        }
        
        static func toJSON(paymentsId: String) -> JSON {
            let dict: [String: Any] = [
                "lastUpload": [
                    "timestamp": Date().timeIntervalSince1970,
                    "user": UIDevice.current.name,
                ],
                "paymentsId": paymentsId
            ]
            return JSON(dict)
        }

        func download(completion: @escaping (SyncStatus, JSON?) -> ()) {
            
            guard listId != "" else {
                completion(.listIdNotEntered, nil)
                return
            }
            
            JSONRequest.get(url: PaymentProvider.url(id: listId)) { response in
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
            
            JSONRequest.put(dict, url: PaymentProvider.url(id: listId)) { response in
            
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
            
            JSONRequest.get(url: PaymentProvider.url(id: paymentsId)) { response in
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
            
            JSONRequest.put(strongSelf.root.toDictionary(), url: PaymentProvider.url(id: paymentsId)) { [weak self] response in
                
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
    
    private func createNewList(dict: [String: Any], completion: @escaping (String?) -> ()) {
        
        guard let url = URL(string: PaymentProvider.baseURL) else {
            print("Cannot convert base URL to URL")
            completion(nil)
            return
        }
        
        JSONRequest.post(dict, url: url) { response in
            
            guard response.error == nil,
                let responseData = response.data,
                let responseString = String(data: responseData, encoding: String.Encoding.utf8),
                let responseDict = JSON(parseJSON: responseString).dictionaryObject,
                let newIdUri = responseDict["uri"] as? String,
                let newListId = URL(string: newIdUri)?.lastPathComponent else {
                    print("Could not create list")
                    completion(nil)
                    return
            }
            
            completion(newListId)
        }
    }
    
    func createNewPaymentsList(completion: @escaping (String?) -> ()) {
        
        let emptyPaymentsDict: [String: Any] = ["root": [:]]
        
        createNewList(dict: emptyPaymentsDict) { [weak self] listId in
            
            guard let strongSelf = self,
                let listId = listId else {
                print("No self or no list ID...")
                completion(nil)
                return
            }
            
            strongSelf.createMetadata(paymentsId: listId, completion: completion)
        }
    }
    
    private func createMetadata(paymentsId: String, completion: @escaping (String?) -> ()) {
        
        guard let metadataDict = Metadata.toJSON(paymentsId: paymentsId).dictionaryObject else {
            print("Metadata not a dictionary")
            completion(nil)
            return
        }
        
        createNewList(dict: metadataDict) { listId in
            
            guard let listId = listId else {
                print("No self or no list ID...")
                completion(nil)
                return
            }
            
            completion(listId)
        }
    }
}
