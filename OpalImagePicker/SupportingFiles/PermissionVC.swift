//
//  PermissionVCViewController.swift
//  OpalImagePicker
//
//  Created by Sina on 11/27/19.
//  Copyright © 2019 Opal Orange LLC. All rights reserved.
//

import UIKit

class PermissionVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    @IBAction func settingsBtnAct(_ sender: Any) {
        let settingsAppURL = URL(string:"App-Prefs:root=OpalImagePicker")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(settingsAppURL!, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(settingsAppURL!)
        }

    }
    
}
