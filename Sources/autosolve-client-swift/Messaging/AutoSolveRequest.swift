//
//  AutoSolveMessage.swift
//  swift-test
//
//  Created by Scott Kapelewski on 22.05.20.
//  Copyright © 2020 Scott Kapelewski. All rights reserved.
//

import Foundation

protocol AutoSolveRequest : Codable{
    var taskId: String {get set}
    var apiKey: String {get set}
    var createdAt: Int {get set}
    
    func type() -> String
}
