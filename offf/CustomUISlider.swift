//
//  SongSeekbar.swift
//  offf
//
//  Created by Yusuf Kayan on 27.06.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit

class SongSeekbar: UISlider {
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.origin.x, y: bounds.origin.y + 8, width: bounds.size.width, height: 15);
    }
    
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        
        let minTrackImage = UIImage.init(named: "seekbar_min")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10));
        setMinimumTrackImage(minTrackImage, for: .normal);
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
