//
//  CategoriesListView.swift
//  BUUP
//
//  Created by Dai Pham on 11/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class CategoryView: UIView {

    // MARK: - outlet
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var lblCateName: UILabel!
    
    // MARK: - properties
    var category:Category?
    var isSelected:Bool = false
    var oldImage:UIImage?
    
    // MARK: - closure
    var onSelectCategory:((Category,Int)->Void)?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configView()
    }
    
    // MARK: - interface
    func load(_ cate:Category) {

        self.category = cate
        
        lblCateName.text = cate.name
        
        if !cate.isAll  || cate.iconUrl.contains("http://") || cate.iconUrl.contains("https://"){
            imgAvatar.loadImageUsingCacheWithURLString(cate.iconUrl,size:nil, placeHolder: nil, false) {[weak self] image in
                guard let _self = self else {return}
                _self.imgAvatar.image = image?.tint(with: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)).withRenderingMode(.alwaysTemplate)
                _self.oldImage = _self.imgAvatar.image
            }
        } else {
            imgAvatar.image = UIImage(named: cate.iconUrl)
            self.oldImage = imgAvatar.image
        }
    }
    
    func isfocus(_ isSelect:Bool = false) {
        self.isSelected = isSelect
        if let img = imgAvatar.image, let oI = self.oldImage {
            if self.isSelected {
                imgAvatar.image = img.withRenderingMode(.alwaysTemplate)
                imgAvatar.tintColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
                lblCateName.textColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
            } else {
                imgAvatar.image = oI
                imgAvatar.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                lblCateName.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            }
        }
    }
    
    // MARK: - private
    func configView() {
        
        lblCateName.font = UIFont.systemFont(ofSize: fontSize13)
        lblCateName.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        lblCateName.adjustsFontSizeToFitWidth = true
        
        self.addEvent {[weak self] in
            guard let _self = self else {return}
            if let cate = _self.category {
                _self.onSelectCategory?(cate,_self.tag)
            }
        }
    }
}
