//
//  AutoSolveTokenRequest.swift
//  swift-test
//
//  Created by Scott Kapelewski on 22.05.20.
//  Copyright © 2020 Scott Kapelewski. All rights reserved.
//

import Foundation

public class AutoSolveTokenRequest : AutoSolveRequest{
    var taskId: String
    var apiKey: String
    var createdAt: Int
    let url: String
    let siteKey: String
    let renderParameters: [String : String]
    let version: Int
    let action: String
    let minScore: Double
    let proxy: String
    let proxyRequired: Bool
    let userAgent: String
    let cookies: String
    
    public init(taskId: String, url: String, siteKey: String, renderParameters: [String : String] = [:], version: Int = 0,
         action: String = "", minScore: Double = 0.3, proxy: String = "", proxyRequired: Bool = false, userAgent: String = "", cookies: String = "") {
        self.taskId = taskId
        self.apiKey = ""
        self.createdAt = Int(Date().timeIntervalSince1970.rounded())
        self.url = url
        self.siteKey = siteKey;
        self.renderParameters = renderParameters
        self.version = version
        self.action = action
        self.minScore = minScore
        self.proxy = proxy
        self.proxyRequired = proxyRequired
        self.userAgent = userAgent
        self.cookies = cookies
    }
    
    func type() -> String {
        return AutoSolveConstants.TokenRequest
    }
}
