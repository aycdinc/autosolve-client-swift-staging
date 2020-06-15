//
//  AutoSolveTokenResponse.swift
//  swift-test
//
//  Created by Scott Kapelewski on 22.05.20.
//  Copyright © 2020 Scott Kapelewski. All rights reserved.
//

import Foundation

public class AutoSolveTokenResponse : AutoSolveResponse {
    let request: AutoSolveTokenRequest
    let createdAt: Int
    let token: String
    let taskId: String
    
    init(request: AutoSolveTokenRequest, createdAt: Int, token: String, taskId: String) {
        self.request = request
        self.createdAt = createdAt
        self.token = token
        self.taskId = taskId
    }
    
    func type() -> String {
        return AutoSolveConstants.CancelResponse
    }
}
