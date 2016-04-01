//
//  GUUserCell.swift
//  GitUsersTest
//
//  Created by Viktor Iarovyi on 3/30/16.
//  Copyright © 2016 Viktor Iarovyi. All rights reserved.
//

import UIKit

protocol GUUserCellDelegate : NSObjectProtocol{
    func didTapAvatar(cell: GUUserCell!)
}

class GUUserCell : UITableViewCell {
    
    static let identifier = "GUUserCell"

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var loginLabel: UILabel!
    
    weak var cellDelegate: GUUserCellDelegate?
    
    private var getAvatarOperation : GUOperation?
    private var tapImageRecognizer: UITapGestureRecognizer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.tapImageRecognizer = UITapGestureRecognizer(target: self, action: #selector(GUUserCell.tapAvatar(_:)))
        self.avatarImageView.addGestureRecognizer(self.tapImageRecognizer!)
    }
    
    func update(user: GUUser!) {
        
        self.loginLabel.text = user.loginName()
        
        // update user picture
        self.avatarImageView.image = UIImage(named: "Profile")
        if let image = user.avatar(), let url = NSURL(string: image) {
            self.getAvatarOperation = GUGetImageOperation(url: url, completion: {
                [weak self] (img, error) -> Void in
                guard let strongSelf = self where error == nil else { return }
                
                if error == nil {
                    strongSelf.avatarImageView.alpha = 0.1
                    strongSelf.avatarImageView.image = img
                    UIView.animateWithDuration(0.4, animations: { () -> Void in
                        strongSelf.avatarImageView.alpha = 1.0
                    }, completion: { (Bool) -> Void in
                        strongSelf.avatarImageView.alpha = 1.0
                    })
                }
                
                strongSelf.avatarImageView.image = img
            })
        }
    }

    internal func tapAvatar(recognizer: UIPanGestureRecognizer!) {
        self.cellDelegate?.didTapAvatar(self)
    }

}