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
    /// Maximum photo selections allowed in picker (zero or fewer means unlimited).
    var maximumSelectionsAllowed:Int! = 2 {
        didSet {
            initializer()
        }
    }
    /// Allowed Media Types that can be fetched. See `PHAssetMediaType`
    var allowedMediaTypes: Set<PHAssetMediaType>? = Set([PHAssetMediaType.image])  {
        didSet {
            initializer()
        }
    }
    /// Checks if selected items should resets after `maximumSelectionsAllowed` reached.
    var shouldResetItems:Bool = true {
        didSet{
            initializer()
        }
    }
    /// Custom first selected image (slide_up).
    var selectionImage:UIImage! = UIImage(named: "slide_up") {
        didSet{
            initializer()
        }
    }
    /// Custom second selected image (double_slide_up).
    var doubleSelectionImage:UIImage! = UIImage(named: "double_slide_up") {
        didSet{
            initializer()
        }
    }
    
    /// Limitation on memory cache (128 MB by default)
    var totalCacheLimit = 128000000 {
        didSet{
            initializer()
        }
    }
    /// Number of assets cache (100 assets by default)
    var cacheCountLimit = 100 {
        didSet{
            initializer()
        }
    }
    
    /// Navigation background color
    var navigationColor:UIColor? = UIColor.white {
        didSet{
            initializer()
        }
    }
    
    /// View background color
    @IBInspectable var _viewBackgroundColor: UIColor? {
        get {
          return UIColor(cgColor: self.layer.borderColor!)
        }set {
          self.imagePicker.backgroundColor = newValue
        }
    }
    var viewBackgroundColor:UIColor? = UIColor.white {
        didSet{
            initializer()
        }
    }
    
    var titleColor:UIColor? = UIColor.black {
        didSet{
            initializer()
        }
    }
    
    var navigationButtonColor:UIColor? = UIColor.blue {
        didSet{
            initializer()
        }
    }
    
    var doneButtonTitle:String? = "Done" {
        didSet{
            initializer()
        }
    }
    
    var cancelButtonTitle:String? = "Cancel" {
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
        root = imagePicker.viewControllers[0] as? OpalImagePickerRootViewController

        imagePicker.imagePickerDelegate = self
        let parent = self.parentViewController
        parent!.addChild(imagePicker)
        imagePicker.viewControllers[0].view.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        let imagePickerView = root.view
        self.addSubview(imagePickerView!)
        
        constraintBuilder(imagePickerView: imagePickerView!)
        configurations(imagePicker: self.imagePicker)
        
        imagePicker.viewControllers[0].didMove(toParent: parent!)
        
    }
    func openModally(imagePicker:OpalImagePickerController, isExternal:Bool = false, items:[UIImage]?, externalTitle:String = "External") {
        imagePicker.imagePickerDelegate = self
        configurations(imagePicker: imagePicker)
        
        imagePicker.isExternal = isExternal
        imagePicker.externalItems = items
        imagePicker.externalTitle = externalTitle
        parentViewController?.present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: Configurations
    private func configurations(imagePicker:OpalImagePickerController){
        imagePicker.maximumSelectionsAllowed = maximumSelectionsAllowed
        imagePicker.allowedMediaTypes = allowedMediaTypes
        root.shouldResetItems = shouldResetItems
        imagePicker.selectionImage = selectionImage
        imagePicker.doubleSelectionImage = doubleSelectionImage
        root.cacheCountLimit = cacheCountLimit
        root.totalCacheLimit = totalCacheLimit
        imagePicker.doneButtonText = doneButtonTitle
        imagePicker.cancelButtonText = cancelButtonTitle
        imagePicker.backgroundColor = viewBackgroundColor
        imagePicker.navigationColor = navigationColor
        imagePicker.titleColor = titleColor
        imagePicker.navigatioButtonColor = navigationButtonColor
        
    }
    
    // MARK: Constraints
    private func constraintBuilder(imagePickerView:UIView){
        imagePickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: imagePickerView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0).isActive = true
        
    }
    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingExternalImages images: [UIImage]) {
        delegate?.imagePicker?(picker, didFinishPickingExternalImages: images)
    }
    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingImages images: [UIImage]) {
        if picker == imagePicker{
            delegate?.imagePicker?(picker, didFinishPickingImages: images)
        }    }
    
    func imagePicker(_ picker: OpalImagePickerController, didFinishPickingAssets assets: [PHAsset]) {
        if picker != imagePicker {
            if assets.count != 0 {
                let images = PHAsset.fetchAssets(with: root.fetchOptions)
                var isSelected = false
                images.enumerateObjects { (asset, id, pointer) in
                    if asset == assets.first! {
                        for i in self.root.selectedIndexPaths.enumerated() {
                            if i.element == IndexPath(item: id, section: 0) {
                                isSelected = true
                                break
                            }
                        }
                        if isSelected {
                            let cell = self.root.collectionView?.cellForItem(at: IndexPath(item: id, section: 0)) as? ImagePickerCollectionViewCell
                            cell?.setDoubleSelected(true, animated: true)
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
        else {
            delegate?.imagePicker?(picker, didPickAssets: assets)
        }
        
    }
}

