//
//  PHAssetExtensions.swift
//  OpalImagePicker
//
//  Created by Sina on 11/27/19.
//  Copyright © 2019 Opal Orange LLC. All rights reserved.
//

import Foundation
import Photos
import UIKit
extension PHAsset {
    var image : UIImage {
        var thumbnail = UIImage()
        let imageManager = PHCachingImageManager()
        imageManager.requestImage(for: self, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: nil, resultHandler: { image, _ in
            thumbnail = image!
        })
        return thumbnail
    }
}
