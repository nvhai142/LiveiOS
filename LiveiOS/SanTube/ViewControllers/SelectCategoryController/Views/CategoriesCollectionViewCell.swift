//
//  CategoriesCollectionViewCell.swift
//  SanTube
//
//  Created by Dai Pham on 11/16/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class CategoriesCollectionViewCell: UICollectionViewCell {

    // MARK: - oulet
    @IBOutlet weak var imvAvatar: UIImageViewRound!
    @IBOutlet weak var lblName: UILabel!
    
    // MARK: - properties
    var object:Category?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configView()
    }

    // MARK: - interface
    func load(cate:Category, check:Bool) {
        self.object = cate
        lblName.text = cate.name
        imvAvatar.loadImageUsingCacheWithURLString(cate.img, size: imvAvatar.frame.size, placeHolder: nil)
        if check {
            imvAvatar.addMask(color: UIColor.black,0.6)
        } else {
            imvAvatar.removeMask()
        }
    }
    
    // MARK: - private
    func configView() {
        lblName.font = UIFont.boldSystemFont(ofSize: fontSize16)
        lblName.textColor = UIColor.white
        imvAvatar.layer.cornerRadius = 5.0
    }
    
    // MARK: - prepare reuse
    override func prepareForReuse() {
        imvAvatar.removeMask()
        object = nil
        imvAvatar.image = nil
    }
}
