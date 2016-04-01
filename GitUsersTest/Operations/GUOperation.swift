//
//  GUOperation.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/29/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import Foundation

class GUOperation : NSObject {
    
    var canceled = false
    var subOperations: [GUOperation]?
   
    deinit {
        self.cancel_impl()
    }

    func addSubOperation(operation: GUOperation) {
        if self.subOperations == nil {
            self.subOperations = []
        }
        self.subOperations?.append(operation)
        if self.canceled {
            operation.cancel()
        }
    }
    
    func cancel() {
        self.cancel_impl()
    }

    internal func cancel_impl() {
        if !self.canceled {
            self.canceled = true;
            if self.subOperations != nil {
                for operation in self.subOperations! {
                    operation.cancel()
                }
            }
        }
    }
}