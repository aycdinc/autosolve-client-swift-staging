//
//  AutoSolveCancelRequest.swift
//  swift-test
//
//  Created by Scott Kapelewski on 22.05.20.
//  Copyright © 2020 Scott Kapelewski. All rights reserved.
//

import Foundation

public class AutoSolveCancelRequest : AutoSolveRequest {
    var taskId: String
    var apiKey: String
    var createdAt: Int
    var responseRequired: Bool
    
    public init(taskId: String = "", apiKey: String, responseRequired: Bool) {
        self.taskId = taskId
        self.apiKey = apiKey
        self.createdAt = Int(Date().timeIntervalSince1970.rounded())
        self.responseRequired = responseRequired
    }
    
    func type() -> String {
        return AutoSolveConstants.CancelRequest
    }
}
