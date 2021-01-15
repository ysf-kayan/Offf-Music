//
//  AppDelegate.swift
//  offf
//
//  Created by Yusuf Kayan on 17.06.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import UIKit
import MediaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        _ = AppGlobals();
        AppGlobals.createLastPosDictIfDoesNotExist();
        AppGlobals.createSessionInfoIfDoesNotExist();
        _ = MusicPlayer();
        _ = SongList();
        
        let oldSessionInfoString = AppGlobals.getOldSessionInfo();
        if (oldSessionInfoString != "") {
            var oldSessionInfo: SessionInfo? = nil;
            do {
                oldSessionInfo = try JSONDecoder().decode(SessionInfo.self, from: oldSessionInfoString.data(using: .utf8)!);
            } catch {}
            
            if (oldSessionInfo != nil && oldSessionInfo!.queue.count > 0) {
                MusicPlayer.setUpFromOldSession(oldSessionInfo: oldSessionInfo!);
            }
        }
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("Uygulama geberiyoooooor!");
        AppGlobals.saveLastPosInfoOfSong(song: MusicPlayer.getCurrentItem(), pos: MusicPlayer.getPlayer().currentTime().seconds);
        
        AppGlobals.saveSessionInfo(currentQueue: MusicPlayer.getQueue(), originalQueue: MusicPlayer.getOriginalQueue(), index: MusicPlayer.getCurrentItemIndex(), loopStatus: MusicPlayer.getLoopStatus(), shuffleStatus: MusicPlayer.getShuffleStatus());
        
        UIApplication.shared.endReceivingRemoteControlEvents();
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

