//
//  Encoding.swift
//  swift-test
//
//  Created by Scott Kapelewski on 22.05.20.
//  Copyright © 2020 Scott Kapelewski. All rights reserved.
//

import Foundation

class Encoding {
    internal static func encode(message: AutoSolveRequest) -> String{
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        do {
            let jsonData = message.type() == AutoSolveConstants.TokenRequest ?
                try jsonEncoder.encode(message as! AutoSolveTokenRequest) :
                try jsonEncoder.encode(message as! AutoSolveCancelRequest)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            if(json != nil) {
                return json!
            } else {}
            
        } catch {
            print("Error encoding message")
        }
        
        return ""
    }
    
    internal static func decode(message: String, classType: String) -> AutoSolveResponse?{
        let data = Data(message.utf8)
        let jsonDecoder = JSONDecoder()
      
        do {
            if(classType == AutoSolveConstants.TokenResponse) {
                return try jsonDecoder.decode(AutoSolveTokenResponse.self, from: data)
            } else {
                return try jsonDecoder.decode(AutoSolveCancelResponse.self, from: data)
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
        
        return nil
    }
}
