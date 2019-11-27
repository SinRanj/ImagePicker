//
//  OpalImageViewPicker.swift
//  OpalImagePicker
//
//  Created by Sina on 11/25/19.
//  Copyright © 2019 Opal Orange LLC. All rights reserved.
//

import UIKit
import Photos

class OpalImageViewPicker: UIView,OpalImagePickerControllerDelegate{
    
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
    var doubleSelectionImage:UIImage! = UIImage(named: "checkmark") {
        didSet{
            initializer()
        }
    }
    
    var selectionButtonTitle:String = "Select" {
        didSet{
            initializer()
        }
    }
    
    private var root:OpalImagePickerRootViewController!
    
    private let imagePicker = OpalImagePickerController()
    private var selectedImage:UIImage!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func initializer(){
        imagePicker.imagePickerDelegate = self
        let parent = self.parentViewController
        parent!.addChild(imagePicker)
        imagePicker.viewControllers[0].view.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        root = imagePicker.viewControllers[0] as? OpalImagePickerRootViewController
        let imagePickerView = root.view
        self.addSubview(imagePickerView!)
        
        constraintBuilder(imagePickerView: imagePickerView!)
        configurations(imagePicker: self.imagePicker)
        
        imagePicker.viewControllers[0].didMove(toParent: parent!)
        
        navigationSelection()
    }
    
    private func navigationSelection(){
        let doneButton = UIBarButtonItem(title: selectionButtonTitle, style: .done, target: self, action: #selector(selectionTapped))
        parentViewController?.navigationItem.rightBarButtonItem = doneButton
    }
    @objc func selectionTapped() {
        let imagePicker = OpalImagePickerController()
        imagePicker.imagePickerDelegate = self
        imagePicker.selectionImage = selectionImage
        imagePicker.doubleSelectionImage = doubleSelectionImage
        configurations(imagePicker: imagePicker)
        parentViewController?.present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: Configurations
    private func configurations(imagePicker:OpalImagePickerController){
        imagePicker.maximumSelectionsAllowed = maximumSelectionsAllowed
        imagePicker.allowedMediaTypes = allowedMediaTypes
        root.shouldResetItems = shouldResetItems
        imagePicker.selectionImage = selectionImage
        imagePicker.doubleSelectionImage = doubleSelectionImage
    }
    
    // MARK: Constraints
    private func constraintBuilder(imagePickerView:UIView){
        imagePickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0).isActive = true
        
    }
    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingImages images: [UIImage]) {
        if picker == imagePicker{
            delegate?.imagePicker?(picker, didFinishPickingImages: images)
        }    }
    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingAssets assets: [PHAsset]) {
        if picker != imagePicker {
            let images = PHAsset.fetchAssets(with: root.fetchOptions)
            images.enumerateObjects { (asset, id, pointer) in
                if asset == assets.first! {
                    for i in self.root.selectedIndexPaths.enumerated() {
                        if i.element == IndexPath(item: id, section: 0) {
                            break
                        }
                    }
                        if self.root.maximumSelectionsAllowed <= self.root.selectedIndexPaths.count {
                            self.root.collectionView?.deselectItem(at: self.root.selectedIndexPaths.first!, animated: true)
                            self.root.set(image: nil, indexPath: self.root.selectedIndexPaths.first!, isExternal: self.root.collectionView == self.root.externalCollectionView)
                            
                        }
                        
                        self.root.set(image: asset.image, indexPath: IndexPath(item: id, section: 0), isExternal: self.root.collectionView == self.root.externalCollectionView)
                        self.root.collectionView?.selectItem(at: IndexPath(item: id, section: 0), animated: false, scrollPosition: UICollectionView.ScrollPosition.top)
                        self.root.doneTapped()
                        print("")
                }
            }
        }
        
    }
}

