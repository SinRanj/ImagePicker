//
//  ViewController.swift
//  OpalImagePicker
//
//  Created by Kristos Katsanevas on 1/15/17.
//  Copyright © 2017 Opal Orange LLC. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController,OpalImagePickerControllerDelegate {

    @IBOutlet weak var pickerView: OpalImageViewPicker!
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.maximumSelectionsAllowed = 2
        pickerView.shouldResetItems = true
        pickerView.selectionImage = UIImage(named: "checkmark2")
        pickerView.allowedMediaTypes = Set([PHAssetMediaType.image])
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingImages images: [UIImage]) {
        
    }
}
