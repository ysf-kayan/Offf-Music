//
//  CurrentQueueInfo.swift
//  offf
//
//  Created by Yusuf Kayan on 8.11.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//
import MediaPlayer

class SessionInfo: Codable {
    var queue: [MPMediaEntityPersistentID] = [];
    var originalQueue: [MPMediaEntityPersistentID] = [];
    var index: Int = 0;
    var loopStatus: LoopStatus = .NO_LOOP;
    var shuffleStatus: ShuffleStatus = .NO_SHUFFLE;
}
