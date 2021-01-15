//
//  MyUIButton.swift
//  offf
//
//  Created by Yusuf Kayan on 20.06.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit

class MyUIButton: UIButton {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.imageView?.contentMode = UIView.ContentMode(rawValue: 1)!;
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
