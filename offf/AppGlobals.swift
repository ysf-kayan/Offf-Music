//
//  File.swift
//  offf
//
//  Created by Yusuf Kayan on 22.06.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import Foundation
import MediaPlayer

class AppGlobals: NSObject {
    static let UPDATE_PLAYER_SCREEN = "UPDATE_PLAYER_SCREEN";
    
    static func isAlpha(val: String) -> Bool {
        let chars = "ABCÇDEFGĞHIİJKLMNOÖPQRSŞTUÜVWXYZabcçdefgğhıijklmnoöpqrsştuüvwxyz";
        return chars.contains(val);
    }
    
    static func isNumeric(val: String) -> Bool {
        let nums = "0123456789";
        return nums.contains(val);
    }
    
    static func createLastPosDictIfDoesNotExist() {
        var lastPosDict = UserDefaults.standard.value(forKey: "lastPosDict");
        if (lastPosDict == nil) {
            lastPosDict = [String: Double]();
            UserDefaults.standard.setValue(lastPosDict, forKey: "lastPosDict");
        }
    }
    
    static func saveLastPosInfoOfSong(song: MPMediaItem?, pos: TimeInterval) {
        var lastPosDict = getLastPosDict();
        if (lastPosDict != nil && song != nil) {
            let songLength = song!.playbackDuration;
            if (songLength >= 600.0 && (songLength - pos) >= 10.0) {
                let key = createSemiUniqueKeyForSong(song: song!);
                lastPosDict![key] = pos;
            }
        }
        
        UserDefaults.standard.setValue(lastPosDict, forKey: "lastPosDict");
    }
    
    static func getLastPosDict() -> [String: Any?]? {
        return UserDefaults.standard.dictionary(forKey: "lastPosDict");
    }
    
    static func getLastPlaybackPositionForSong(song: MPMediaItem) -> Double? {
        let key = createSemiUniqueKeyForSong(song: song);
        let lastPosDict = getLastPosDict();
        
        if (lastPosDict!.keys.contains(key)) {
            let lastPosForSong: Double = lastPosDict![key] as! Double;
            return lastPosForSong;
        }
        return nil;
    }
    
    private static func createSemiUniqueKeyForSong(song: MPMediaItem) -> String {
        // This key may be not unique you know!
        var key = "";
        if (song.title != nil) {
            key.append("\(song.title!)");
        } else {
            key.append("title");
        }
        
        if (song.artist != nil) {
            key.append("\(song.artist!)");
        } else {
            key.append("artist");
        }
        
        if (song.albumArtist != nil) {
            key.append("\(song.albumArtist!)");
        } else {
            key.append("albumArtist");
        }
        
        if (song.albumTitle != nil) {
            key.append("\(song.albumTitle!)");
        } else {
            key.append("albumTitle");
        }
        
        key.append("\(song.playbackDuration)");

        return key;
    }
    
    static func createSessionInfoIfDoesNotExist() {
        let sessionInfoString = UserDefaults.standard.value(forKey: "sessionInfo");
        if (sessionInfoString == nil) {
            let sessionInfoString = "";
            UserDefaults.standard.setValue(sessionInfoString, forKey: "sessionInfo");
        }
    }
    
    static func saveSessionInfo(currentQueue: [MPMediaItem], originalQueue: [MPMediaItem], index: Int, loopStatus: LoopStatus, shuffleStatus: ShuffleStatus) {
        let sessionInfo = SessionInfo();
        
        currentQueue.forEach { item in
            sessionInfo.queue.append(item.persistentID);
        }
        originalQueue.forEach { item in
            sessionInfo.originalQueue.append(item.persistentID);
        }
        sessionInfo.index = index;
        sessionInfo.loopStatus = loopStatus;
        sessionInfo.shuffleStatus = shuffleStatus;
        
        var sessionInfoString = "";
        do {
            let sessionInfoStringData = try JSONEncoder().encode(sessionInfo);
            sessionInfoString = String(data: sessionInfoStringData, encoding: String.Encoding.utf8)!;
        } catch {}
        UserDefaults.standard.setValue(sessionInfoString, forKey: "sessionInfo");
    }
    
    static func getOldSessionInfo() -> String {
        return UserDefaults.standard.string(forKey: "sessionInfo")!;
    }
    
    static func createTableFooter(table: UITableView, text: String) -> UIView {
        let footer = UIView(frame: .zero);
        footer.frame = CGRect(x: 0, y: 0, width: table.frame.width, height: (table.visibleCells.first?.frame.height)!);
                
        let footerSeparator = UIView();
        footerSeparator.backgroundColor = table.separatorColor;
        footer.addSubview(footerSeparator);
                
        footerSeparator.translatesAutoresizingMaskIntoConstraints = false;
        let separatorLeading = NSLayoutConstraint(item: footerSeparator, attribute: .leading, relatedBy: .equal, toItem: footer, attribute: .leading, multiplier: 1, constant: table.separatorInset.left);
        let separatorTrailing = NSLayoutConstraint(item: footerSeparator, attribute: .trailing, relatedBy: .equal, toItem: footer, attribute: .trailing, multiplier: 1, constant: -table.separatorInset.right);
        let separatorTop = NSLayoutConstraint(item: footerSeparator, attribute: .top, relatedBy: .equal, toItem: footer, attribute: .top, multiplier: 1, constant: 0);
        let separatorHeight = NSLayoutConstraint(item: footerSeparator, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0.33);
        
        footer.addConstraints([separatorLeading, separatorTrailing, separatorTop, separatorHeight]);
                
        let footerText = UILabel();
        footerText.text = text;
        footerText.textAlignment = .center;
        footerText.textColor = UIColor.init(red: 145/255, green: 145/255, blue: 145/255, alpha: 1);
        footerText.font = UIFont(name: "Helvetica Neue", size: 15);
        
        footer.addSubview(footerText);
                
        footerText.translatesAutoresizingMaskIntoConstraints = false;
        let footerTextLeading = NSLayoutConstraint(item: footerText, attribute: .leading, relatedBy: .equal, toItem: footer, attribute: .leading, multiplier: 1, constant: 0);
        let footerTextTrailing = NSLayoutConstraint(item: footerText, attribute: .trailing, relatedBy: .equal, toItem: footer, attribute: .trailing, multiplier: 1, constant: 0);
        let footerTextTop = NSLayoutConstraint(item: footerText, attribute: .top, relatedBy: .equal, toItem: footerSeparator, attribute: .bottom, multiplier: 1, constant: 0);
        let footerTextBottom = NSLayoutConstraint(item: footerText, attribute: .bottom, relatedBy: .equal, toItem: footer, attribute: .bottom, multiplier: 1, constant: 0);
        
        footer.addConstraints([footerTextLeading, footerTextTrailing, footerTextTop, footerTextBottom]);
        
        
        return footer;
    }
    
    public static func createTotalLengthText(totalSongLength: Int) -> String {
        let weeks = totalSongLength / (7 * 24 * 60 * 60);
        let remainderAfterWeeks = totalSongLength % (7 * 24 * 60 * 60);
        let days = remainderAfterWeeks / (24 * 60 * 60);
        let remainderAfterDays = remainderAfterWeeks % (24 * 60 * 60);
        let hours = remainderAfterDays / (60 * 60);
        let remainderAfterHours = remainderAfterDays % (60 * 60);
        let minutes = remainderAfterHours / 60;
        
        var timeText = "";
        if (weeks > 0) {
            timeText += "\(weeks) weeks";
        }
        if (days > 0) {
            if (timeText != "") {
                timeText += ", ";
            }
            timeText += "\(days) days";
        }
        if (hours > 0) {
            if (timeText != "") {
                timeText += ", ";
            }
            timeText += "\(hours) hours";
        }
        if (minutes > 0) {
            if (timeText != "") {
                timeText += ", ";
            }
            timeText += "\(minutes) minutes";
        }
        
        return timeText;
    }
    
}
