//
//  GUImageCache.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/29/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import Foundation
import UIKit

class GUImageCache {

    private let memoryCache = NSCache()
    private let fileManager = NSFileManager()
    private let queue = dispatch_queue_create("GUImageCache", DISPATCH_QUEUE_SERIAL)
    
    static let sharedInstance = GUImageCache()

    func getImage(key: String, completion: (img: UIImage?) -> Void) {
        
        dispatch_async(self.queue) { [weak self] () -> Void in
            guard let strongSelf = self else {
                return
            }

            var cachedImg: AnyObject? = strongSelf.memoryCache.objectForKey(key)
            if (cachedImg == nil)
            {
                let localPath = strongSelf.localImagePath(key, createPathIfNeeded: false)
                if strongSelf.fileManager.fileExistsAtPath(localPath) {
                    cachedImg = UIImage(contentsOfFile: localPath)
                    if cachedImg != nil {
                        strongSelf.memoryCache.setObject(cachedImg!, forKey: key)
                    }
                }
            }
            
            completion(img: cachedImg as? UIImage)
        }
    }
    
    func setImage(key: String, image: UIImage, completion: (() -> Void)?) {

        dispatch_async(self.queue) { [weak self] () -> Void in
            
            guard let strongSelf = self else {
                return
            }

            strongSelf.memoryCache.setObject(image, forKey: key)
            
            let localPath = strongSelf.localImagePath(key, createPathIfNeeded: true)
            if strongSelf.fileManager.fileExistsAtPath(localPath) {
                do {
                    try strongSelf.fileManager.removeItemAtPath(localPath)
                } catch  {
                    print("failed to remove local file: %@", localPath)
                }
            }
            
            if let imageData = UIImagePNGRepresentation(image) {
                if !imageData.writeToFile(localPath, atomically: true) {
                    print("failed to write local file: %@", localPath)
                }
            }
            
            if completion != nil {
                completion!()
            }
        }
    }
    
    internal func cacheDirectory(createIfNeeded: Bool) -> String {
        let cachesPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        let path = "\(cachesPath)/GitUsersTest/images"

        if createIfNeeded {
            if !self.fileManager.fileExistsAtPath(path) {
                do {
                    try self.fileManager.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
                } catch  {
                    #if DEBUG
                    print("failed to crete cache directory: %@", path)
                    #endif
                }
            }
        }
        return path
    }
    
    internal func localImagePath(key: String, createPathIfNeeded: Bool) -> String {
        let utf8Key = (key as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        let base64Key = utf8Key?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        let cacheDir = self.cacheDirectory(createPathIfNeeded)
        let path = "\(cacheDir)/\(base64Key!)"
        return path
    }
    
}
