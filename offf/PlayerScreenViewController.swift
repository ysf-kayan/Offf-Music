//
//  PlayerScreenViewController.swift
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

enum Direction {
    case LEFT
    case RIGHT
}

let swingAnimConstant: Float = 0.1;

class PlayerScreenViewController: UIViewController {

    
    @IBOutlet weak var hiddenVolumeSliderContainer: UIView!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var songIndexLabel: UILabel!
    @IBOutlet weak var seekbarContainer: UIView!
    @IBOutlet weak var songSeekbar: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var playPauseSkipContainer: UIView!
    @IBOutlet weak var playPauseButton: MyUIButton!
    @IBOutlet weak var loopShuffleContainer: UIView!
    @IBOutlet weak var loopButton: LoopButton!
    @IBOutlet weak var shuffleButton: ShuffleButton!
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var previousButtonImage: UIImageView!
    @IBOutlet weak var playPauseButtonImage: UIImageView!
    
    
    @IBOutlet weak var vinyl1Container: UIView!
    @IBOutlet weak var vinyl1Image: UIImageView!
    @IBOutlet weak var vinyl1LightImage: UIImageView!
    @IBOutlet weak var vinyl2Container: UIView!
    @IBOutlet weak var vinyl2Image: UIImageView!
    @IBOutlet weak var vinyl2LightImage: UIImageView!
    
    
    @IBOutlet weak var artistLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var albumLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var songIndexLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var loopShuffleContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var previousButtonImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextButtonImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playPauseButtonImageHeightConstraint: NSLayoutConstraint!
    
    var command = PlayerCommand.SHOW_PLAYER;
    var songList: [MPMediaItem] = [];
    var volumeView: MPVolumeView? = nil;
    var timeObserverToken: Any?;
    var seeking: Bool = false;
    var wasPlayingBeforeSeek = false;
    var volumeBeingChangedManually = false;
    var volumeBeingChangedManuallyAsyncTask: DispatchWorkItem? = nil;
    
    var animationsInitialized = false;
    var controlsContainerHeight: CGFloat = 0;
    var controlsResized = false;
    
    var vinylAnimator: UIViewPropertyAnimator!;
    var lightAnimator: UIViewPropertyAnimator!;
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(restartAnimationsAfterEnteringForeground), name: UIApplication.willEnterForegroundNotification, object: nil);
        
    
        print("viewDidLoad()");
    }
    
    private func rotateVinyl(animCount: Int) {
        vinylAnimator = UIViewPropertyAnimator(duration: TimeInterval(animCount * 5), curve: .linear, animations: nil);

        vinylAnimator.addAnimations {
            for _ in 1...animCount {
                self.vinyl2Image.transform = self.vinyl2Image.transform.rotated(by: CGFloat.pi);
            }
        }
        
        vinylAnimator.addCompletion { (_) in
            self.rotateVinyl(animCount: animCount);
        }
        
        vinylAnimator.startAnimation();
    }
    
    private func swingLight(backward: Bool) {
        lightAnimator = UIViewPropertyAnimator(duration: 2.5, curve: .easeInOut, animations: nil);
        
        lightAnimator.addAnimations {
            let deg = backward ? Float.pi * swingAnimConstant : -Float.pi * swingAnimConstant;
            self.vinyl2LightImage.transform = self.vinyl2LightImage.transform.rotated(by: CGFloat(deg));
        }
        
        lightAnimator.addCompletion { (_) in
            self.swingLight(backward: !backward);
        }
        
        lightAnimator.startAnimation();
    }
    
    @objc private func restartAnimationsAfterEnteringForeground() {
        if (MusicPlayer.getPlaybackState() == .PLAYING) {
            //resumeVinylPlayingAnimation();
        }
    }
        
    private func startVinylPlayingAnimation() {
        rotateVinyl(animCount: 1);
        swingLight(backward: false);
    }
    
    private func resumeVinylPlayingAnimation() {
        createVinylAnimationsIfNeeded();
        
        vinylAnimator.continueAnimation(withTimingParameters: vinylAnimator.timingParameters, durationFactor: 1 - vinylAnimator.fractionComplete);
        lightAnimator.continueAnimation(withTimingParameters: lightAnimator.timingParameters, durationFactor: 1 - lightAnimator.fractionComplete);
    }
    
    private func stopVinylPlayingAnimation() {
        vinylAnimator.pauseAnimation();
        lightAnimator.pauseAnimation();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updatePlayerScreen), name: Notification.Name(AppGlobals.UPDATE_PLAYER_SCREEN), object: nil);
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil);
        
        
        let timeScale = CMTimeScale(NSEC_PER_SEC);
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale);
        
        timeObserverToken = MusicPlayer.getPlayer().addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            if (!self!.seeking) {
                self!.updatePlaybackTimeLabels(seconds: Int(time.seconds));
                self!.updateSeekbarPos(seconds: Int(time.seconds));
            }
        };
                
        updatePlayerScreen();
        print("viewWillAppear");
    }
    
    private func createVinylAnimationsIfNeeded() {
        if (!animationsInitialized) {
            if (MusicPlayer.getPlaybackState() == .PLAYING) {
                startVinylPlayingAnimation();
                animationsInitialized = true;
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        //print("viewDidLayoutSubviews()");
        createVinylAnimationsIfNeeded();
        
        if (controlsContainerHeight != controlsView.frame.height) {
            controlsContainerHeight = controlsView.frame.height;
            controlsResized = false;
        }
        
        if (!controlsResized) {
            print("controlsResized");
            var constantSizesTotal: CGFloat = 0;
            constantSizesTotal += seekbarContainer.frame.height;
            constantSizesTotal += loopShuffleContainer.frame.height;
            constantSizesTotal += volumeSlider.frame.height;
            
            let remainingSize = controlsView.frame.height - constantSizesTotal;
            
            titleViewHeightConstraint.constant = remainingSize * 32.6 / 100;
            prepareTitleView();
            
            var playPauseButtonsContainerHeight = remainingSize - titleViewHeightConstraint.constant;
            
            if (playPauseButtonsContainerHeight < 50.0) {
                let playPauseAndLoopShuffleTotalHeight = playPauseButtonsContainerHeight + 50;
                loopShuffleContainerHeightConstraint.constant = playPauseAndLoopShuffleTotalHeight / 2;
                playPauseButtonsContainerHeight = loopShuffleContainerHeightConstraint.constant;
            }
            
            if (playPauseButtonsContainerHeight < previousButtonImageHeightConstraint.constant) {
                previousButtonImageHeightConstraint.constant = playPauseButtonsContainerHeight;
                nextButtonImageHeightConstraint.constant = playPauseButtonsContainerHeight;
                playPauseButtonImageHeightConstraint.constant = playPauseButtonsContainerHeight;
            }
            
            controlsResized = true;
        }
    }
        
    private func prepareTitleView() {
        let titleViewHeight = titleViewHeightConstraint.constant;
        let unitHeight = titleViewHeight / (1 + 1 + 1.4 + 1);
        artistLabelHeightConstraint.constant = unitHeight;
        albumLabelHeightConstraint.constant = unitHeight;
        songIndexLabelHeightConstraint.constant = unitHeight;
        
        let artistLabelHeight = unitHeight;
        let titleLabelHeight = titleViewHeight - (unitHeight * 3);
        titleLabelHeightConstraint.constant = titleLabelHeight;
                
        artistLabel.font = getFontForHeight(font: artistLabel.font, height: artistLabelHeight);
        
        titleLabel.font = getFontForHeight(font: titleLabel.font, height: titleLabelHeight);

        albumLabel.font = artistLabel.font;
        songIndexLabel.font = artistLabel.font;
    }
    
    private func getFontForHeight(font: UIFont, height: CGFloat) -> UIFont {
        let initialFontSize = 0.5;
        let fontSizeIncreaseStep = 0.5;
        
        var fontSize = initialFontSize;
        var font = UIFont(descriptor: font.fontDescriptor, size: CGFloat(fontSize));
        while font.lineHeight <= height {
            fontSize += fontSizeIncreaseStep;
            font = UIFont(descriptor: font.fontDescriptor, size: CGFloat(fontSize));
        }
        font = UIFont(descriptor: font.fontDescriptor, size: CGFloat(fontSize - fontSizeIncreaseStep));
        
        return font;
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default);
        navigationController?.navigationBar.shadowImage = nil;
        
        MusicPlayer.getPlayer().removeTimeObserver(timeObserverToken!);
        NotificationCenter.default.removeObserver(self, name: Notification.Name(AppGlobals.UPDATE_PLAYER_SCREEN), object: nil);
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume");
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil);
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
        
        let vinyl1Anim = createVinylMoveAnimation(values: [vinyl1Container.frame.origin.x + vinyl1Container.frame.width / 2, -(10 + vinyl1Container.frame.width / 2)]);
        vinyl1Container.layer.add(vinyl1Anim, forKey: "moveLeft");
        
        let vinyl2InitialX = (vinyl2Container.frame.origin.x + vinyl2Container.frame.width / 2) + vinyl2Container.frame.width + 25;
        let vinyl2NewX = vinyl2Container.frame.origin.x + vinyl2Container.frame.width / 2;
        let vinyl2Anim = createVinylMoveAnimation(values: [vinyl2InitialX, vinyl2NewX]);
        
        vinyl2Container.layer.add(vinyl2Anim, forKey: "moveLeft");
    }
    
    @IBAction func nextButtonLongPress(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == .began) {
            MusicPlayer.fastForward(seconds: 30);
        }
    }
    
    @IBAction func previousButtonClicked(_ sender: UITapGestureRecognizer) {
        MusicPlayer.previousTrack();
        
        let vinyl1Anim = createVinylMoveAnimation(values: [-(10 + vinyl1Container.frame.width / 2), vinyl1Container.frame.origin.x + vinyl1Container.frame.width / 2]);
        vinyl1Container.layer.add(vinyl1Anim, forKey: "moveRight");
        
        let vinyl2InitialX = (vinyl2Container.frame.origin.x + vinyl2Container.frame.width / 2) + vinyl2Container.frame.width + 25;
        let vinyl2NewX = vinyl2Container.frame.origin.x + vinyl2Container.frame.width / 2;
        let vinyl2Anim = createVinylMoveAnimation(values: [vinyl2NewX, vinyl2InitialX]);
        
        vinyl2Container.layer.add(vinyl2Anim, forKey: "moveRight");
    }
    
    private func moveVinyls(direction: Direction) {
        
        let vinyl1X1 = vinyl1Container.frame.origin.x + vinyl1Container.frame.width / 2;
        let vinyl1X2 = -(10 + vinyl1Container.frame.width / 2);
        
        var vinyl1Anim: CAAnimation?;
        if (direction == Direction.LEFT) {
            vinyl1Anim = createVinylMoveAnimation(values: [vinyl1X1, vinyl1X2]);
        } else if (direction == Direction.RIGHT) {
            vinyl1Anim = createVinylMoveAnimation(values: [vinyl1X2, vinyl1X1]);
        }
        vinyl1Container.layer.add(vinyl1Anim!, forKey: direction == Direction.LEFT ? "moveLeft" : "moveRight");
        
        let vinyl2X1 = (vinyl2Container.frame.origin.x + vinyl2Container.frame.width / 2) + vinyl2Container.frame.width + 25;
        let vinyl2X2 = vinyl2Container.frame.origin.x + vinyl2Container.frame.width / 2;
        var vinyl2Anim: CAAnimation?;
        if (direction == Direction.LEFT) {
            vinyl2Anim = createVinylMoveAnimation(values: [vinyl2X1, vinyl2X2]);
        } else if (direction == Direction.RIGHT) {
            vinyl2Anim = createVinylMoveAnimation(values: [vinyl2X2, vinyl2X1]);
        }
        vinyl2Container.layer.add(vinyl2Anim!, forKey: direction == Direction.LEFT ? "moveLeft" : "moveRight");
    }
    
    @IBAction func playPauseClicked(_ sender: MyUIButton) {
        if (MusicPlayer.getPlaybackState() == .PLAYING) {
            MusicPlayer.pause();
            stopVinylPlayingAnimation();
        } else {
            MusicPlayer.resume();
            resumeVinylPlayingAnimation();
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
            playPauseButtonImage.image = UIImage(systemName: "pause.fill");
        } else {
            playPauseButtonImage.image = UIImage(systemName: "play.fill");
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
    
    public func createVinylMoveAnimation(values: [CGFloat]) -> CAKeyframeAnimation {
        let moveAnimation = CAKeyframeAnimation(keyPath: "position.x");
        moveAnimation.values = values;
        moveAnimation.duration = 0.25;
        moveAnimation.fillMode = .forwards;
        moveAnimation.isRemovedOnCompletion = true;
        return moveAnimation;
    }
    
    deinit {
        print("PlayerScreenViewController deinit()");
    }
}
