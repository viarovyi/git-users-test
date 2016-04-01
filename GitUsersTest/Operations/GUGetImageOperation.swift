//
//  GUGetImageOperation.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/29/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import Foundation
import UIKit

class GUGetImageOperation : GUNetworkOperation {

    typealias completionType = (img: UIImage?, error: NSError?) -> Void

    let url: NSURL!
    let imageCache = GUImageCache.sharedInstance
    
    init(url anUrl: NSURL!, completion: completionType?) {
        url = anUrl
        super.init { (result, error) -> Void in
            assert(NSThread.isMainThread())
            completion?(img: result as! UIImage?,  error: error)
        }
    }
    
    override func makeRequest() -> NSURLSessionTask! {
        
        let block: GUNetworkCompletion = { [weak self] (result, error) -> Void in
            guard let strongSelf = self where !strongSelf.canceled else {
                return
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let strongSelf = self where !strongSelf.canceled {
                    strongSelf.completion?(result: result, error: error)
                }
            })
        }
        
        guard let path = url.path else {
            block(result: nil, error: NSError.parametersError(nil))
            return nil
        }
        
        var sessionTask: NSURLSessionTask?
        
        // try to get image from cache
        imageCache.getImage(path, completion: { [weak self] (result) -> Void in
            
            guard result == nil else {
                block(result: result, error: nil)
                return
            }
            
            guard let strongSelf = self where !strongSelf.canceled else {
                return
            }
            
            // no image in cache - create network request
            GUActivityIndicatorManager.sharedManager.start()
            sessionTask = NSURLSession.sharedSession().downloadTaskWithURL(strongSelf.url, completionHandler: { [weak self] (fileUrl, response, err) -> Void in
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    GUActivityIndicatorManager.sharedManager.stop()
                })

                guard err == nil else {
                    block(result: nil, error: err)
                    return
                }
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
                        block(result: nil, error: NSError(domain: kNetworkErrorDomain, code: httpResponse.statusCode, userInfo: nil) )
                        return
                    }
                }

                guard let strongSelf = self where !strongSelf.canceled else {
                    return
                }
                
                let respData = [strongSelf.url!, fileUrl!]
                strongSelf.handleResponse(respData, response: response, completion: block)
            })
            
            if !strongSelf.canceled {
                strongSelf.sessionTask = sessionTask
                strongSelf.sessionTask?.resume()
            }
        })
        
        return sessionTask
    }
    
    override func handleResponse(data: AnyObject?, response: NSURLResponse!, completion: GUNetworkCompletion) {
        
        let respData = data as! [NSURL]
        
        // move downloaded file to cache folder
        let cachePath = self.imageCache.localImagePath(respData[0].path!, createPathIfNeeded: true)
        do {
            try NSFileManager.defaultManager().moveItemAtPath(respData[1].path!, toPath: cachePath)
        } catch  {
            #if DEBUG
            print("failed to move local file from: \(respData[1].path!) to: \(cachePath)")
            #endif
        }

        // get image from cache
        self.imageCache.getImage(url.path!) { (img) -> Void in
            guard img != nil else {
                completion(result: nil, error: NSError.unknownError(""))
                return
            }
            completion(result: img, error: nil)
        }
    }
}
