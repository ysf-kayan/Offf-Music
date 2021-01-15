//
//  EqualizerAnimation.swift
//  offf
//
//  Created by Yusuf Kayan on 13.12.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit

class Equalizer: UIView {
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var view1: UIView!
    
    @IBOutlet weak var view1TopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var view2TopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var view3TopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var view4TopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var view5TopConstraint: NSLayoutConstraint!
    
    var animationTimer: Timer?;
    
    var barHeights = [0, 0, 0, 0, 0];
    var firstDraw = true;
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        initSubviews();
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        initSubviews();
        
        print("Equalizer: init()");
        print(frame);
    }
    
    func initSubviews() {
        let nib = UINib(nibName: "Equalizer", bundle: nil);
        nib.instantiate(withOwner: self, options: nil);
        
        contentView.frame = bounds;
        addSubview(contentView);
    }
    
    @objc func animate() {
        if (self.window == nil) {
            if (animationTimer != nil) {
                animationTimer?.invalidate();
            }
        }
        
        if (self.superview?.convert(self.frame.origin, to: nil) == nil) {
            if (animationTimer != nil) {
                animationTimer?.invalidate();
            }
        }
        
        barHeights = barHeights.map { _ in
            return Int.random(in: 2...Int(view1.frame.size.height));
        };
        
        self.view1TopConstraint.constant = CGFloat(barHeights[0]);
        self.view2TopConstraint.constant = CGFloat(barHeights[1]);
        self.view3TopConstraint.constant = CGFloat(barHeights[2]);
        self.view4TopConstraint.constant = CGFloat(barHeights[3]);
        self.view5TopConstraint.constant = CGFloat(barHeights[4]);
        UIView.animate(withDuration: 0.7, animations: { () -> Void in
            self.layoutIfNeeded();
        }, completion: { _ in });
                
        //print(self.window);
        //print(self.superview?.convert(self.frame.origin, to: nil));
    }
    
    public static func embedIntoView(view: UIView, equalizer: Equalizer) {
        view.addSubview(equalizer);
                
        equalizer.translatesAutoresizingMaskIntoConstraints = false;
        let leading = NSLayoutConstraint(item: equalizer, attribute: .leading, relatedBy: .equal, toItem:view, attribute: .leading, multiplier: 1, constant: 0);
        let trailing = NSLayoutConstraint(item: equalizer, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0);
        let top = NSLayoutConstraint(item: equalizer, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0);
        let bottom = NSLayoutConstraint(item: equalizer, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0);
        
        view.addConstraints([leading, trailing, top, bottom]);
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect);
        
        stackView.spacing = (rect.width / 5) / 5;
        
        if (firstDraw) {
            print("Equalizer: first draw()");
            print(rect);
            barHeights = barHeights.map { _ in
                return Int.random(in: 2...Int(view1.frame.size.height));
            };
            
            self.view1TopConstraint.constant = CGFloat(barHeights[0]);
            self.view2TopConstraint.constant = CGFloat(barHeights[1]);
            self.view3TopConstraint.constant = CGFloat(barHeights[2]);
            self.view4TopConstraint.constant = CGFloat(barHeights[3]);
            self.view5TopConstraint.constant = CGFloat(barHeights[4]);
            
            firstDraw = false;
        }
        
        animationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(animate), userInfo: nil, repeats: true);
        
        RunLoop.main.add(animationTimer!, forMode: .common);
    }
    
    deinit {
        print("Equalizer yok ediliyor...");
    }
}
