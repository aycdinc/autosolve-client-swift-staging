//
// Created by Scott Kapelewski on 26.05.20.
// Copyright (c) 2020 AYCD. All rights reserved.
//

import Foundation
import RMQClient

class AutoSolveDeliveryHandler : RMQConsumer{
    public var autoSolve: AutoSolve?

    override init!(channel: RMQChannel!, queueName: String!, options: RMQBasicConsumeOptions) {
        super.init(channel: channel, queueName: queueName, options: options)
    }

    override func consume(_ message: RMQMessage) {
        guard let jsonMessage = String(data: message.body, encoding: .utf8) else { return }

        switch message.routingKey {
        case autoSolve!.tokenResponseRoutingKey:
            let autoSolveMessage = Encoding.decode(message: jsonMessage, classType: AutoSolveConstants.TokenResponse)
            if(autoSolveMessage != nil) {
                let result = autoSolveMessage as! AutoSolveTokenResponse
                autoSolve!.debugLogger(message: "Received token for task : \(result.taskId) :: \(result.token)")
                autoSolve!.responseEmitter.emit(result)
            }
        case autoSolve!.cancelResponseRoutingKey:
            let autoSolveMessage = Encoding.decode(message: jsonMessage, classType: AutoSolveConstants.CancelResponse)
            if(autoSolveMessage != nil) {
                let result = autoSolveMessage as! AutoSolveCancelResponse
                autoSolve!.debugLogger(message: "Received \(result.requests.count) cancel(s) from OneClick")
                autoSolve!.cancelEmitter.emit(result)
            }

        default:
            autoSolve!.errorEmitter.emit(AutoSolveError.UnknownMessageReceived)
        }
    }
}