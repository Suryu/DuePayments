//
//  PickerLayerViewController.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 01.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import UIKit

class PickerLayerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var pickerView: UIView!
    
    var options: [String] = []
    var callback: ((Int, String) -> ())?
    
    @IBOutlet weak var picker: UIPickerView!
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print("tapped")
//    }
    
    override func viewDidLoad() {
        picker.dataSource = self
        picker.delegate = self
        
        pickerView.layer.borderColor = UIColor.darkGray.cgColor
        pickerView.layer.borderWidth = 1.0
        pickerView.layer.cornerRadius = 14.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pickerView.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.pickerView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //MARK: Delegates
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.black
        pickerLabel.text = options[row]
        // pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 15)
        pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 14) // In this use your custom font
        pickerLabel.textAlignment = .center
        return pickerLabel
    }
    @IBAction func okTapped(_ sender: Any) {
        callback?(picker.selectedRow(inComponent: 0), options[picker.selectedRow(inComponent: 0)])
    }
}
