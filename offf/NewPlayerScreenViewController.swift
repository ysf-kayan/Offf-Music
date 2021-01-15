//
//  NewPlayerScreenViewController.swift
//  offf
//
//  Created by Yusuf Kayan on 26.12.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit
import MediaPlayer

enum PlayerCommand {
    case PLAY_NEW_LIST
    case SHOW_PLAYER
}

class MyPopAnimation: CABasicAnimation {
}

class MyImageView: UIImageView, CAAnimationDelegate {
    
    public func addRotateAnimation() {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation");
        rotateAnimation.fromValue = 0;
        rotateAnimation.toValue = Double.pi * 2;
        rotateAnimation.duration = 5;
        rotateAnimation.fillMode = .forwards;
        rotateAnimation.repeatCount = Float.infinity;
        rotateAnimation.delegate = self;
        
        self.layer.add(rotateAnimation, forKey: nil);
    }
    
    public func addSwingAnimation() {
        let swingAnimation = CAKeyframeAnimation(keyPath: "transform.rotation");
        swingAnimation.values = [0, Double.pi * 0.03, 0, -Double.pi * 0.03, 0];
        swingAnimation.duration = 5;
        swingAnimation.fillMode = .forwards;
        swingAnimation.isRemovedOnCompletion = true;
        swingAnimation.repeatCount = Float.infinity;
        swingAnimation.calculationMode = .cubic;
        swingAnimation.delegate = self;
        
        self.layer.add(swingAnimation, forKey: nil);
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        print("animation stopped");
    }
    
    /*public func addPopAnimation(noteView: MyImageView) {
        let popAnimation = MyPopAnimation(keyPath: "transform.scale");
        popAnimation.fromValue = 0;
        popAnimation.toValue = 1;
        popAnimation.duration = Double.random(in: 0.5...10);
        popAnimation.fillMode = .forwards;
        popAnimation.isRemovedOnCompletion = true;
        popAnimation.delegate = noteView;
        
        self.tintColor = UIColor.init(red: CGFloat.random(in: 0.0...1.0), green: CGFloat.random(in: 0.0...1.0), blue: CGFloat.random(in: 0.0...1.0), alpha: 1.0);
        
        noteView.layer.add(popAnimation, forKey: "pop");
    }
    
    public func addMoveAnimation(noteView: MyImageView) {
        let moveAnimation = CAKeyframeAnimation(keyPath: "position.y");
        moveAnimation.values = [self.frame.origin.y + self.frame.height / 2, 900];
        moveAnimation.duration = Double.random(in: 3.0...15.0);
        moveAnimation.fillMode = .forwards;
        moveAnimation.isRemovedOnCompletion = false;
        moveAnimation.delegate = noteView;
        
        noteView.layer.add(moveAnimation, forKey: "move");
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if (flag) {
            if (anim is MyPopAnimation) {
                self.layer.removeAnimation(forKey: "pop");
                addMoveAnimation(noteView: self);
            } else {
                self.layer.removeAnimation(forKey: "move");
                addPopAnimation(noteView: self);
            }
        }
    }*/
}

class NewPlayerScreenViewController: UIViewController {

    
    @IBOutlet weak var hiddenVolumeSliderContainer: UIView!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var songIndexLabel: UILabel!
    @IBOutlet weak var songSeekbar: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var playPauseButton: MyUIButton!
    @IBOutlet weak var loopButton: LoopButton!
    @IBOutlet weak var shuffleButton: ShuffleButton!
    @IBOutlet weak var animationView: UIView!
    
    @IBOutlet weak var vinylImage: MyImageView!
    @IBOutlet weak var vinylLightImage: MyImageView!
    
    @IBOutlet weak var artistLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleViewHeightConstraint: NSLayoutConstraint!
    
    var command = PlayerCommand.SHOW_PLAYER;
    var songList: [MPMediaItem] = [];
    var volumeView: MPVolumeView? = nil;
    var timeObserverToken: Any?;
    var seeking: Bool = false;
    var wasPlayingBeforeSeek = false;
    var volumeBeingChangedManually = false;
    var volumeBeingChangedManuallyAsyncTask: DispatchWorkItem? = nil;

    var noteViews: [UIImageView] = [];
    var popAnims: [MyPopAnimation] = [];
    
    override func viewDidLoad() {
        super.viewDidLoad();
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default);
        navigationController?.navigationBar.shadowImage = UIImage();
        navigationController?.navigationBar.isTranslucent = true;
        
        let gradient = CAGradientLayer();
        gradient.frame = view.bounds;
        gradient.colors = [UIColor.darkGray.cgColor, UIColor.black.cgColor];
                
        gradient.startPoint = CGPoint.init(x: 0, y: 0)
        gradient.endPoint = CGPoint.init(x: 1, y: 1);
        view.layer.insertSublayer(gradient, at: 0);
        
        volumeView = MPVolumeView(frame: hiddenVolumeSliderContainer.bounds);
        hiddenVolumeSliderContainer.addSubview(volumeView!);
        
        shuffleButton.setStatus(status: MusicPlayer.getShuffleStatus());
        loopButton.setStatus(status: MusicPlayer.getLoopStatus());
        
        print("viewDidLoad()");
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updatePlayerScreen), name: Notification.Name(AppGlobals.UPDATE_PLAYER_SCREEN), object: nil);
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil);
        
        
        let timeScale = CMTimeScale(NSEC_PER_SEC);
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale);
        
        timeObserverToken = MusicPlayer.getPlayer().addPeriodicTimeObserver(forInterval: time, queue: .main) { time in
            if (!self.seeking) {
                self.updatePlaybackTimeLabels(seconds: Int(time.seconds));
                self.updateSeekbarPos(seconds: Int(time.seconds));
            }
        };
        
        updatePlayerScreen();
        
        prepareTitleView();
        
        print("viewWillAppear");
    }
    
    var animationsInitialized = false;
    
    override func viewDidLayoutSubviews() {
        print("viewDidLayoutSubviews()");
        if (!animationsInitialized) {
            vinylImage.addRotateAnimation();
            vinylLightImage.addSwingAnimation();
            animationsInitialized = true;
        }
        
        /*if (!animationsInitialized) {
            for _ in 1...30 {
                let noteView = MyImageView(image: UIImage(systemName: "music.note"));
                noteView.tintColor = UIColor.systemGray;
                noteView.frame = CGRect(x: Int.random(in: 30...Int(animationView.frame.width) - 30), y: 30, width: 30, height: 30);
                noteViews.append(noteView);
            }
            
            noteViews.forEach { (noteView) in
                animationView.addSubview(noteView);
                (noteView as! MyImageView).addPopAnimation(noteView: noteView as! MyImageView);
                /*DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.1...5)) {
                    (noteView as! MyImageView).addMoveAnimation(noteView: noteView as! MyImageView);
                }*/
                addSwingAnimation(noteView: noteView as! MyImageView);
            }
            animationsInitialized = true;
        }*/
    }
    
    private func addSwingAnimation(noteView: MyImageView) {
        let swingAnimation = CAKeyframeAnimation(keyPath: "transform.rotation");
        swingAnimation.values = [0, Double.pi * 0.05, 0, -Double.pi * 0.05, 0];
        swingAnimation.duration = 1 / 2;
        swingAnimation.fillMode = .forwards;
        swingAnimation.isRemovedOnCompletion = true;
        swingAnimation.repeatCount = Float.infinity;
        swingAnimation.calculationMode = .cubic;
        swingAnimation.delegate = noteView;
        
        noteView.layer.add(swingAnimation, forKey: nil);
    }
        
    private func prepareTitleView() {
        let titleViewHeight = titleViewHeightConstraint.constant;
        let unitHeight = titleViewHeight / (1 + 1 + 1.2);
        artistLabelHeightConstraint.constant = unitHeight;
        albumLabelHeightConstraint.constant = unitHeight;
        
        let artistLabelHeight = unitHeight;
        let titleLabelHeight = titleViewHeight - (unitHeight * 2);
        
        let initialFontSize = 5.0;
        let fontSizeIncreaseStep = 0.5;
                
        var artistFontSize = initialFontSize;
        var artistFont = UIFont(descriptor: artistLabel.font.fontDescriptor, size: CGFloat(artistFontSize));
        while artistFont.lineHeight <= artistLabelHeight {
            artistFontSize += fontSizeIncreaseStep;
            artistFont = UIFont(descriptor: artistLabel.font.fontDescriptor, size: CGFloat(artistFontSize));
        }
        artistFont = UIFont(descriptor: artistLabel.font.fontDescriptor, size: CGFloat(artistFontSize - fontSizeIncreaseStep));
        artistLabel.font = artistFont;
        
        var titleFontSize = initialFontSize;
        var titleFont = UIFont(descriptor: titleLabel.font.fontDescriptor, size: CGFloat(titleFontSize));
        while titleFont.lineHeight <= titleLabelHeight {
            titleFontSize += fontSizeIncreaseStep;
            titleFont = UIFont(descriptor: titleLabel.font.fontDescriptor, size: CGFloat(titleFontSize));
        }
        titleFont = UIFont(descriptor: titleLabel.font.fontDescriptor, size: CGFloat(titleFontSize - fontSizeIncreaseStep));
        titleLabel.font = titleFont;
        
        albumLabel.font = artistFont;
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default);
        navigationController?.navigationBar.shadowImage = nil;
        
        MusicPlayer.getPlayer().removeTimeObserver(timeObserverToken!);
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume");
    }
    
    @IBAction func volumeSliderValueChanged(_ sender: UISlider) {
        setVolume(volume: sender.value);
    }
    
    @IBAction func volumeSliderTouchDown(_ sender: UISlider) {
        if (volumeBeingChangedManually) {
            if (volumeBeingChangedManuallyAsyncTask != nil) {
                volumeBeingChangedManuallyAsyncTask!.cancel();
            }
        }
        
        volumeBeingChangedManually = true;
    }
    
    @IBAction func volumeSliderTouchUp(_ sender: UISlider) {
        volumeBeingChangedManuallyAsyncTask = DispatchWorkItem {
            self.volumeBeingChangedManually = false;
        };

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: volumeBeingChangedManuallyAsyncTask!);
    }
    
    @IBAction func nextButtonClicked(_ sender: UITapGestureRecognizer) {
        MusicPlayer.nextTrack(skippedByUser: true);
    }
    
    @IBAction func nextButtonLongPress(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == .began) {
            MusicPlayer.fastForward(seconds: 30);
        }
    }
    
    @IBAction func previousButtonClicked(_ sender: UITapGestureRecognizer) {
        MusicPlayer.previousTrack();
    }
    @IBAction func playPauseClicked(_ sender: MyUIButton) {
        if (MusicPlayer.getPlaybackState() == .PLAYING) {
            MusicPlayer.pause();
        } else {
            MusicPlayer.resume();
        }
        setPlayPauseButtonState();
    }
    
    @IBAction func loopButtonClicked(_ sender: LoopButton) {
        MusicPlayer.setLoopStatus(loopStatus: sender.status);
    }
    
    @IBAction func shuffleButtonClicked(_ sender: ShuffleButton) {
        MusicPlayer.setShuffle(shuffle: sender.status);
    }
    
    
    func setPlayPauseButtonState() {
        if (MusicPlayer.getPlaybackState() == .PLAYING) {
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: UIControl.State.normal);
        } else {
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: UIControl.State.normal);
        }
    }
    
    @IBAction func previousButtonLongPress(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == .began) {
            MusicPlayer.fastBackward(seconds: 30);
        }
    }
    
    
    
    private func setVolume(volume: Float) {
        let slider = volumeView!.subviews.last as? UISlider;
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            slider!.value = volume;
        }
    }
    
    func showSongInfo() {
        let nowPlayingItem = MusicPlayer.getCurrentItem();
        if (nowPlayingItem != nil) {
            artistLabel.text = nowPlayingItem?.albumArtist;
            titleLabel.text = nowPlayingItem?.title;
            albumLabel.text = nowPlayingItem?.albumTitle;
        }
    }
    
    @objc func updatePlayerScreen() {
        showSongIndex();
        showSongInfo();
        setSeekbarMinMax();
        todo: if (MusicPlayer.getPlaybackState() == .PAUSED || MusicPlayer.getPlaybackState() == .STOPPED) {
            updatePlaybackTimeLabels(seconds: Int(MusicPlayer.getPlayer().currentTime().seconds));
            updateSeekbarPos(seconds: Int(MusicPlayer.getPlayer().currentTime().seconds));
        }
        setPlayPauseButtonState();
        updateVolumeSlider();
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "outputVolume" && !volumeBeingChangedManually) {
            updateVolumeSlider();
        }
    }
    
    func updateVolumeSlider() {
        let vol = AVAudioSession.sharedInstance().outputVolume;
        volumeSlider.value = vol;
    }
    
    func showSongIndex() {
        let indexText = "\(MusicPlayer.getCurrentItemIndex() + 1)/\(MusicPlayer.getQueue().count)";
        songIndexLabel.text = indexText;
    }
    
    @IBAction func songSeekbarSeekingStarted(_ sender: UISlider) {
        wasPlayingBeforeSeek = MusicPlayer.getPlaybackState() == .PLAYING;
                MusicPlayer.pause();
    }
    
    @IBAction func songSeekbarSeekingEnded(_ sender: UISlider) {
        if (wasPlayingBeforeSeek) {
            MusicPlayer.seek(to: Double(sender.value), playbackRate: 1);
        } else {
            MusicPlayer.seek(to: Double(sender.value), playbackRate: 0);
        }
        updateSeekbarPos(seconds: Int(sender.value));
        if (wasPlayingBeforeSeek) {
            MusicPlayer.resume();
        }
    }
    
    @IBAction func songSeekbarValueChanged(_ sender: UISlider) {
        updatePlaybackTimeLabels(seconds: Int(sender.value));
    }
    
    func updateSeekbarPos(seconds: Int) {
        songSeekbar.value = Float(seconds);
    }
    
    func setSeekbarMinMax() {
        if (MusicPlayer.getCurrentItem() != nil) {
            let nowPlayingItemPlaybackDuration = Int(MusicPlayer.getCurrentItem()!.playbackDuration);
            
            songSeekbar.minimumValue = 0.0;
            songSeekbar.maximumValue = Float(nowPlayingItemPlaybackDuration);
        }
    }
    
    func updatePlaybackTimeLabels(seconds: Int) {
        let nowPlayingItemPlaybackDuration = Int((MusicPlayer.getCurrentItem()?.playbackDuration)!);
        
        let currTimeDict = getHoursMinutesSecondsFromSeconds(seconds: seconds);
        let currHours: Int = currTimeDict["h"]!;
        let currMins: Int = currTimeDict["m"]!;
        let currSecs: Int = currTimeDict["s"]!;
        
        let remainingTime = nowPlayingItemPlaybackDuration - seconds;
        let remainingTimeDict = getHoursMinutesSecondsFromSeconds(seconds: remainingTime);
        let remainingHours: Int = remainingTimeDict["h"]!;
        let remainingMins: Int = remainingTimeDict["m"]!;
        let remainingSecs: Int = remainingTimeDict["s"]!;
        
        var currentTimeText = "";
        var remainingTimeText = "";
        if (nowPlayingItemPlaybackDuration < 3600) {
            currentTimeText = String.init(format: "%d:%02d", currMins, currSecs);
            remainingTimeText = String.init(format: "﹣%d:%02d", remainingMins, remainingSecs);
        } else {
            currentTimeText = String.init(format: "%d:%02d:%02d", currHours, currMins, currSecs);
            remainingTimeText = String.init(format: "﹣%d:%02d:%02d", remainingHours, remainingMins, remainingSecs);
        }
                
        currentTimeLabel.text = currentTimeText;
        remainingTimeLabel.text = remainingTimeText;
    }
    
    func getHoursMinutesSecondsFromSeconds(seconds: Int) -> [String: Int] {
        var dict = [String: Int]();
        
        let hours = Int(seconds / 3600);
        let minutes = Int((seconds % 3600) / 60);
        let seconds = Int(((seconds % 3600) % 60));
        
        dict["h"] = hours;
        dict["m"] = minutes;
        dict["s"] = seconds;
        
        return dict;
    }
}
