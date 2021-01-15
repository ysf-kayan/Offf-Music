//
//  MusicPlayer.swift
//  offf
//
//  Created by Yusuf Kayan on 25.06.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import Foundation
import MediaPlayer

class MusicPlayer: NSObject {
    private static var avPlayer: AVPlayer?;
    private static var isSetUp = false;
    private static var queue: [MPMediaItem] = [];
    private static var originalQueue: [MPMediaItem] = [];
    private static var currentItemIndex = -1;
    private static var loopStatus: LoopStatus = .NO_LOOP;
    private static var shuffleStatus: ShuffleStatus = .NO_SHUFFLE;
    private static var playbackState: MusicPlayerStatus = .STOPPED;
    private static var pendingSeek = false;
    private static var pendingSeekVal = 0.0;
    private static var instance: MusicPlayer? = nil;
    private static var resumePlaybackAfterRateChange: Bool = false;
    private static var currentItem: MPMediaItem? = nil;
    
    override init() {
        super.init();
        // Bu değişkeni tutma sebebimiz şu, static class herhangi bir değişkende tutulmayınca deinit oluyor
        // O durumda ise rate observer düzgün çalışamıyor. MusicPlayer class'ının deinit olmasını engellemek için
        // bir instance değişkeni tutuyoruz.
        MusicPlayer.instance = self;
        
        MusicPlayer.avPlayer = AVPlayer();

        UIApplication.shared.beginReceivingRemoteControlEvents();
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget(MusicPlayer.self, action: #selector(MusicPlayer.onNextTrackCommand));
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget(MusicPlayer.self, action: #selector(MusicPlayer.onPrevTrackCommand));
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget(MusicPlayer.self, action: #selector(MusicPlayer.onTogglePlayPauseCommand));
        //MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true;
        //MPRemoteCommandCenter.shared().skipForwardCommand.addTarget(MusicPlayer.self, action: #selector(MusicPlayer.onNextTrackCommand));
        MPRemoteCommandCenter.shared().changeShuffleModeCommand.addTarget(MusicPlayer.self, action: #selector(MusicPlayer.changeShuffleMode));
        
        NotificationCenter.default.addObserver(MusicPlayer.self, selector: #selector(MusicPlayer.currentPlayingItemEnd), name: .AVPlayerItemDidPlayToEndTime, object: MusicPlayer.avPlayer?.currentItem);
        
        NotificationCenter.default.addObserver(self,
                       selector: #selector(handleRouteChange),
                       name: AVAudioSession.routeChangeNotification,
                       object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlayerInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil);

    }

    
    @objc func handlePlayerInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
    
        if (type == .began && !(userInfo[AVAudioSessionInterruptionWasSuspendedKey] != nil)) {
            MusicPlayer.pause();
            NotificationCenter.default.post(name: Notification.Name(AppGlobals.UPDATE_PLAYER_SCREEN), object: nil);
        }
    }
    
    @objc func handleRouteChange(notification: Notification) {
        print("routeChanged");
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let _ = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
        }
                
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs;
    
        if (outputs.first!.portType == .builtInSpeaker) {
            DispatchQueue.main.async {
                MusicPlayer.pause();
                NotificationCenter.default.post(name: Notification.Name(AppGlobals.UPDATE_PLAYER_SCREEN), object: nil);
            }
        }
        
    }
    
    static func play(startAt: Int?) {
        
        // Müzikçalar için bir seferliğine AVAudioSession başlat
        if (!isSetUp) {
            setUpAvSession();
        }
        
        if (queue.count > 0) {
            if (playbackState == .PLAYING) {
                // Yeni bir kuyruk başlatıldığında eğer şarkı çalmaktaysa çalmakta olan şarkının
                //    pozisyonunu kaydet.
                AppGlobals.saveLastPosInfoOfSong(song: MusicPlayer.getCurrentItem(), pos: MusicPlayer.getPlayer().currentTime().seconds);
            }
            if (startAt != nil) {
                currentItemIndex = startAt!;
            } else {
                currentItemIndex = 0;
            }
            setCurrentItem();
            setNowPlayingInfo();
            seekToLastSavedPosition();
            playCurrentItem();
        } else {
            print("MusicPlayer: Kuyruk boş olduğu için çalma başlamadı.")
        }
    }
    
    static func setUpAvSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback);
            try AVAudioSession.sharedInstance().setActive(true);
            isSetUp = true;
            print("MusicPlayer: AVAudioSession kurulumu tamamlandı.")
        } catch {
            print("MusicPlayer: AVAudioSession kurulumu sırasında hata oluştu!");
            return;
        }
    }
    
    static func pause() {
        avPlayer?.rate = 0.0;
        setPausedState();
        print("MusicPlayer: Müzik duraklatıldı.")
    }
    
    static func setPausedState() {
        playbackState = .PAUSED;
        // Müzik pause konumuna alındığı anda pozisyonu kaydet, daha sonra oradan devam edilecektir
        // pendingSeekVal değerinin kullanım sebebi: avplayer süresi set edildiğinde player'ın current time'ı
        // set edilmiş süre olarak geri döndürmesi için başlatılması gerekiyor. Başlatıldıktan sonra da doğru süreyi
        // dönmesi için bir süre geçmesi gerekiyor. Bu sebeple kilit ekranındaki süre kaydedilmiş değer ile ayarlanıyor.
        pendingSeekVal = avPlayer!.currentTime().seconds;
        setNowPlayingPlaybackTimeInfo(rate: 0, time: pendingSeekVal);
        AppGlobals.saveLastPosInfoOfSong(song: MusicPlayer.getCurrentItem(), pos: MusicPlayer.getPlayer().currentTime().seconds);
    }
    
    static func stop() {
        playbackState = .STOPPED;
        avPlayer?.rate = 0.0;
        seek(to: 0, playbackRate: 0);
    }
    
    static func resume() {
        playbackState = .PLAYING;
        avPlayer?.play();
        setNowPlayingPlaybackTimeInfo(rate: 1, time: pendingSeekVal);
        print("MusicPlayer: Müzik devam ettirildi.");
    }
    
    static func setUpFromOldSession(oldSessionInfo: SessionInfo) {
        var queue: [MPMediaItem] = [];
        
        MusicPlayer.setShuffleStatus(shuffleStatus: oldSessionInfo.shuffleStatus);
        MusicPlayer.setLoopStatus(loopStatus: oldSessionInfo.loopStatus);
        
        oldSessionInfo.queue.forEach { (songId) in
            let s = SongList.getAllSongsList().first { (song) in
                return song.persistentID == songId;
            }
            if (s != nil) {
                queue.append(s!);
            }
        }
        
        self.queue = queue;
        
        if (oldSessionInfo.originalQueue.count > 0) {
            var newOriginalQueue: [MPMediaItem] = [];
            oldSessionInfo.originalQueue.forEach { (songId) in
                let s = SongList.getAllSongsList().first { (song) in
                    return song.persistentID == songId;
                }
                if (s != nil) {
                    newOriginalQueue.append(s!);
                }
            }
            originalQueue = newOriginalQueue;
        }
        
        MusicPlayer.setCurrentItemIndex(index: oldSessionInfo.index);
        MusicPlayer.setCurrentItem();
        seekToLastSavedPosition();
        MusicPlayer.setUpAvSession();
        
        print("MusicPlayer: setUpFromOldSession()");
    }
    
    static func getPlaybackState() -> MusicPlayerStatus {
        return playbackState;
    }
    
    private static func playCurrentItem() {
        avPlayer?.play();
        playbackState = .PLAYING;
        print("MusicPlayer: \(queue[currentItemIndex].title!) çalınıyor...");
    }
    
    static func setQueue(newQueue: [MPMediaItem]) {
        queue = newQueue;
        originalQueue = queue;
        shuffleStatus = .NO_SHUFFLE;
        currentItem = nil;
        print("MusicPlayer: Kuyruk ayarlandı.");
    }
    
    private static func setOriginalQueue(newQueue: [MPMediaItem]) {
        originalQueue = newQueue;
    }
    
    static func seek(to: Double, playbackRate: Double) {
        avPlayer!.seek(to: CMTime(seconds: to, preferredTimescale: .max), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero);
        pendingSeekVal = to;
        setNowPlayingPlaybackTimeInfo(rate: playbackRate, time: pendingSeekVal);
    }
    
    static func seekToLastSavedPosition() {
        let lastSavedPlaybackPosition = getLastSavedPlaybackPosition(song: getCurrentItem()!);
        if (lastSavedPlaybackPosition != nil) {
            seek(to: lastSavedPlaybackPosition!, playbackRate: 1);
        }
    }
    
    static func fastForward(seconds: Double) {
        if (seconds <= 0) {return};
        
        let currentTimeInSeconds = avPlayer!.currentTime().seconds;
        let newTimeInSeconds = currentTimeInSeconds + seconds;
        let totalTime = currentItem!.playbackDuration;
        
        if (newTimeInSeconds < totalTime + 5) {
            seek(to: newTimeInSeconds, playbackRate: 1.0);
        }
    }
    
    static func fastBackward(seconds: Double) {
        if (seconds < 0) {return;}
        
        let currentTimeInSeconds = avPlayer!.currentTime().seconds;
        let newTimeInSeconds = currentTimeInSeconds - seconds;
        
        if (newTimeInSeconds > 0) {
            seek(to: newTimeInSeconds, playbackRate: 1.0);
        }
    }
    
    private static func getLastSavedPlaybackPosition(song: MPMediaItem) -> Double? {
        let lastPos = AppGlobals.getLastPlaybackPositionForSong(song: song);
        return lastPos;
    }
    
    static func getQueue() -> [MPMediaItem] {
        return queue;
    }
    
    static func getOriginalQueue() -> [MPMediaItem] {
        return originalQueue;
    }
    
    static func getCurrentItemIndex() -> Int {
        return currentItemIndex;
    }
    
    static func setCurrentItemIndex(index: Int) {
        currentItemIndex = index;
    }
    
    private static func setCurrentItem() {
        let avPlayerItem = AVPlayerItem(url: queue[getCurrentItemIndex()].assetURL!);
        avPlayer?.replaceCurrentItem(with: avPlayerItem);
        currentItem = queue[getCurrentItemIndex()];
    }
    
    static func getCurrentItem() -> MPMediaItem? {
        return currentItem;
    }
    
    static func getPlayer() -> AVPlayer {
        return avPlayer!;
    }
    
    private static func setNowPlayingInfo()
    {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default();
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]();

        let titleText = "\(currentItemIndex + 1)•\(queue.count) \(queue[currentItemIndex].title!)";
        let artistAlbum = "\(queue[currentItemIndex].albumTitle!)";
        //let artworkData = Data()
        //let image = UIImage(data: artworkData) ?? UIImage()
        //let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
         //   return image
        //})
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = titleText;
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = artistAlbum;
        //nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork

        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = getCurrentItem()?.playbackDuration;
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = avPlayer?.currentTime().seconds;
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0;
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo;
        
        
        print("MusicPlayer: NowPlayingInfo ayarlandı.");
    }
    
    static func setNowPlayingPlaybackTimeInfo(rate: Double, time: Double) {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default();
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]();
        
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = getCurrentItem()?.playbackDuration;
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time;
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate;
        
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo;
    }
    
    @objc private static func onPrevTrackCommand(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("MusicPlayer: previousTrackCommand alındı.");
        
        previousTrack();
        
        return MPRemoteCommandHandlerStatus.success;
    }
    
    @objc private static func onNextTrackCommand(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("MusicPlayer: nextTrackCommand alındı.");
        
        nextTrack(skippedByUser: true);
        
        return MPRemoteCommandHandlerStatus.success;
    }
    
    @objc private static func onTogglePlayPauseCommand(_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        print("MusicPlayer: togglePlayPauseCommand alındı.");
        
        if (getPlaybackState() == .PLAYING) {
            pause();
        } else {
            resume();
        }
        
        NotificationCenter.default.post(name: Notification.Name(AppGlobals.UPDATE_PLAYER_SCREEN), object: nil);
        return MPRemoteCommandHandlerStatus.success;
    }
    
    @objc static func currentPlayingItemEnd() {
        print("MusicPlayer: Current item çalma bitti!");
        nextTrack(skippedByUser: false);
    }
    
    static func previousTrack() {
        let currentTimeInSeconds = avPlayer?.currentTime().seconds;
        
        if (currentTimeInSeconds != nil && currentTimeInSeconds! >= 10.0) {
            if (playbackState == .PLAYING) {
                seek(to: 0, playbackRate: 1);
            } else {
                seek(to: 0, playbackRate: 0);
            }
            print("MusicPlayer: Şarkı zamanı başlangıca sarıldı");
        } else {
            if (currentItemIndex - 1 > -1) {
                currentItemIndex -= 1;
                print("MusicPlayer: Önceki şarkıya geçildi.");
            } else {
                currentItemIndex = getQueue().count - 1;
                print("MusicPlayer: Liste başında önceki şarkıya geçildi!");
            }
            setCurrentItem();
            setNowPlayingInfo();
            let lastSavedPlaybackPosition = getLastSavedPlaybackPosition(song: getCurrentItem()!);
            let playbackRate = playbackState == .PLAYING ? 1.0 : 0.0;
            if (lastSavedPlaybackPosition != nil) {
                seek(to: lastSavedPlaybackPosition!, playbackRate: playbackRate);
            } else {
                seek(to: 0, playbackRate: playbackRate);
            }
            if (playbackState == .PLAYING) {
                playCurrentItem();
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name(AppGlobals.UPDATE_PLAYER_SCREEN), object: nil);
    }
    
    // skippedByUser değeri true olduğunda şarkı bitmeden kullanıcı sonraki şarkıya
    // geçmiştir.
    static func nextTrack(skippedByUser: Bool) {
        
        if (!skippedByUser && loopStatus == .STOP_AFTER_ONE) {
            print("MusicPlayer: Bir şarkıdan sonra dur seçeneği aktif olduğu için sonraki şarkıya geçilmedi");
            stop();
        }
        else if ((currentItemIndex + 1 < queue.count) || (loopStatus == .LOOP_LIST) || loopStatus == .LOOP_ONE || skippedByUser ) {
            AppGlobals.saveLastPosInfoOfSong(song: MusicPlayer.getCurrentItem(), pos: MusicPlayer.getPlayer().currentTime().seconds);
            if (!skippedByUser && loopStatus == .LOOP_ONE) {
                currentItemIndex -= 1;
            }
            if (currentItemIndex + 1 >= queue.count) {
                currentItemIndex = -1;
            }
            currentItemIndex += 1;
            setCurrentItem();
            setNowPlayingInfo();
            let lastSavedPlaybackPosition = getLastSavedPlaybackPosition(song: getCurrentItem()!);
            let playbackRate = playbackState == .PLAYING ? 1.0 : 0.0;
            if (lastSavedPlaybackPosition != nil) {
                seek(to: lastSavedPlaybackPosition!, playbackRate: playbackRate);
            } else {
                seek(to: 0, playbackRate: playbackRate);
            }
            if (playbackState == .PLAYING) {
                playCurrentItem();
                print("playcurrent");
            }
            print("MusicPlayer: Sonraki şarkıya geçildi.");
        } else {
            print("MusicPlayer: Liste sonunda sonraki şarkıya geçilmedi!");
            stop();
        }
        
        NotificationCenter.default.post(name: Notification.Name(AppGlobals.UPDATE_PLAYER_SCREEN), object: nil);
    }
    
    @objc private static func changeShuffleMode() -> MPRemoteCommandHandlerStatus {
        print("MusicPlayer: changleShuffleModeCommand alındı.");
                
        return MPRemoteCommandHandlerStatus.success;
    }
    
    public static func setShuffle(shuffle: ShuffleStatus) {
        MusicPlayer.shuffleStatus = shuffle;
        
        if (MusicPlayer.shuffleStatus == .SHUFFLE) {
            print("MusicPlayer: setShuffle(true)");
            originalQueue = queue;
            var shuffledQueue: [MPMediaItem] = [];
            if (currentItem != nil) {
                shuffledQueue.append(currentItem!);
            }
            queue.shuffled().forEach { (item) in
                if (item != currentItem) {
                    shuffledQueue.append(item);
                }
            }
            queue = shuffledQueue;
            currentItemIndex = 0;
        } else {
            print("MusicPlayer: setShuffle(false)")
            
            queue = originalQueue;
            originalQueue = [];
            currentItemIndex = queue.firstIndex(of: currentItem!)!;
        }
        NotificationCenter.default.post(name: Notification.Name(AppGlobals.UPDATE_PLAYER_SCREEN), object: nil);
    }
    
    private static func setShuffleStatus(shuffleStatus: ShuffleStatus) {
        self.shuffleStatus = shuffleStatus;
    }
    
    public static func getShuffleStatus() -> ShuffleStatus {
        return self.shuffleStatus;
    }
    
    public static func setLoopStatus(loopStatus: LoopStatus) {
        print("MusicPlayer: setLoopStatus(\(loopStatus))");
        MusicPlayer.loopStatus = loopStatus;
    }
    
    public static func getLoopStatus() -> LoopStatus {
        return MusicPlayer.loopStatus;
    }
}

enum MusicPlayerStatus {
    case PLAYING
    case PAUSED
    case STOPPED
}
