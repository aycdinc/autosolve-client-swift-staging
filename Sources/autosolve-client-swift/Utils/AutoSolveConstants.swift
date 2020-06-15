//
//  AutoSolveConstants.swift
//  swift-test
//
//  Created by Scott Kapelewski on 22.05.20.
//  Copyright © 2020 Scott Kapelewski. All rights reserved.
//

import Foundation

public class AutoSolveConstants {
    static let Hostname = "rabbit.autosolve.io";
    static let DirectExchange = "exchanges.direct";
    static let FanoutExchange = "exchanges.fanout";
    static let TokenResponseQueuePrefix = "queues.response.direct"
    static let TokenSendRoutingKey = "routes.request.token"
    static let TokenResponseRoutingKey = "routes.response.token"
    static let CancelSendRoutingKey = "routes.request.token.cancel"
    static let CancelResponseRoutingKey = "routes.response.token.cancel"
    static let Vhost = "oneclick"
    
    static let TokenRequest = "TokenRequest"
    static let CancelRequest = "CancelRequest"
    static let TokenResponse = "TokenResponse"
    static let CancelResponse = "CancelResponse"
    
    static let SuccessStatusCode = 200
    static let InvalidClientKeyStatusCode = 400
    static let InvalidCredentialsStatusCode = 401
    static let TooManyRequests = 429

}
