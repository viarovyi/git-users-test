//
//  GUNetworkOperation.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/29/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import Foundation

public let kNetworkErrorDomain = "GUNetworkErrorDomain"

typealias GUNetworkCompletion = (result: AnyObject?, error: NSError?) -> Void

class GUNetworkOperation : GUOperation {
    
    var sessionTask : NSURLSessionTask?
    var completion: GUNetworkCompletion?
    
    init(completion aCompletion: GUNetworkCompletion?) {
        completion = aCompletion
        super.init()
        
        let sessionTask = self.makeRequest()
        
        if !self.canceled {
            self.sessionTask = sessionTask
            self.sessionTask?.resume()
        }
    }
 
    deinit {
        self.cancel_task_impl()
    }

    override func cancel() {
        self.cancel_task_impl()
        super.cancel()
    }
    
    func cancel_task_impl() {
        if !self.canceled && self.sessionTask != nil {
            self.sessionTask?.cancel()
        }
    }
    
    func makeRequest() -> NSURLSessionTask! {
        
        let urlComponents = NSURLComponents()
        urlComponents.scheme = self.scheme()
        urlComponents.host = self.host()
        urlComponents.path = self.path()
        urlComponents.queryItems = self.queryItems()
        urlComponents.port = self.port()
        
        let req = NSMutableURLRequest(URL: urlComponents.URL!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 30)
        req.HTTPMethod = self.method()
        req.HTTPBody = self.body()
        if let headers = self.headers() {
            for header in headers {
                req.addValue(header.1, forHTTPHeaderField: header.0)
            }
        }
        
        GUActivityIndicatorManager.sharedManager.start()
        let sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(req, completionHandler: { [weak self] (data, response, err) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                GUActivityIndicatorManager.sharedManager.stop()
            })
            
            let block: GUNetworkCompletion = { [weak self] (result, error) -> Void in
                guard let strongSelf = self where !strongSelf.canceled else {
                    return
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let strongSelf = self where !strongSelf.canceled {
                        strongSelf.completion!(result: result, error: error)
                    }
                })
            }
            
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
            
            strongSelf.handleResponse(data, response: response, completion: block)
        })
        
        return sessionTask
    }

    func handleResponse(data: AnyObject?, response: NSURLResponse!, completion: GUNetworkCompletion) {
        completion(result: data, error: nil)
    }

    func scheme() -> String? {
        return nil
    }
    func host() -> String? {
        return nil
    }
    func path() -> String? {
        return nil
    }
    func method() -> String {
        return "GET"
    }
    func queryItems() -> [NSURLQueryItem]? {
        return nil
    }
    func headers() -> [String : String]? {
        return nil
    }
    func body() -> NSData? {
        return nil
    }
    func port() -> NSNumber? {
        return nil
    }
}
