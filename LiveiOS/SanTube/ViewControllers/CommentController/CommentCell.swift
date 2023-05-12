//
//  CommentCell.swift
//  SanTube
//
//  Created by Dai Pham on 12/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {

    // MARK: - outlet
    @IBOutlet weak var imvUserAvatar: UIImageView!
    @IBOutlet weak var lblComment: UILabel!
    
    // MARK: - properties
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    // MARK: - interface
    func load(data:JSON) {
        
        let listComment = ["What are the man and woman mainly discussing?",
                           "How is the woman traveling?",
                           "Why aren't the man and woman going together?",
                           "What does the man have to do today?",
                           "What can be inferred from the conversation?",
                           "What does the woman offer to do for the man?",
                           "I have a doctor's appointment this afternoon. Are you going to be in the office, or do you have a meeting?",
                           "I'll be here. And, don't worry. I don't have much on for today, so I'll handle all of your calls",
                           "Thanks. I'm expecting a call from my lawyer. He's supposed to be sending me some changes to the contracts.",
                           "I'll make sure to take a detailed message if he calls. Is there anything you want to tell him?",
                           "Well, you could remind him that I'm going to need to come downtown and sign a few papers in front of him. I'll have to set something up for next week."]
        
        let name = NSMutableAttributedString(string:"\("Peter Nguyen")", attributes: [NSFontAttributeName:UIFont.boldSystemFont(ofSize: fontSize16),NSForegroundColorAttributeName:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)])
        let time = NSMutableAttributedString(string:"\(" (1 hour ago)")", attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: fontSize14),NSForegroundColorAttributeName:#colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)])
        let twoDot = NSMutableAttributedString(string:": ", attributes: [NSFontAttributeName:UIFont.boldSystemFont(ofSize: fontSize16),NSForegroundColorAttributeName:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)])
        let comment = NSMutableAttributedString(string: listComment.choose(1).first!,
            attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: fontSize16),
                         NSForegroundColorAttributeName:#colorLiteral(red: 0.3019607843, green: 0.3019607843, blue: 0.3019607843, alpha: 1)])
        
        let final = NSMutableAttributedString(attributedString: name)
        final.append(time)
        final.append(twoDot)
        final.append(comment)
        lblComment.attributedText = final
        imvUserAvatar.image = UIImage(named: APP_LOGO_PLACEHOLDER)
    }
    
    // MARK: - prepare reuse
    override func prepareForReuse() {
        imvUserAvatar.image = nil
    }
}
