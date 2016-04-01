//
//  NSError+GitUsers.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/29/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import Foundation

public let kGitUsersErrorDomain = "GitUsersErrorDomain"

public enum GitUsersErrorCode: Int {
    case kUnknownError = 1
    case kNoInternetConnectionError
    case kParametersError
}

let kNoNetworkReason = "Internet connection required."

extension NSError {

    convenience init(code: GitUsersErrorCode, reason: String?) {
        var info : [NSObject : AnyObject]? = nil
        if reason != nil {
            info = [NSLocalizedFailureReasonErrorKey : reason!]
        }
        self.init(domain: kGitUsersErrorDomain, code: code.rawValue, userInfo: info)
    }

    convenience init(code: GitUsersErrorCode, userInfo dict: [NSObject : AnyObject]?) {
        self.init(domain: kGitUsersErrorDomain, code: code.rawValue, userInfo: dict)
    }
    
}

extension NSError {
    
    class func unknownError(reason :String?) -> NSError {
        return NSError(code: .kUnknownError, reason: reason)
    }
    
    class func noNetworkError() -> NSError {
        return NSError(code: .kNoInternetConnectionError, reason: kNoNetworkReason)
    }
    
    class func parametersError(reason: String?) -> NSError {
        return NSError(code: .kParametersError, reason: reason)
    }
    
}