//
//  PickerLayerViewController.swift
//  DuePayments
//
//  Created by Paweł Wojtkowiak on 01.04.2017.
//  Copyright © 2017 Paweł Wojtkowiak. All rights reserved.
//

import Foundation
import UIKit

struct PickerOption {
    var title: String
    var object: Any
    var bolded: Bool
    
    init(title: String, object: Any, bolded: Bool = false) {
        self.title = title
        self.object = object
        self.bolded = bolded
    }
}

class PickerLayerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var pickerView: UIView!
    
    // name: ID
    var options: [PickerOption] = []
    var defaultOptionIndex: Int?
    var callback: ((Any) -> ())?
    
    @IBOutlet weak var picker: UIPickerView!
    
    override func viewDidLoad() {
        picker.dataSource = self
        picker.delegate = self
        
        pickerView.layer.borderColor = UIColor.darkGray.cgColor
        pickerView.layer.borderWidth = 1.0
        pickerView.layer.cornerRadius = 14.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pickerView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        
        if let idx = defaultOptionIndex {
            picker.selectRow(idx, inComponent: 0, animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.1,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: { [weak self] in
                        self?.pickerView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: nil)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //MARK: Delegates
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return options[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.black
        
        let option = options[row]

        let attrs = [NSFontAttributeName : option.bolded ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 14)]
        let attrText = NSMutableAttributedString(string: option.title, attributes:attrs)
        pickerLabel.attributedText = attrText
        pickerLabel.textAlignment = .center
        return pickerLabel
    }
    @IBAction func okTapped(_ sender: Any) {
        let row = picker.selectedRow(inComponent: 0)
        callback?(options[row].object)
    }
}
