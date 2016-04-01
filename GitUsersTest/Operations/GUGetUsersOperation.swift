//
//  GUGetUsersOperation.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/29/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import Foundation

// MARK - GUUsersPage

class GUUsersPage: NSObject {

    var URL: NSURL!
    
    init(url: NSURL!) {
        URL = url
    }

    class func fistPage(since: UInt, per_page: UInt) -> GUUsersPage! {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "api.github.com"
        urlComponents.path = "/users"
        
        var queryItems: [NSURLQueryItem]?
        if since > 0 || per_page > 0 {
            queryItems = [NSURLQueryItem]()
            if since > 0 { queryItems!.append(NSURLQueryItem(name: "since", value: "\(since)")) }
            if per_page > 0 {  queryItems!.append(NSURLQueryItem(name: "per_page", value: "\(per_page)")) }
        }
        urlComponents.queryItems = queryItems
        
        return GUUsersPage(url: urlComponents.URL!)
    }
}

typealias GUGetUsersCompletion = (users: [GUUser]?, nextPage: GUUsersPage?, error: NSError?) -> Void

// MARK - GUGetUsersOperation

class GUGetUsersOperation : GUApiOperation {
    
    private var getUsersCompletion: GUGetUsersCompletion?
    private var pageUrl: NSURLComponents!
    private var nextPage: GUUsersPage?
    
    init(page aPage: GUUsersPage!, usersCompletion: GUGetUsersCompletion?) {
        getUsersCompletion = usersCompletion
        pageUrl = NSURLComponents(URL: aPage.URL, resolvingAgainstBaseURL: false)
        
        super.init { (result, error) -> Void in
            assert(NSThread.isMainThread())
            
            guard error == nil else {
                usersCompletion?(users: nil, nextPage: nil, error: error)
                return
            }
            
            let result = result as! [AnyObject]
            
            var wrapped = [GUUser]()
            let users = result[0] as! [[String : AnyObject]]
            for item in users {
                wrapped.append(GUUser(dict: item))
            }
            usersCompletion?(users: wrapped, nextPage: result[1] as? GUUsersPage, error: nil)
        }
    }
    
    override func scheme() -> String? { return pageUrl.scheme }
    
    override func host() -> String? { return pageUrl.host }
    
    override func path() -> String? { return pageUrl.path }
    
    override func queryItems() -> [NSURLQueryItem]? { return pageUrl.queryItems }
    
    override func handleResponse(data: AnyObject?, response: NSURLResponse!, completion: GUNetworkCompletion) {
        
        // extract next page from Link header
        if let httpResponse = response as? NSHTTPURLResponse, pageLink = httpResponse.allHeaderFields["Link"] {
            
            var nextLink: String?
            let links = pageLink.componentsSeparatedByString(",")
            for link in links {
                let pair = link.componentsSeparatedByString(";")
                guard pair.count == 2 else { continue }
                
                for i in 0 ... 1 {
                    let key = pair[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                    if key == "rel=\"next\"" {
                        nextLink = pair[(i + 1) % 2].stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))
                        break
                    }
                }
                if nextLink != nil { break }
            }
            
            if nextLink != nil {
                self.nextPage = GUUsersPage(url: NSURL(string: nextLink!))
            }
        }
        
        super.handleResponse(data, response: response, completion: completion)
    }
    
    override func parseResponseData(json: AnyObject?) -> (error: NSError?, result: AnyObject?) {
        let valid = super.parseResponseData(json)
        guard valid.error == nil else { return valid }
        
        if let users = valid.result as? [[String : AnyObject]] {
            return (nil, [users, self.nextPage!])
        }
        return (NSError.unknownError("Invalid response format"), nil)
    }
    
}