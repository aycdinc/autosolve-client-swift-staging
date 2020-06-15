//
//  AutoSolveConnectionEvent1.swift
//  AutoSolveClient
//
//  Created by Scott Kapelewski on 25.05.20.
//  Copyright © 2020 AYCD. All rights reserved.
//

import Foundation

public enum AutoSolveConnectionEvent {
    case Disconnected
    case FailedConnection
    case StartRecovery
    case ChannelError
}
