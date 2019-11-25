//
//  OpalImageViewPicker.swift
//  OpalImagePicker
//
//  Created by Sina on 11/25/19.
//  Copyright © 2019 Opal Orange LLC. All rights reserved.
//

import UIKit
import Photos

class OpalImageViewPicker: UIView{
    
    weak var delegate: OpalImagePickerControllerDelegate? {
        didSet {
            initializer()
        }
    }
    
    var maximumSelectionsAllowed:Int! = 5 {
        didSet {
            initializer()
        }
    }
    
    var allowedMediaTypes: Set<PHAssetMediaType>? = Set([PHAssetMediaType.image])  {
        didSet {
            initializer()
        }
    }
    var shouldResetItems:Bool = false {
        didSet{
            initializer()
        }
    }
    
    var selectionImage:UIImage! = UIImage(named: "checkmark") {
        didSet{
            initializer()
        }
    }
    
    private var root:OpalImagePickerRootViewController!
    
    private let imagePicker = OpalImagePickerController()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func initializer(){
        imagePicker.imagePickerDelegate = delegate
        let parent = self.parentViewController
        parent!.addChild(imagePicker)
        imagePicker.viewControllers[0].view.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        root = imagePicker.viewControllers[0] as? OpalImagePickerRootViewController
        let imagePickerView = root.view
        self.addSubview(imagePickerView!)
        
        constraintBuilder(imagePickerView: imagePickerView!)
        configurations()

        imagePicker.viewControllers[0].didMove(toParent: parent!)
    }
    
    // MARK: Configurations
    private func configurations(){
        imagePicker.maximumSelectionsAllowed = maximumSelectionsAllowed
        imagePicker.allowedMediaTypes = allowedMediaTypes
        root.shouldResetItems = shouldResetItems
        imagePicker.selectionImage = selectionImage
    }
    
    // MARK: Constraints
    private func constraintBuilder(imagePickerView:UIView){
        imagePickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0).isActive = true
                NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0).isActive = true
        
    }
}
