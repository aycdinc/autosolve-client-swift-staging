//
//  AutoSolveDelegate.swift
//  AutoSolveClient
//
//  Created by Scott Kapelewski on 25.05.20.
//  Copyright © 2020 AYCD. All rights reserved.
//

import Foundation
import Emit
import RMQClient

@objc class AutoSolveDelegate: NSObject, RMQConnectionDelegate {
    var lastChannelError: Error?
    var lastConnectionError: Error?
    var lastChannelOpenError: Error?
    var disconnectCalled = false
    var lastDisconnectError: Error?

    var willStartRecoveryConnection: RMQConnection?
    var startingRecoveryConnection: RMQConnection?
    var recoveredConnection: RMQConnection?
    let autoSolve: AutoSolve

    init(autoSolve: AutoSolve) {
        self.autoSolve = autoSolve
    }

    func channel(_ channel: RMQChannel!, error: Error!) {
        lastChannelError = error
        autoSolve.handlerConnectionEvent(connectionEvent: AutoSolveConnectionEvent.ChannelError)
    }

    func connection(_ connection: RMQConnection!, failedToConnectWithError error: Error!) {
        lastConnectionError = error
        autoSolve.handlerConnectionEvent(connectionEvent: AutoSolveConnectionEvent.FailedConnection)
    }

    func connection(_ connection: RMQConnection!, failedToOpenChannel channel: RMQChannel!, error: Error!) {
        lastChannelOpenError = error
        autoSolve.handlerConnectionEvent(connectionEvent: AutoSolveConnectionEvent.ChannelError)
    }

    func connection(_ connection: RMQConnection!, disconnectedWithError error: Error!) {
        disconnectCalled = true
        lastDisconnectError = error
        autoSolve.handlerConnectionEvent(connectionEvent: AutoSolveConnectionEvent.Disconnected)
    }

    func willStartRecovery(with connection: RMQConnection!) {
        autoSolve.handlerConnectionEvent(connectionEvent: AutoSolveConnectionEvent.StartRecovery)
        print("Starting recovery")
        willStartRecoveryConnection = connection
    }

    func startingRecovery(with connection: RMQConnection!) {
        startingRecoveryConnection = connection
    }

    func recoveredConnection(_ connection: RMQConnection!) {
        recoveredConnection = connection
    }
}
