//
//  BaseTabBarController.swift
//  offf
//
//  Created by Yusuf Kayan on 17.06.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import Foundation
import UIKit

class BaseTabBarController: UITabBarController {
    @IBInspectable var defaultIndex: Int = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        selectedIndex = defaultIndex;
        self.view.backgroundColor = UIColor.systemBackground;
    }
}
