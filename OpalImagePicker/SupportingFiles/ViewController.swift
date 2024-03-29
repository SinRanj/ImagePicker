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
    @IBOutlet weak var imageView2: UIImageView!
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var pickerView: OpalImageViewPicker!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.doneButtonTitle = "Done"
        pickerView.cancelButtonTitle = "Cancel"
        pickerView.navigationColor = UIColor.black
        pickerView.viewBackgroundColor = UIColor.black
        pickerView.titleColor = UIColor.white
        pickerView.navigationButtonColor = UIColor.white
        pickerView.isExternal = true
        let items = [UIImage(named: "slide_up")!,UIImage(named: "double_slide_up")!]
        pickerView.externalItems = items
        let doneButton = UIBarButtonItem(title: "Select", style: .done, target: self, action: #selector(selectionTapped))
        navigationItem.rightBarButtonItem = doneButton
    }
    
    @objc func selectionTapped(){
        let imagePicker = OpalImagePickerController()
//        let items = [UIImage(named: "slide_up")!,UIImage(named: "double_slide_up")!]
        imagePicker.permissionColor = UIColor.white
        imagePicker.permissionText = "Please Allow Photo Access *"
        imagePicker.settingText = "Open Settings *"
        imagePicker.settingColor = UIColor.green
        pickerView.openModally(imagePicker: imagePicker, isExternal: false, items: nil, externalTitle: "External")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingExternalImages images: [UIImage]) {
        print("")
    }
    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingImages images: [UIImage]) {
        switch images.count {
        case 0:
            imageView1.image = nil
            imageView2.image = nil
        case 1:
            imageView1.image = images[0]
            imageView2.image = nil
        case 2:
            imageView1.image = images[0]
            imageView2.image = images[1]
        default:
            break;
        }
    }
    func imagePicker(_ picker: OpalImagePickerController, didPickAssets assets: [PHAsset]) {
        
    }
}
