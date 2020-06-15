//
//  AutoSolveCancelResponse.swift
//  swift-test
//
//  Created by Scott Kapelewski on 22.05.20.
//  Copyright © 2020 Scott Kapelewski. All rights reserved.
//

import Foundation

public class AutoSolveCancelResponse : AutoSolveResponse {
    let requests: [AutoSolveTokenRequest]
    
    init(requests: [AutoSolveTokenRequest]) {
        self.requests = requests
    }
    
    func type() -> String {
        return AutoSolveConstants.CancelResponse
    }
}
