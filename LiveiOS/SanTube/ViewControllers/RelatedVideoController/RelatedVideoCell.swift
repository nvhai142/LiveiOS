//
//  RelatedVideoCell.swift
//  SanTube
//
//  Created by Dai Pham on 12/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class RelatedVideoCell: UITableViewCell {

    // MARK: - outlet
    @IBOutlet weak var imvThumbnail: UIImageView!
    @IBOutlet weak var imvCate: UIImageViewRound!
    @IBOutlet weak var imvUserAvatar: UIImageView!
    
    @IBOutlet weak var lblStreamName: UILabel!
    @IBOutlet weak var btnNumberOfViews: UILabel!
    @IBOutlet weak var lblLive: UILabel!
    @IBOutlet weak var imvIconViews: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var vwContainerBG: UIView!
    
    // MARK: - properties
    var stream:Stream?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configView()
        configText()
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        contentView.frame = UIEdgeInsetsInsetRect(contentView.frame, UIEdgeInsetsMake(0, 0, 0, 0))
//    }
    
    // MARK: - interface
    func load(data:Stream) {
        stream = data
        
        imvThumbnail.loadImageUsingCacheWithURLString(data.thumbnailUrl, size: nil, placeHolder: UIImage(named: APP_LOGO_PLACEHOLDER)?.tint(with: #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)), true, nil)
        lblStreamName.text = data.name
        imvUserAvatar.loadImageUsingCacheWithURLString(data.user.avatar, size: nil, placeHolder: UIImage(named: "ic_profile")?.tint(with: #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)))
        btnNumberOfViews.text = data.noOfViews.toNumberStringView(false)
        
        lblLive.text = data.status == AppConfig.status.stream.streaming() ? "live".localized().uppercased() : "\(data.timeStart())"
        lblLive.backgroundColor = data.status == AppConfig.status.stream.streaming() ? #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1) : UIColor.clear
        lblLive.textColor = data.status == AppConfig.status.stream.streaming() ? #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) : #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)
        
        guard let cate = data.categories.first else { return }
        imvCate.loadImageUsingCacheWithURLString(cate.iconUrl, size: nil, placeHolder: nil, false)
        
        lblUserName.text = data.user.name
    }
    
    // MARK: - private
    func configView() {
        
        lblLive.layer.masksToBounds = true
        lblLive.layer.cornerRadius = 3
        lblLive.font = UIFont.systemFont(ofSize: fontSize13)
        lblLive.textAlignment = .center
        
        imvUserAvatar.layer.borderColor = #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1).cgColor
        imvUserAvatar.layer.borderWidth = 1
        
        imvIconViews.image = #imageLiteral(resourceName: "ic_views").withRenderingMode(.alwaysTemplate)
        imvIconViews.tintColor = #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)
        
        lblStreamName.font = UIFont.systemFont(ofSize: fontSize16)
        lblStreamName.textColor = #colorLiteral(red: 0.2470588235, green: 0.2470588235, blue: 0.2470588235, alpha: 1)
        
        btnNumberOfViews.font = UIFont.systemFont(ofSize: fontSize14)
        btnNumberOfViews.textColor = #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)
        
        lblUserName.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        lblUserName.font = UIFont.boldSystemFont(ofSize: fontSize16)
        
        imvThumbnail.layer.masksToBounds = true
        imvThumbnail.layer.cornerRadius  = 4
    }
    
    func configText() {
        lblLive.text = " \("live".localized().uppercased()) "
    }
    
    // MARK: - prepare reuse
    override func prepareForReuse() {
        Loader.removeLoaderFromViews([self])
        self.stream = nil
        imvUserAvatar.image = nil
        imvCate.image = nil
        imvThumbnail.image = nil
    }
}
