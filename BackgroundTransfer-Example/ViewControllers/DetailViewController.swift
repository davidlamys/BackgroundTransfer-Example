//
//  DetailViewController.swift
//  BackgroundTransfer-Example
//
//  Created by david lam on 21/2/21.
//  Copyright © 2021 William Boles. All rights reserved.
//

import Foundation
import UIKit

class DetailViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func didTapUpload(_ sender: Any) {
        guard let asset = asset else {
            print("wtf david")
            return
        }
        BackgroundUploader.shared.upload(asset: asset) { result in
            print(result)
        }
    }
    
    var asset: GalleryAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let asset = asset {
            let url = asset.cachedLocalAssetURL()
            if let data = try? Data(contentsOf: url) {
                imageView.image = UIImage(data: data)
            }
        }
    }
}
