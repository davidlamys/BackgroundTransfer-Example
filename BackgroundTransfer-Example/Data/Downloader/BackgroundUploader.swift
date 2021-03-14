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
    
    var queue = [Job]()
    var dict = [Int: Job]()
    
    private override init() {
        super.init()
        
        let configuration = URLSessionConfiguration.background(withIdentifier: "background.upload.session")
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func queueUpload(asset: GalleryAsset, completionHandler: @escaping ForegroundDownloadCompletionHandler) {
        let job = Job(asset: asset, didComplete: completionHandler)
        queue.append(job)
        if queue.first(where: { $0.isCompleted == false }) == job {
            upload(job: job, completionHandler: completionHandler)
        }
    }
    
    func uploadNext() {
        if let job = queue.first(where: { $0.isCompleted == false }) {
            upload(job: job, completionHandler: job.didComplete)
        }
    }
    
    func upload(job: Job, completionHandler: @escaping ForegroundDownloadCompletionHandler) {
        if let asset = context.uploadItem(uploadItem: job.asset){
            print("Already uploading: \(asset.filePathURL)")
            asset.foregroundCompletionHandler = completionHandler
        } else {
            let asset = job.asset
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
            print("task id: \(task.taskIdentifier)")
            dict[task.taskIdentifier] = job
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
        if let httpUrlResponse = task.response as? HTTPURLResponse
               {
            
            if #available(iOS 13.0, *) {
                if let error = error {
                    print(httpUrlResponse)
                    print("Error Occurred: \(error.localizedDescription)")
                } else if let rateleft = httpUrlResponse.value(forHTTPHeaderField: "x-post-rate-limit-remaining") {
                    print(rateleft)
                }
            }
        }
        if let job = dict[task.taskIdentifier] {
//            job.didComplete(DataRequestResult<URL>)
            job.isCompleted = true
            uploadNext()
        }
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
//                    uploadNext()
                }
            } catch {
                // Display an error
            }
        }
    }
}

class Job: NSObject {
    let asset: GalleryAsset
    var isCompleted: Bool = false
    let didComplete: ForegroundDownloadCompletionHandler
    
    internal init(asset: GalleryAsset, didComplete: @escaping ForegroundDownloadCompletionHandler) {
        self.asset = asset
        self.didComplete = didComplete
    }
}
