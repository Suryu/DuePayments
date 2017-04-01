//
//  Payments.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 31.03.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON

class Payments {
    
    private static let jsonUrl = "https://api.myjson.com/bins/yax4f"
    private static let metaJsonUrl = "https://api.myjson.com/bins/182vnb"
    
    static let shared = Payments()
    
    var root: Payment?
    var lastDownloadMetadata: JSON?
    
    class Metadata {
        
        static var current: JSON {
            let dict: [String: Any] = ["lastUpload": [
                "timestamp": Date().timeIntervalSince1970,
                "user": UIDevice.current.name,
                ]
            ]
            return JSON(dict)
        }
        
        static func download(completion: @escaping (JSON?) -> ()) {
            
            Alamofire.request(Payments.metaJsonUrl).response { response in
                print("Downloaded metadata")
                
                if let data = response.data,
                    let jsonString = String(data: data, encoding: String.Encoding.utf8) {
                    completion(JSON(parseJSON: jsonString))
                } else {
                    print("Error: \(response.error)")
                    completion(nil)
                }
            }
        }
        
        static func upload(completion: @escaping (JSON?) -> ()) {
            guard let dict = current.dictionaryObject else {
                print("invalid metadata for upload")
                completion(nil)
                return
            }
            
            Alamofire.request(Payments.metaJsonUrl, method: .put, parameters: dict, encoding: JSONEncoding.default).response { response in
                print("Uploaded metadata")
                completion(JSON(dict))
            }
        }
        
    }
    
    func download(completion: @escaping (Bool) -> ()) {
        Alamofire.request(Payments.jsonUrl).response { response in
            if let data = response.data,
                let jsonString = String(data: data, encoding: String.Encoding.utf8) {
                self.root = Payment(jsonString: jsonString)
                Metadata.download { [weak self] json in
                    
                    guard let json = json else {
                        self?.downloadErrorAlert()
                        completion(false)
                        return
                    }
                    
                    self?.lastDownloadMetadata = json
                    completion(true)
                }
            } else {
                print("Error: \(response.error)")
                self.downloadErrorAlert()
                completion(false)
            }
        }
    }
    
    func upload(completion: @escaping (Bool) -> ()) {
        guard let rootDict = root?.toDictionary() else {
            print("Could not upload - root does not exist")
            uploadErrorAlert()
            return
        }
        
        if lastDownloadMetadata != nil {
            Metadata.download { [weak self] md in
                
                guard let md = md else {
                    print("Could not download metadata.")
                    self?.uploadErrorAlert()
                    completion(false)
                    return
                }
                guard let remoteTime = md["lastUpload"]["timestamp"].double else {
                    print("No timestamp in metadata")
                    self?.uploadErrorAlert()
                    completion(false)
                    return
                }
                
                guard let localTime = self?.lastDownloadMetadata?["lastUpload"]["timestamp"].double else {
                    print("no timestamp in last download metadata")
                    self?.uploadErrorAlert()
                    completion(false)
                    return
                }
                
                if remoteTime <= localTime {
                    Alamofire.request(Payments.jsonUrl, method: .put, parameters: rootDict, encoding: JSONEncoding.default).response { response in
                        
                        if response.error != nil {
                            self?.uploadErrorAlert()
                            print("error from Alamofire put request")
                            return
                        }
                        print("Uploaded")
                        Metadata.upload { uploadedMd in
                            
                            guard let uploadedMd = uploadedMd else {
                                self?.uploadErrorAlert()
                                print("UploadedMd nil")
                                return
                            }
                            
                            self?.lastDownloadMetadata = uploadedMd
                            completion(true)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false)
                        UIApplication.showAlert(error: "PaymentsNotUpToDate".localized)
                        return
                    }
                }
            }
        }
    }
    
    func uploadErrorAlert() {
        UIApplication.showAlert(error: "CouldNotUploadPayments".localized)
    }
    
    func downloadErrorAlert() {
        UIApplication.showAlert(error: "CouldNotDownloadPayments".localized)
    }
}
