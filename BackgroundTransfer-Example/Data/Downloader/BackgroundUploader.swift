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
    
    
    func upload(asset: GalleryAsset, completionHandler: @escaping ForegroundDownloadCompletionHandler) {
        if let asset = context.uploadItem(uploadItem: asset){
            print("Already uploading: \(asset.filePathURL)")
            asset.foregroundCompletionHandler = completionHandler
        } else {
            print("Scheduling to upload: \(asset.id)")
            
            let uploadItem = UploadItem(filePathURL: asset.cachedLocalAssetURL())
            context.saveUploadItem(uploadItem, asset: asset)
            uploadItem.foregroundCompletionHandler = completionHandler
            let boundary = "Boundary-\(UUID().uuidString)"
            
            var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image")!)
            request.addValue("Client-ID 9dd6db9436ff5d4", forHTTPHeaderField: "Authorization")
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            let url = asset.cachedLocalAssetURL()
            let imageData = try? Data(contentsOf: url).base64EncodedString()
            
            var body = ""
            body += "--\(boundary)\r\n"
            body += "Content-Disposition:form-data; name=\"image\""
            body += "\r\n\r\n\(imageData ?? "")\r\n"
            body += "--\(boundary)--\r\n"
            let postData = body.data(using: .utf8)
            
            let tempDir = FileManager.default.temporaryDirectory
            let localURL = tempDir.appendingPathComponent("throwaway")
            try? postData?.write(to: localURL)
            
            let task = session.uploadTask(with: request, fromFile: localURL)
            task.resume()
        }
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

extension BackgroundUploader: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print(task.response)
    }
    
}

extension BackgroundUploader: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let dataString = String(data: data, encoding: .utf8) {
            print("imgur upload results: \(dataString)")
            let parsedResult: [String: AnyObject]
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                if let dataJson = parsedResult["data"] as? [String: Any] {
                    print("Link is : \(dataJson["link"] as? String ?? "Link not found")")
                    
                }
            } catch {
                // Display an error
            }
        }
    }
}
