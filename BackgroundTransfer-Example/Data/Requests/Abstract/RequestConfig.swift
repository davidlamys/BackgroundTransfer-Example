//
//  RequestConfig.swift
//  BackgroundTransfer-Example
//
//  Created by William Boles on 28/04/2018.
//  Copyright © 2018 William Boles. All rights reserved.
//

import Foundation

enum HTTPRequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

class RequestConfig {
    
    let clientID: String
    let APIHost: String
    
    // MARK: - Init
    
    init() {
        var clientID = ""
        if let testClientID = ProcessInfo.processInfo.environment["TEST_CLIENT_ID"] as String? {
            clientID = testClientID
        }
        
        assert(!clientID.isEmpty, "You need to provide a clientID hash, you get this from [insert imgur url]")
        
        self.clientID = clientID
        self.APIHost = "https://api.imgur.com/3"
    }
}
