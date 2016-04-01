//
//  GUApiOperation.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/29/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import Foundation

class GUApiOperation : GUNetworkOperation {
    
    override init(completion: GUNetworkCompletion?) {
        super.init(completion: completion)
    }
    
    override func scheme() -> String? { return "https" }
    
    override func host() -> String? { return "api.github.com" }
    
    override func headers() -> [String : String]? {
        return ["Content-Type" : "application/json", "Accept" : "application/json"]
    }

    override func body() -> NSData? {
        if let params = self.bodyParams() {
            var body: NSData?
            do { body = try NSJSONSerialization.dataWithJSONObject(params, options: []) } catch {}
            return body
        }
        return nil
    }
    
    func bodyParams() -> Dictionary<String, AnyObject>? { return nil }
    
    override func handleResponse(data: AnyObject?, response: NSURLResponse!, completion: GUNetworkCompletion) {
        
        var jsonObj: AnyObject?
        do {
            try jsonObj = NSJSONSerialization.JSONObjectWithData(data as! NSData, options: .MutableLeaves) as? [AnyObject]
        }
        catch let error as NSError {
            print("failed: \(error.localizedDescription)")
        }
        
        let valid = self.parseResponseData(jsonObj)
        completion(result: valid.result, error: valid.error)
    }

    func parseResponseData(json: AnyObject?) -> (error: NSError?, result: AnyObject?) {
        
        guard json != nil else {
            return (NSError.unknownError("Invalid response"), nil)
        }
        
        return (nil, json)
    }
    
}
