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
        
        static func upload(completion: @escaping (JSON) -> ()) {
            guard let dict = current.dictionaryObject else {
                print("invalid metadata for upload")
                return
            }
            
            Alamofire.request(Payments.metaJsonUrl, method: .put, parameters: dict, encoding: JSONEncoding.default).response { response in
                print("Uploaded metadata")
                completion(JSON(dict))
            }
        }
        
    }
    
    func download(completion: @escaping () -> ()) {
        Alamofire.request(Payments.jsonUrl).response { response in
            if let data = response.data,
                let jsonString = String(data: data, encoding: String.Encoding.utf8) {
                self.root = Payment(jsonString: jsonString)
                Metadata.download { json in
                    self.lastDownloadMetadata = json
                }
            } else {
                print("Error: \(response.error)")
            }
            completion()
        }
    }
    
    func upload(completion: @escaping () -> ()) {
        guard let rootDict = root?.toDictionary() else {
            print("Could not upload - root does not exist")
            return
        }
        
        if lastDownloadMetadata != nil {
            Metadata.download { md in
                guard let remoteTime = md?["lastUpload"]["timestamp"].double else {
                    return
                }
                
                guard let localTime = self.lastDownloadMetadata?["lastUpload"]["timestamp"].double else {
                    return
                }
                
                if remoteTime <= localTime {
                    Alamofire.request(Payments.jsonUrl, method: .put, parameters: rootDict, encoding: JSONEncoding.default).response { response in
                        print("Uploaded")
                        Metadata.upload { uploadedMd in
                            self.lastDownloadMetadata = uploadedMd
                            completion()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completion()
                        self.showNeedsRefreshAlert()
                    }
                }
            }
        }
    }
    
    func showNeedsRefreshAlert() {
        let alertController = UIAlertController(title: "Error".localized, message: "PaymentsNotUpToDate".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in alertController.dismiss(animated: true, completion: nil) }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}
