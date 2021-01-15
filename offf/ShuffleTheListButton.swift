//
//  ShuffleTheListButton.swift
//  offf
//
//  Created by Yusuf Kayan on 20.12.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit

class ShuffleTheListButton: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var button: UIButton!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        initSubviews();
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        initSubviews();
    }
    
    func initSubviews() {
        let nib = UINib(nibName: "ShuffleTheListButton", bundle: nil);
        nib.instantiate(withOwner: self, options: nil);
        contentView.frame = bounds;
        
        button.addTarget(self, action: #selector(onTouchDownButton), for: .touchDown);
        //button.addTarget(self, action: #selector(onTouchUpButton), for: .touchUpInside);
        button.addTarget(self, action: #selector(onTouchUpButton), for: .touchUpOutside);
                
        addSubview(contentView);
    }
    
    @objc func onTouchDownButton() {
        button.backgroundColor = UIColor.init(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.3);
    }
    
    @objc func onTouchUpButton() {
        button.backgroundColor = UIColor.init(red: 150/255, green: 150/255, blue: 150/255, alpha: 0);
    }
}
