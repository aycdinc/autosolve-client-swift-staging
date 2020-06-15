//
//  Validation.swift
//  swift-test
//
//  Created by Scott Kapelewski on 22.05.20.
//  Copyright © 2020 Scott Kapelewski. All rights reserved.
//

import Foundation


class Validator {
    internal static func validateCredentials(accessToken: String, apiKey: String, clientKey: String, completionHandler: @escaping  (Int?, AutoSolveError?) -> ()) {
        let url = URL(string: "https://dash.autosolve.aycd.io/rest/\(accessToken)/verify/\(apiKey)?clientId=\(clientKey)")
        var statusCode: Int?
        var autoSolveError: AutoSolveError?
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            defer {
                completionHandler(statusCode, autoSolveError)
            }

            if let error = error {
                print("Error took place in AutoSolve validation \(error)")
                statusCode = 0
                autoSolveError = AutoSolveError.InitConnectionError
                return
            } else if let response = response as? HTTPURLResponse {
                statusCode = response.statusCode
                switch statusCode {
                case AutoSolveConstants.InvalidClientKeyStatusCode:
                    autoSolveError = AutoSolveError.InvalidClientKey
                case AutoSolveConstants.InvalidCredentialsStatusCode:
                    autoSolveError = AutoSolveError.InvalidApiKeyOrToken
                case AutoSolveConstants.TooManyRequests:
                    autoSolveError = AutoSolveError.TooManyRequests
                default:
                    autoSolveError = nil
                }
            } else {
                statusCode = 0
                autoSolveError = AutoSolveError.InitConnectionError
                return
            }
        }
        task.resume()
    }
}
