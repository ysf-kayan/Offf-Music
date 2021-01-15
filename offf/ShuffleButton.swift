//
//  ShuffleButton.swift
//  offf
//
//  Created by Yusuf Kayan on 21.10.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit

class ShuffleButton: UIButton {
    
    var status = ShuffleStatus.NO_SHUFFLE;

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
        print("ShuffleButton init");
    }
    
    @objc func onTouchUpInside() {
        if (status == ShuffleStatus.SHUFFLE) {
            setStatus(status: .NO_SHUFFLE);
        } else {
            setStatus(status: .SHUFFLE);
        }
    }
    
    func setStatus(status: ShuffleStatus) {
        self.status = status;
        if (status == .NO_SHUFFLE) {
            self.tintColor = UIColor.systemGray;
        } else {
            self.tintColor = UIColor.white;
        }
    }

}

enum ShuffleStatus: Int, Codable {
    case NO_SHUFFLE
    case SHUFFLE
}
