//
//  RelatedVideoBlockView.swift
//  SanTube
//
//  Created by Dai Pham on 3/15/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class RelatedVideoBlockView: UIView {

    
    @IBOutlet var imvStream: UIImageView!
    @IBOutlet weak var btnNumberOfViews: UILabel!
    @IBOutlet weak var lblLive: UILabel!
    @IBOutlet weak var imvIconViews: UIImageView!
    
    var tapGesture:UITapGestureRecognizer?
    var onSelectObject:((Stream)->Void)?
    
    
    var object:Stream?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // init tapgesture
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.touchView(_:)))
        tapGesture?.cancelsTouchesInView = true
        if let tap = tapGesture {
            self.addGestureRecognizer(tap)
        }
        
        configView()
        
    }
    
    deinit {
        if let tap = tapGesture {
            self.removeGestureRecognizer(tap)
        }
    }
    
    // MARK: - interface
    func load(data:Stream) {
        self.object = data
        if data.status == AppConfig.status.stream.streaming() {
            lblLive.text = "\("live".localized().uppercased())"
        } else {
            lblLive.removeFromSuperview()
        }
        imvStream.loadImageUsingCacheWithURLString(data.thumbnailUrl, size: nil, placeHolder: UIImage(named: APP_LOGO_PLACEHOLDER)?.tint(with: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
        
        btnNumberOfViews.text = data.noOfViews.toNumberStringView(false)
    }
    
    
    // MARK: - event
    func touchView(_ gesture:UIGestureRecognizer) {
        guard let obj = self.object else { return }
        self.onSelectObject?(obj)
    }
    
    // MARK: - private
    func configView() {
        lblLive.layer.masksToBounds = true
        lblLive.layer.cornerRadius = 3
        lblLive.font = UIFont.systemFont(ofSize: fontSize13)
        lblLive.textAlignment = .center
        imvStream.layer.cornerRadius = 5
        
        imvIconViews.image = #imageLiteral(resourceName: "ic_views").withRenderingMode(.alwaysTemplate)
        imvIconViews.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        btnNumberOfViews.font = UIFont.systemFont(ofSize: fontSize14)
        btnNumberOfViews.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
}
