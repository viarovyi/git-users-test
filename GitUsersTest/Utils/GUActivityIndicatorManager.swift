//
//  GUActivityIndicatorManager.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/29/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import Foundation
import UIKit

class GUActivityIndicatorManager {

    private var tasks: Int = 0

    static let sharedManager = GUActivityIndicatorManager()
    
    func start() {
        let application = UIApplication.sharedApplication()
        if !application.networkActivityIndicatorVisible {
            application.networkActivityIndicatorVisible = true
            self.tasks = 0
        }
        self.tasks += 1
    }
    
    func stop() {
        let application = UIApplication.sharedApplication()
        if application.statusBarHidden {
            return
        }
        
        self.tasks -= 1
        
        if self.tasks <= 0 {
            application.networkActivityIndicatorVisible = false
            self.tasks = 0
        }
    }
    
}
