//
//  UIViewExtensions.swift
//  OpalImagePicker
//
//  Created by Sina on 11/25/19.
//  Copyright © 2019 Opal Orange LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
