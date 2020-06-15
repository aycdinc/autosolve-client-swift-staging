//
//  AutoSolveResponse.swift
//  swift-test
//
//  Created by Scott Kapelewski on 22.05.20.
//  Copyright © 2020 Scott Kapelewski. All rights reserved.
//

import Foundation

protocol AutoSolveResponse : Decodable {
    func type() -> String
}
