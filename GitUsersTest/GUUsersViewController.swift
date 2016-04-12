//
//  GUUsersViewController.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/29/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import UIKit
import SafariServices

class GUUsersViewController: UITableViewController {

    private var userList: [GUUser] = []
    private var getUsersOperation: GUOperation?
    private var canLoadMore: Bool = true
    private var isLoading: Bool = false
    private var currentPage = GUUsersPage.fistPage(0, per_page: 50)
    
    private var getAvatarOperation : GUOperation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.requestNextPage()
    }

    func requestNextPage() {
        guard !self.isLoading else {
            return
        }
        self.isLoading = true
        
        self.getUsersOperation = GUUser.fetchUsers(self.currentPage, completion: {
            [weak self] (users, nextPage, error) in
            guard let strongSelf = self else { return }
            
            guard error == nil, let newUsers = users  else {
                strongSelf.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: strongSelf.userList.count, inSection: 0)], withRowAnimation: .Bottom)
                return
            }
            
            // append indexes
            let firstAppendIndex = strongSelf.userList.count
            let numOfAppendIndexes = newUsers.count
            var appendIndexes : [NSIndexPath] = []
            for i in 0 ..< numOfAppendIndexes {
                strongSelf.userList.append(newUsers[i])
                appendIndexes.append(NSIndexPath(forRow: i + firstAppendIndex, inSection: 0))
            }
            strongSelf.tableView.insertRowsAtIndexPaths(appendIndexes, withRowAnimation: .Automatic)
            
            // check if it's last page
            if newUsers.count == 0 {
                strongSelf.canLoadMore = false
            }
            
            strongSelf.currentPage = nextPage!
            strongSelf.isLoading = false
        })
    }
    
}

// MARK: UITableViewDataSource

extension GUUsersViewController {
    
    internal override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    internal override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (userList.count + 1)
    }
    
    internal override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        if userList.count == indexPath.row {
            cell = tableView.dequeueReusableCellWithIdentifier(GULoadingCell.identifier, forIndexPath: indexPath)
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(GUUserCell.identifier, forIndexPath: indexPath)
            if let userCell = cell as? GUUserCell {
                userCell.cellDelegate = self
                userCell.update(userList[indexPath.row])
            }
        }
        
        return cell!
    }
}

// MARK: UITableViewDelegate

extension GUUsersViewController {
    
    internal override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        guard !self.isLoading && self.canLoadMore else { return }
        
        // Check scrolled percentage
        let yOffset = self.tableView.contentOffset.y
        let height = self.tableView.contentSize.height - self.tableView.bounds.height
        let scrolledPercentage = yOffset / height
        
        // Check if all the conditions are met to allow loading the next page
        if scrolledPercentage > 0.6 {
            self.requestNextPage()
        }
    }
    
    internal override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard indexPath.row < self.userList.count else {
            return
        }
        
        let user = self.userList[indexPath.row]
        if let link = user.profileLink, let url = NSURL(string: link) {
            if #available(iOS 9.0, *) {
                let svc = SFSafariViewController(URL: url, entersReaderIfAvailable: true)
                self.navigationController?.pushViewController(svc, animated: true)
            } else {
                if UIApplication.sharedApplication().canOpenURL(url) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
        }
    }
}

// MARK: GUUserCellDelegate

extension GUUsersViewController : GUUserCellDelegate {
    
    func didTapAvatar(cell: GUUserCell!) {

        guard let indexPath = self.tableView.indexPathForCell(cell) where indexPath.row < self.userList.count else {
            return
        }

        let user = self.userList[indexPath.row]
        
        if let avatar = user.avatar, url = NSURL(string: avatar), parentView = self.view.superview {
            let imageFrame = cell.avatarImageView.convertRect(cell.avatarImageView.bounds, toView: parentView)
            self.previewAvatar(url, parentView: parentView, frame: imageFrame)
        }
    }
  
    func previewRecognizerAction(recognizer : UITapGestureRecognizer) {

        guard let dimView = recognizer.view, imageView = dimView.subviews.first else {
            return
        }

        self.getAvatarOperation?.cancel()

        dimView.removeGestureRecognizer(recognizer)
        UIView.animateWithDuration(0.25, animations: {
            imageView.alpha = 0.0
            dimView.alpha = 0.0
        }) { _ in
            dimView.removeFromSuperview()
        }
    }

    func previewAvatar(url: NSURL!, parentView: UIView!, frame: CGRect) {
        
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        let dimView = UIView(frame: frame)
        dimView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.9)
        
        let imageView = UIImageView(frame: dimView.bounds)
        imageView.userInteractionEnabled = true
        dimView.addSubview(imageView)
        
        self.view.superview?.addSubview(dimView)
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            dimView.frame = parentView.bounds
            imageView.frame.size = CGSize(width: parentView.bounds.width, height: parentView.bounds.width)
            imageView.center = dimView.center

        }, completion: { (result) in
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(GUUsersViewController.previewRecognizerAction(_:)))
            dimView.addGestureRecognizer(recognizer)
            
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
        })
        
        self.getAvatarOperation?.cancel()
        self.getAvatarOperation = GUGetImageOperation(url: url, completion: {
            [weak imageView] (img, error) -> Void in
            if error == nil {
                imageView?.image = img
            }
        })
    }
}