//
//  LoopButton.swift
//  offf
//
//  Created by Yusuf Kayan on 1.11.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit

class LoopButton: UIButton {

    var status = LoopStatus.NO_LOOP;
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        commonInit();
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        commonInit();
    }
    
    private func commonInit() {
        self.addTarget(self, action: #selector(onTouchUpInside), for: .touchUpInside);
        print("LoopButton init");
    }
    
    @objc func onTouchUpInside() {        
        if (status == .NO_LOOP) {
            setStatus(status: .LOOP_LIST);
        } else if (status == .LOOP_LIST) {
            setStatus(status: .LOOP_ONE);
        } else if (status == .LOOP_ONE) {
            setStatus(status: .STOP_AFTER_ONE);
        } else if (status == .STOP_AFTER_ONE) {
            setStatus(status: .NO_LOOP);
        }
    }
    
    public func setStatus(status: LoopStatus) {
        self.status = status;
        
        if (status == .NO_LOOP) {
            self.tintColor = UIColor.systemGray;
        } else {
            self.tintColor = UIColor.white;
        }
        
        if (status == .NO_LOOP || status == .LOOP_LIST) {
            let repeatImage = UIImage.init(systemName: "repeat");
            self.setImage(repeatImage, for: .normal);
        } else if (status == .LOOP_ONE) {
            let repeat1Image = UIImage.init(systemName: "repeat.1");
            self.setImage(repeat1Image, for: .normal);
        } else if (status == .STOP_AFTER_ONE) {
            let stopAfterOneImage = UIImage.init(systemName: "forward.end.fill");
            self.setImage(stopAfterOneImage, for: .normal);
        }
    }

}
