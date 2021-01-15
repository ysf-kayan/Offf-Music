//
//  PlayerScreenTitle.swift
//  offf
//
//  Created by Yusuf Kayan on 20.06.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit

@IBDesignable class PlayerScreenTitleView: UIView {
    
    var artistLabel: UILabel?;
    var titleLabel: UILabel?;
    var albumLabel: UILabel?;
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        print("PlayerScreenTitleView: init(frame) \(self.frame)");
        commonInit();
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        print("PlayerScreenTitleView: init(coder) \(self.frame)");
        commonInit();
    }
    
    private func commonInit() {
        //let stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height));
        let stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: 20, height: 20));
        stackView.distribution = UIStackView.Distribution.fillProportionally
        stackView.axis = NSLayoutConstraint.Axis.vertical;
        
        stackView.backgroundColor = UIColor.red;
        
        
        artistLabel = UILabel();
        artistLabel!.text = "Duman";
        artistLabel!.textAlignment = NSTextAlignment.center;
        artistLabel!.font = UIFont(name: "Helvetica", size: 10);
        artistLabel!.textColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1);
        artistLabel?.minimumScaleFactor = 0.1;
        artistLabel?.adjustsFontSizeToFitWidth = true;
        artistLabel?.lineBreakMode = .byClipping;
        artistLabel?.numberOfLines = 0;
        
        
        titleLabel = UILabel()
        titleLabel!.text = "Haberin Yok Ölüyorum";
        titleLabel!.textAlignment = NSTextAlignment.center;
        titleLabel!.font = UIFont(name: "Helvetica", size: 15);
        titleLabel?.minimumScaleFactor = 0.1;
        titleLabel?.adjustsFontSizeToFitWidth = true;
        titleLabel?.lineBreakMode = .byClipping;
        titleLabel?.numberOfLines = 0;
        
        albumLabel = UILabel()
        albumLabel!.text = "Her Şeyi Yak";
        albumLabel!.textAlignment = NSTextAlignment.center;
        albumLabel!.font = UIFont(name: "Helvetica", size: 10);
        albumLabel!.textColor = UIColor(displayP3Red: 200/255, green: 200/255, blue: 200/255, alpha: 1);
        albumLabel?.minimumScaleFactor = 0.1;
        albumLabel?.adjustsFontSizeToFitWidth = true;
        albumLabel?.lineBreakMode = .byClipping;
        albumLabel?.numberOfLines = 0;
        
        stackView.addArrangedSubview(artistLabel!);
        stackView.addArrangedSubview(titleLabel!);
        stackView.addArrangedSubview(albumLabel!);
        
        addSubview(stackView);
    }
    
    override func draw(_ rect: CGRect) {
        /*print("PlayerScreenTitleView: draw(rect) \(rect)");
        //print("super: \(self.superview?.superview?.subviews)");
        self.superview?.superview?.subviews.forEach { (view) in
            print(view);
        }
        
        self.superview?.superview?.subviews[0].backgroundColor = UIColor.red;
        self.superview?.superview?.subviews[1].backgroundColor = UIColor.green;
        self.superview?.superview?.subviews[1].backgroundColor = UIColor.blue;*/
    }
    
    /*override func sizeThatFits(_ size: CGSize) -> CGSize {
        print("fits: \(size)");
        return super.sizeThatFits(size);
    }*/
    
}
