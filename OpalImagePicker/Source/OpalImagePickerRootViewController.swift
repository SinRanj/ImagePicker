//
//  OpalImagePickerRootViewController.swift
//  OpalImagePicker
//
//  Created by Kristos Katsanevas on 1/16/17.
//  Copyright © 2017 Opal Orange LLC. All rights reserved.
//

import UIKit
import Photos

/// Image Picker Root View Controller contains the logic for selecting images. The images are displayed in a `UICollectionView`, and multiple images can be selected.
open class OpalImagePickerRootViewController: UIViewController,MenuDelegate {
    
    
    
    /// Delegate for Image Picker. Notifies when images are selected (done is tapped) or when the Image Picker is cancelled.
    open weak var delegate: OpalImagePickerControllerDelegate?
    
    /// Configuration to change Localized Strings
    open var configuration: OpalImagePickerConfiguration? {
        didSet {
            configuration?.updateStrings = configurationChanged
            if let configuration = self.configuration {
                configurationChanged(configuration)
            }
        }
    }
    
    /// `UICollectionView` for displaying photo library images
    open weak var collectionView: UICollectionView?
    
    /// `UICollectionView` for displaying external images
    open weak var externalCollectionView: UICollectionView?
    
    /// `UIToolbar` to switch between Photo Library and External Images.
    open lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()
    
    /// `UISegmentedControl` to switch between Photo Library and External Images.
    open lazy var tabSegmentedControl: UISegmentedControl = {
        let tabSegmentedControl = UISegmentedControl(items: [NSLocalizedString("Library", comment: "Library"), NSLocalizedString("External", comment: "External")])
        tabSegmentedControl.addTarget(self, action: #selector(segmentTapped(_:)), for: .valueChanged)
        tabSegmentedControl.selectedSegmentIndex = 0
        return tabSegmentedControl
    }()
    
    /// Custom Tint Color for overlay of selected images.
    open var selectionTintColor: UIColor? {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    /// Custom Tint Color for selection image (checkmark).
    open var selectionImageTintColor: UIColor? {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    /// Custom selection image (checkmark).
    open var selectionImage: UIImage? {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    /// Custom double selection image (checkmark).
    open var doubleSelectionImage: UIImage? {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    /// Allowed Media Types that can be fetched. See `PHAssetMediaType`
    open var allowedMediaTypes: Set<PHAssetMediaType>? {
        didSet {
            updateFetchOptionPredicate()
        }
    }
    
    /// Allowed MediaSubtype that can be fetched. Can be applied as `OptionSet`. See `PHAssetMediaSubtype`
    open var allowedMediaSubtypes: PHAssetMediaSubtype? {
        didSet {
            updateFetchOptionPredicate()
        }
    }
    
    /// Maximum photo selections allowed in picker (zero or fewer means unlimited).
    open var maximumSelectionsAllowed: Int = -1
    open var shouldResetItems: Bool = false
    
    /// Page size for paging through the Photo Assets in the Photo Library. Defaults to 100. Must override to change this value. Only works in iOS 9.0+
    public let pageSize = 10000
    
    var photoAssets: PHFetchResult<PHAsset> = PHFetchResult()
    weak var doneButton: UIBarButtonItem?
    weak var cancelButton: UIBarButtonItem?
    
    internal var collectionViewLayout: OpalImagePickerCollectionViewLayout? {
        return collectionView?.collectionViewLayout as? OpalImagePickerCollectionViewLayout
    }
    
    internal lazy var fetchOptions: PHFetchOptions = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return fetchOptions
    }()
    
    @available(iOS 9.0, *)
    internal var fetchLimit: Int {
        get {
            return fetchOptions.fetchLimit
        }
        set {
            fetchOptions.fetchLimit = newValue
        }
    }
    
    internal var shouldShowTabs: Bool {
        guard let imagePicker = navigationController as? OpalImagePickerController else { return false }
        return delegate?.imagePickerNumberOfExternalItems?(imagePicker) != nil
    }
    
    private var photosCompleted = 0
    var savedImages: [UIImage] = []
    private var imagesDict: [IndexPath: UIImage] = [:]
    private var showExternalImages = false
    var selectedIndexPaths: [IndexPath] = []
    private var externalSelectedIndexPaths: [IndexPath] = []
    
    private lazy var cache: NSCache<NSIndexPath, NSData> = {
        let cache = NSCache<NSIndexPath, NSData>()
        cache.totalCostLimit = 128000000 //128 MB
        cache.countLimit = 100 // 100 images
        return cache
    }()
    
    private var selectedCollection : PHAssetCollection!
    public var shouldSelectAlbumes:Bool = false
    var menu : Menu!
    private var titleView:UILabel!
    private var items:[menuItem]!
    private var albumModel:[AlbumModel]!
    private var status:Bool?
    fileprivate weak var rightExternalCollectionViewConstraint: NSLayoutConstraint?
    
    /// Initializer
    public required init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    /// Initializer (Do not use this View Controller in Interface Builder)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Cannot init \(String(describing: OpalImagePickerRootViewController.self)) from Interface Builder")
    }
    
    private func setup() {
        guard let view = view else { return }
        fetchPhotos()
        
        let collectionView = UICollectionView(frame: view.frame, collectionViewLayout: OpalImagePickerCollectionViewLayout())
        setup(collectionView: collectionView)
        view.addSubview(collectionView)
        self.collectionView = collectionView
        
        var constraints: [NSLayoutConstraint] = []
        if shouldShowTabs {
            setupTabs()
            let externalCollectionView = UICollectionView(frame: view.frame, collectionViewLayout: OpalImagePickerCollectionViewLayout())
            setup(collectionView: externalCollectionView)
            view.addSubview(externalCollectionView)
            self.externalCollectionView = externalCollectionView
            
            constraints += [externalCollectionView.constraintEqualTo(with: collectionView, attribute: .top)]
            constraints += [externalCollectionView.constraintEqualTo(with: collectionView, attribute: .bottom)]
            constraints += [externalCollectionView.constraintEqualTo(with: collectionView, receiverAttribute: .left, otherAttribute: .right)]
            constraints += [collectionView.constraintEqualTo(with: view, attribute: .width)]
            constraints += [externalCollectionView.constraintEqualTo(with: view, attribute: .width)]
            constraints += [toolbar.constraintEqualTo(with: collectionView, receiverAttribute: .bottom, otherAttribute: .top)]
        } else {
            constraints += [view.constraintEqualTo(with: collectionView, attribute: .top)]
            constraints += [view.constraintEqualTo(with: collectionView, attribute: .right)]
        }
        
        //Lower priority to override left constraint for animations
        let leftCollectionViewConstraint = view.constraintEqualTo(with: collectionView, attribute: .left)
        leftCollectionViewConstraint.priority = UILayoutPriority(rawValue: 999)
        constraints += [leftCollectionViewConstraint]
        
        constraints += [view.constraintEqualTo(with: collectionView, attribute: .bottom)]
        NSLayoutConstraint.activate(constraints)
        view.layoutIfNeeded()
    }
    
    private func setup(collectionView: UICollectionView) {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImagePickerCollectionViewCell.self, forCellWithReuseIdentifier: ImagePickerCollectionViewCell.reuseId)
    }
    
    private func setupTabs() {
        guard let view = view else { return }
        
        edgesForExtendedLayout = UIRectEdge()
        navigationController?.navigationBar.isTranslucent = false
        toolbar.isTranslucent = false
        
        view.addSubview(toolbar)
        let flexItem1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let flexItem2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let barButtonItem = UIBarButtonItem(customView: tabSegmentedControl)
        toolbar.setItems([flexItem1, barButtonItem, flexItem2], animated: false)
        
        if let imagePicker = navigationController as? OpalImagePickerController,
            let title = delegate?.imagePickerTitleForExternalItems?(imagePicker) {
            tabSegmentedControl.setTitle(title, forSegmentAt: 1)
        }
        
        NSLayoutConstraint.activate([
            toolbar.constraintEqualTo(with: topLayoutGuide, receiverAttribute: .top, otherAttribute: .bottom),
            toolbar.constraintEqualTo(with: view, attribute: .left),
            toolbar.constraintEqualTo(with: view, attribute: .right)
        ])
    }
    
    private func fetchPhotos() {
        requestPhotoAccessIfNeeded(PHPhotoLibrary.authorizationStatus())
        
        if #available(iOS 9.0, *) {
            fetchOptions.fetchLimit = pageSize
        }
        if selectedCollection == nil {
            photoAssets = PHAsset.fetchAssets(with: fetchOptions)
        }
        else {
            photoAssets = PHAsset.fetchAssets(in: selectedCollection as! PHAssetCollection, options: fetchOptions)
            
        }
        collectionView?.reloadData()
    }
    
    private func updateFetchOptionPredicate() {
        var predicates: [NSPredicate] = []
        if let allowedMediaTypes = self.allowedMediaTypes {
            let mediaTypesPredicates = allowedMediaTypes.map { NSPredicate(format: "mediaType = %d", $0.rawValue) }
            let allowedMediaTypesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: mediaTypesPredicates)
            predicates += [allowedMediaTypesPredicate]
        }
        
        if let allowedMediaSubtypes = self.allowedMediaSubtypes {
            let mediaSubtypes = NSPredicate(format: "mediaSubtypes = %d", allowedMediaSubtypes.rawValue)
            predicates += [mediaSubtypes]
        }
        
        if predicates.count > 0 {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            fetchOptions.predicate = predicate
        } else {
            fetchOptions.predicate = nil
        }
        fetchPhotos()
    }
    
    /// Load View
    open override func loadView() {
        view = UIView()
    }
    open override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        albumModel = [AlbumModel]()
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    let userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
                    self.albumModel.append(AlbumModel(colection: nil, index: nil))
                    userCollections.enumerateObjects { (collection, id, pointer) in
                        self.albumModel.append(AlbumModel(colection: collection, index: id))
                    }
                    self.items = [menuItem]()
                    for i in self.albumModel {
                        if i.colection == nil {
                            let images = PHAsset.fetchAssets(with: self.fetchOptions)
                            self.items.append(menuItem(title: "Recents", image: self.loadPhotoAsset(asset: images.firstObject!), description: "\(images.count)", id: i.index))
                        }
                        else {
                            let images = PHAsset.fetchAssets(in: i.colection as! PHAssetCollection, options: self.fetchOptions)
                            
                            self.items.append(menuItem(title: i.colection!.localizedTitle, image: self.loadPhotoAsset(asset: images.firstObject), description: "\(images.count)", id: i.index))
                        }
                        
                    }
                    self.menu = Menu(viewController: self,items:self.items)
                    self.menu.delegate = self
                }
            case .notDetermined:
                DispatchQueue.main.async {
                    self.loadPermissionVC()
                }
            case .restricted:
                DispatchQueue.main.async {
                    self.loadPermissionVC()
                }
            case .denied:
                DispatchQueue.main.async {
                    self.loadPermissionVC()
                }
            @unknown default:
                break;
            }
        }
        
        titleView = UILabel()
        titleView.text = configuration?.navigationTitle ?? NSLocalizedString("Recents", comment: "")
        titleView.textAlignment = .center
        titleView.frame = CGRect(origin:CGPoint.zero, size:CGSize(width: 500, height: 500))
        self.navigationItem.titleView = titleView
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(titleTapped))
        titleView.isUserInteractionEnabled = true
        titleView.addGestureRecognizer(recognizer)
        
        //        navigationItem.title = configuration?.navigationTitle ?? NSLocalizedString("Photos", comment: "")
        
        let cancelButtonTitle = configuration?.cancelButtonTitle ?? NSLocalizedString("Cancel", comment: "")
        let cancelButton = UIBarButtonItem(title: cancelButtonTitle, style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.leftBarButtonItem = cancelButton
        self.cancelButton = cancelButton
        
        let doneButtonTitle = configuration?.doneButtonTitle ?? NSLocalizedString("Done", comment: "")
        let doneButton = UIBarButtonItem(title: doneButtonTitle, style: .done, target: self, action: #selector(doneTapped))
        navigationItem.rightBarButtonItem = doneButton
        self.doneButton = doneButton
    }
    private func loadPermissionVC(){
        guard let permissionVC = Bundle.main.loadNibNamed("PermissionVC", owner: self, options: nil)?[0] as? PermissionVC else { return }
        self.present(permissionVC, animated: true, completion: nil)
    }
    private func loadPhotoAsset(asset:PHAsset?)->UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        
        
        let manager = PHImageManager.default()
        var _image: UIImage?
        if asset != nil {
            manager.requestImage(for: asset!, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
                _image = image
            })
        }
        return _image
    }
    func didSelectItem(index: Int, title: String) {
        titleView.text = title
        selectedCollection = albumModel[index].colection as? PHAssetCollection
        fetchPhotos()
        menu.show()
    }
    @objc func titleTapped(){
        menu.show()
    }
    @objc func cancelTapped() {
        dismiss(animated: true) { [weak self] in
            guard let imagePicker = self?.navigationController as? OpalImagePickerController else { return }
            self?.delegate?.imagePickerDidCancel?(imagePicker)
        }
    }
    
    @objc func doneTapped() {
        guard let imagePicker = navigationController as? OpalImagePickerController else { return }
        
        let indexPathsForSelectedItems = selectedIndexPaths
        let externalIndexPaths = externalSelectedIndexPaths
        //        guard indexPathsForSelectedItems.count + externalIndexPaths.count > 0 else {
        //            cancelTapped()
        //            return
        //        }
        //
        var photoAssets: [PHAsset] = []
        for indexPath in indexPathsForSelectedItems {
            guard indexPath.item < self.photoAssets.count else { continue }
            photoAssets += [self.photoAssets.object(at: indexPath.item)]
        }
        delegate?.imagePicker?(imagePicker, didFinishPickingAssets: photoAssets)
        
        var selectedURLs: [URL] = []
        for indexPath in externalIndexPaths {
            guard let url = delegate?.imagePicker?(imagePicker, imageURLforExternalItemAtIndex: indexPath.item) else { continue }
            selectedURLs += [url]
        }
        delegate?.imagePicker?(imagePicker, didFinishPickingExternalURLs: selectedURLs)
        
        guard shouldExpandImagesFromAssets() else { return }
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        
        for asset in photoAssets {
            manager.requestImageData(for: asset, options: options, resultHandler: { [weak self] (data, _, _, _) in
                guard let strongSelf = self,
                    let data = data,
                    let image = UIImage(data: data) else { return }
                strongSelf.savedImages += [image]
            })
        }
        delegate?.imagePicker?(imagePicker, didFinishPickingImages: savedImages)
        savedImages = []
        dismiss(animated: true, completion: nil)
    }
    
    private func shouldExpandImagesFromAssets() -> Bool {
        //Only expand images if didFinishPickingAssets is implemented in delegate.
        if let delegate = self.delegate as? NSObject,
            delegate.responds(to: #selector(OpalImagePickerControllerDelegate.imagePicker(_:didFinishPickingImages:))) {
            return true
        } else if !(delegate is NSObject) {
            return true
        }
        return false
    }
    
    func set(image: UIImage?, indexPath: IndexPath, isExternal: Bool) {
        update(isSelected: image != nil, isExternal: isExternal, for: indexPath)
        
        // Only store images if delegate method is implemented
        if let nsDelegate = delegate as? NSObject,
            !nsDelegate.responds(to: #selector(OpalImagePickerControllerDelegate.imagePicker(_:didFinishPickingImages:))) {
            return
        }
        
        let key = IndexPath(item: indexPath.item, section: isExternal ? 1 : 0)
        imagesDict[key] = image
    }
    
    private func update(isSelected: Bool, isExternal: Bool, for indexPath: IndexPath) {
        if isSelected && isExternal {
            externalSelectedIndexPaths += [indexPath]
        } else if !isSelected && isExternal {
            externalSelectedIndexPaths = externalSelectedIndexPaths.filter { $0 != indexPath }
        } else if isSelected && !isExternal {
            selectedIndexPaths += [indexPath]
        } else {
            selectedIndexPaths = selectedIndexPaths.filter { $0 != indexPath }
        }
        print("")
    }
    
    private func get(imageForIndexPath indexPath: IndexPath, isExternal: Bool) -> UIImage? {
        let key = IndexPath(item: indexPath.item, section: isExternal ? 1 : 0)
        return imagesDict[key]
    }
    
    @available(iOS 9.0, *)
    private func fetchNextPageIfNeeded(indexPath: IndexPath) {
        guard indexPath.item == fetchLimit-1 else { return }
        
        let oldFetchLimit = fetchLimit
        fetchLimit += pageSize
        photoAssets = PHAsset.fetchAssets(with: fetchOptions)
        var indexPaths: [IndexPath] = []
        for item in oldFetchLimit..<photoAssets.count {
            indexPaths += [IndexPath(item: item, section: 0)]
        }
        collectionView?.insertItems(at: indexPaths)
    }
    
    func requestPhotoAccessIfNeeded(_ status: PHAuthorizationStatus)->Bool {
        var isAvailable = false
        guard status == .notDetermined else { return false}
        let v = PHPhotoLibrary.authorizationStatus()
        if v == PHAuthorizationStatus.authorized {
            isAvailable = true
        }
        else {
            isAvailable = false
        }
        PHPhotoLibrary.requestAuthorization { [weak self] (_) in
            DispatchQueue.main.async { [weak self] in
                self?.photoAssets = PHAsset.fetchAssets(with: self?.fetchOptions)
                self?.collectionView?.reloadData()
            }
        }
        return isAvailable
    }
    
    @objc private func segmentTapped(_ sender: UISegmentedControl) {
        guard let view = view else { return }
        
        showExternalImages = sender.selectedSegmentIndex == 1
        
        //Instantiate right constraint if needed
        if rightExternalCollectionViewConstraint == nil {
            let rightConstraint = externalCollectionView?.constraintEqualTo(with: view, attribute: .right)
            rightExternalCollectionViewConstraint = rightConstraint
        }
        rightExternalCollectionViewConstraint?.isActive = showExternalImages
        
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            sender.isUserInteractionEnabled = false
            self?.view.layoutIfNeeded()
            }, completion: { _ in
                sender.isUserInteractionEnabled = true
        })
    }
    
    private func configurationChanged(_ configuration: OpalImagePickerConfiguration) {
        if let navigationTitle = configuration.navigationTitle {
            navigationItem.title = navigationTitle
        }
        
        if let librarySegmentTitle = configuration.librarySegmentTitle {
            tabSegmentedControl.setTitle(librarySegmentTitle, forSegmentAt: 0)
        }
    }
}

// MARK: - Collection View Delegate

extension OpalImagePickerRootViewController: UICollectionViewDelegate {
    
    /// Collection View did select item at `IndexPath`
    ///
    /// - Parameters:
    ///   - collectionView: the `UICollectionView`
    ///   - indexPath: the `IndexPath`
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImagePickerCollectionViewCell,
            let image = cell.imageView.image else { return }
        set(image: image, indexPath: indexPath, isExternal: collectionView == self.externalCollectionView)
        doneTapped()
        
    }
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImagePickerCollectionViewCell,
            let image = cell.imageView.image else { return false}
        guard maximumSelectionsAllowed > 0 else { return true }
        if maximumSelectionsAllowed <= selectedIndexPaths.count {
            //We exceeded maximum allowed, so alert user. Don't allow selection
            
            if shouldResetItems {
                collectionView.deselectItem(at: selectedIndexPaths.first!, animated: true)
                collectionView.deselectItem(at: selectedIndexPaths.last!, animated: true)
                set(image: nil, indexPath: selectedIndexPaths.first!, isExternal: collectionView == self.externalCollectionView)
                if selectedIndexPaths.count != 0 {
                    set(image: nil, indexPath: selectedIndexPaths.last!, isExternal: collectionView == self.externalCollectionView)
                }
                doneTapped()
                return false
            }
            else {
                let message = configuration?.maximumSelectionsAllowedMessage ?? NSLocalizedString("You cannot select more than \(maximumSelectionsAllowed) images. Please deselect another image before trying to select again.", comment: "You cannot select more than (x) images. Please deselect another image before trying to select again. (OpalImagePicker)")
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                let okayString = configuration?.okayString ?? NSLocalizedString("OK", comment: "OK")
                let action = UIAlertAction(title: okayString, style: .cancel, handler: nil)
                alert.addAction(action)
                present(alert, animated: true, completion: nil)
                doneTapped()
                return false
            }
        }
        else {
            let cell = collectionView.cellForItem(at: indexPath) as? ImagePickerCollectionViewCell
            cell?.setDoubleSelected(true, animated: true)
            set(image: image, indexPath: indexPath, isExternal: collectionView == self.externalCollectionView)
            doneTapped()
        }
        return false
    }
    
    /// Collection View did de-select item at `IndexPath`
    ///
    /// - Parameters:
    ///   - collectionView: the `UICollectionView`
    ///   - indexPath: the `IndexPath`
    //    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    //        set(image: nil, indexPath: indexPath, isExternal: collectionView == self.externalCollectionView)
    //        doneTapped()
    ////        guard let cell = collectionView.cellForItem(at: indexPath) as? ImagePickerCollectionViewCell,
    ////            let image = cell.imageView.image else { return }
    ////        set(image: image, indexPath: indexPath, isExternal: collectionView == self.externalCollectionView)
    ////        doneTapped()
    //    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImagePickerCollectionViewCell,
            cell.imageView.image != nil else { return false }
        guard maximumSelectionsAllowed > 0 else { return true }
        
        let collectionViewItems = self.collectionView?.indexPathsForSelectedItems?.count ?? 0
        let externalCollectionViewItems = self.externalCollectionView?.indexPathsForSelectedItems?.count ?? 0
        
        if maximumSelectionsAllowed <= selectedIndexPaths.count {
            //We exceeded maximum allowed, so alert user. Don't allow selection
            
            if shouldResetItems {
                collectionView.deselectItem(at: selectedIndexPaths.first!, animated: true)
                collectionView.deselectItem(at: selectedIndexPaths.last!, animated: true)
                set(image: nil, indexPath: selectedIndexPaths.first!, isExternal: collectionView == self.externalCollectionView)
                if selectedIndexPaths.count != 0 {
                    set(image: nil, indexPath: selectedIndexPaths.last!, isExternal: collectionView == self.externalCollectionView)
                }
                return true
            }
            else {
                let message = configuration?.maximumSelectionsAllowedMessage ?? NSLocalizedString("You cannot select more than \(maximumSelectionsAllowed) images. Please deselect another image before trying to select again.", comment: "You cannot select more than (x) images. Please deselect another image before trying to select again. (OpalImagePicker)")
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                let okayString = configuration?.okayString ?? NSLocalizedString("OK", comment: "OK")
                let action = UIAlertAction(title: okayString, style: .cancel, handler: nil)
                alert.addAction(action)
                present(alert, animated: true, completion: nil)
                return false
            }
            
        }
        return true
    }
}

// MARK: - Collection View Data Source

extension OpalImagePickerRootViewController: UICollectionViewDataSource {
    
    /// Returns Collection View Cell for item at `IndexPath`
    ///
    /// - Parameters:
    ///   - collectionView: the `UICollectionView`
    ///   - indexPath: the `IndexPath`
    /// - Returns: Returns the `UICollectionViewCell`
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.collectionView {
            return photoAssetCollectionView(collectionView, cellForItemAt: indexPath)
        } else {
            return externalCollectionView(collectionView, cellForItemAt: indexPath)
        }
    }
    
    private func photoAssetCollectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if #available(iOS 9.0, *) {
            fetchNextPageIfNeeded(indexPath: indexPath)
        }
        
        guard let layoutAttributes = collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath),
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImagePickerCollectionViewCell.reuseId, for: indexPath) as? ImagePickerCollectionViewCell else { return UICollectionViewCell() }
        let photoAsset = photoAssets.object(at: indexPath.item)
        cell.indexPath = indexPath
        cell.photoAsset = photoAsset
        cell.size = layoutAttributes.frame.size
        
        if let selectionTintColor = self.selectionTintColor {
            cell.selectionTintColor = selectionTintColor
        }
        if let selectionImageTintColor = self.selectionImageTintColor {
            cell.selectionImageTintColor = selectionImageTintColor
        }
        if let selectionImage = self.selectionImage {
            cell.selectionImage = selectionImage
        }
        if let doubleSelectionImage = self.doubleSelectionImage {
            cell.doubleSelectionImage = doubleSelectionImage
        }
        var count = 0
        for i in selectedIndexPaths {
            if i == indexPath {
                count += 1
            }
        }
        if count == 2 {
            cell.setDoubleSelected(true, animated: true)
        }
        return cell
    }
    private func externalCollectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let imagePicker = navigationController as? OpalImagePickerController,
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImagePickerCollectionViewCell.reuseId, for: indexPath) as? ImagePickerCollectionViewCell else { return UICollectionViewCell() }
        if let url = delegate?.imagePicker?(imagePicker, imageURLforExternalItemAtIndex: indexPath.item) {
            cell.cache = cache
            cell.url = url
            cell.indexPath = indexPath
        } else {
            assertionFailure("You need to implement `imagePicker(_:imageURLForExternalItemAtIndex:)` in your delegate.")
        }
        
        if let selectionTintColor = self.selectionTintColor {
            cell.selectionTintColor = selectionTintColor
        }
        if let selectionImageTintColor = self.selectionImageTintColor {
            cell.selectionImageTintColor = selectionImageTintColor
        }
        if let selectionImage = self.selectionImage {
            cell.selectionImage = selectionImage
        }
        
        return cell
    }
    
    /// Returns the number of items in a given section
    ///
    /// - Parameters:
    ///   - collectionView: the `UICollectionView`
    ///   - section: the given section of the `UICollectionView`
    /// - Returns: Returns an `Int` for the number of rows.
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collectionView {
            return photoAssets.count
        } else if let imagePicker = navigationController as? OpalImagePickerController,
            let numberOfItems = delegate?.imagePickerNumberOfExternalItems?(imagePicker) {
            return numberOfItems
        } else {
            assertionFailure("You need to implement `imagePickerNumberOfExternalItems(_:)` in your delegate.")
            return 0
        }
    }
}
