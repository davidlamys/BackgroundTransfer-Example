//
//  BackgroundUploader.swift
//  BackgroundTransfer-Example
//
//  Created by david lam on 21/2/21.
//  Copyright © 2021 William Boles. All rights reserved.
//

import Foundation
import UIKit

class BackgroundUploader: NSObject {
    
    var backgroundCompletionHandler: (() -> Void)?
    private let fileManager = FileManager.default
    private let context = BackgroundUploaderContext()
    private var session: URLSession!
    
    // MARK: - Singleton

    static let shared = BackgroundUploader()
    
    // MARK: - Init
    
    private override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "background.upload.session")
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
}

// MARK: - URLSessionDelegate

extension BackgroundUploader: URLSessionDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}

extension BackgroundUploader: URLSessionDataDelegate {
    
}
