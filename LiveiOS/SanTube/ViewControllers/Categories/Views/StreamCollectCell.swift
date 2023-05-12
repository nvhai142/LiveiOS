//
//  StreamCollectCell.swift
//  SanTube
//
//  Created by Dai Pham on 12/1/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

enum StreamCollectCellType {
    case expand
    case normal
}

class StreamCollectCell: UICollectionViewCell {

    // MARK: - outlet
    @IBOutlet weak var imvThumbnail: UIImageView!
    @IBOutlet weak var vwViews: UIView!
    @IBOutlet weak var stackViews: UIStackView!
    @IBOutlet weak var iconViews: UIImageView!
    @IBOutlet weak var lblNumberViews: UILabel!
    @IBOutlet weak var lblLive: UILabel!
    
    // MARK: - peroperties
    var type:StreamCollectCellType = .normal
    var stream:Stream?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        lblLive.isHidden = true
        
        configView()
    }

    // MARK: - interface
    func load(stream:Stream) {
        self.stream = stream
        
        lblLive.isHidden = stream.status != AppConfig.status.stream.streaming() ? true : false
        vwViews.isHidden = stream.status != AppConfig.status.stream.streaming() ? false : true
        stackViews.isHidden = stream.status != AppConfig.status.stream.streaming() ? false : true
        
         let imgThumbnailPlaceholder = UIImage(named: APP_LOGO_PLACEHOLDER)?.tint(with: #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1))
        
        lblNumberViews.text = stream.noOfViews.toNumberStringView(false)
        lblLive.isHidden = stream.status != AppConfig.status.stream.streaming()
        imvThumbnail.loadImageUsingCacheWithURLString(stream.thumbnailUrl, size: imvThumbnail.frame.size, placeHolder: imgThumbnailPlaceholder)
        
        configView()
    }
    
    // MARK: - private
    func configView() {
        
        imvThumbnail.layer.cornerRadius = 3
        iconViews.backgroundColor = UIColor.clear
        
        lblLive.font = UIFont.boldSystemFont(ofSize: fontSize13)
        lblLive.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        lblLive.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lblLive.text = "live".localized().uppercased()
        lblLive.layer.masksToBounds = true
        lblLive.layer.cornerRadius = 3
        
        lblNumberViews.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lblNumberViews.font = UIFont.boldSystemFont(ofSize: fontSize14)
        
        iconViews.image = #imageLiteral(resourceName: "ic_views").withRenderingMode(.alwaysTemplate)
        iconViews.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        vwViews.layer.cornerRadius = 3

        self.layer.cornerRadius = 3
//        self.dropShadow(offsetX: 0, offsetY: 0.3, color: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), opacity: 0.3, radius: 5, scale: true)
    }
    
    override func prepareForReuse() {
        
        configView()
        imvThumbnail.image = nil
        lblNumberViews.isHidden = false
        self.imvThumbnail.contentMode = .scaleAspectFill
        type = .normal
        stream = nil
        lblLive.isHidden = true
    }
}
