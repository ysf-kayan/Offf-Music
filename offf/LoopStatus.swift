//
//  LoopStatus.swift
//  offf
//
//  Created by Yusuf Kayan on 1.11.2020.
//  Copyright © 2020 Yusuf Kayan. All rights reserved.
//

import Foundation

enum LoopStatus: Int, Codable {
    case NO_LOOP
    case LOOP_LIST
    case LOOP_ONE
    case STOP_AFTER_ONE
}
