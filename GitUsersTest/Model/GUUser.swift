//
//  GUUser.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/29/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import Foundation

class GUUser : NSObject {
    
    var userDict: Dictionary<String, AnyObject>!
    
    init(dict: Dictionary<String, AnyObject>!) {
        userDict = dict
        super.init()
    }

    var userId: Int? { return userDict["id"] as? Int }
    var loginName: String? { return userDict["login"] as? String }
    var avatar: String? { return userDict["avatar_url"] as? String }
    var profileLink: String? { return userDict["html_url"] as? String }
 
    class func fetchUsers(page: GUUsersPage!, completion: GUGetUsersCompletion?) -> GUOperation {
        return GUGetUsersOperation(page: page, usersCompletion: completion)
    }

}