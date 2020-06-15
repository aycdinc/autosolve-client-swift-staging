//
//  AutoSolveError.swift
//  swift-test
//
//  Created by Scott Kapelewski on 22.05.20.
//  Copyright © 2020 Scott Kapelewski. All rights reserved.
//

import Foundation

public enum AutoSolveError : Error {
    case InvalidClientKey
    case InvalidApiKeyOrToken
    case TooManyRequests
    case InputValueError
    case InitConnectionError
    case ChannelNotInitialized
    case UnknownMessageReceived
    case MessageSendError
}
