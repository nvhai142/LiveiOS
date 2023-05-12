//
//  FeatureStreamView.swift
//  BUUP
//
//  Created by Dai Pham on 11/6/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

// MARK: - FeatureStreamView
class FeatureStreamView: UITableViewCell {

    @IBOutlet var stackContainer: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var onSelectObject:((Stream)->Void)?
    
    var listDatas:[Stream] = []
    var height:CGFloat = 0
    
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        configView()
    }
    
    // MARK: - interface
    func loadListFeature(_ list:[Stream]?,_ titleBelow:String? = nil) {
        guard let listFeatures = list else { return }
        listDatas.removeAll()
        listDatas = listFeatures
        
        loadData()
    }
    
    func getHeight()->CGFloat {
        return self.frame.size.height
    }
    
    // MARK: - private
    private func loadData() {
        _ = stackContainer.arrangedSubviews.reversed().map{if !$0.isKind(of: UILabel.self){ $0.removeFromSuperview()}}
        for item in listDatas {
            let cv = Bundle.main.loadNibNamed("FeatureStreamBlockView", owner: self, options: [:])?.first as! FeatureStreamBlockView
            cv.loadObject(object: item)
            cv.onSelectObject = {[weak self] object in
                guard let _self = self else {return}
                _self.onSelectObject?(object)
            }
            stackContainer.insertArrangedSubview(cv, at: stackContainer.arrangedSubviews.count)
            cv.translatesAutoresizingMaskIntoConstraints = false
            let numberItem:CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 5 : 2
            let width = (UIScreen.main.bounds.size.width - (10 + numberItem*10))/numberItem
            cv.widthAnchor.constraint(equalToConstant: width).isActive = true
            cv.heightAnchor.constraint(equalToConstant: width*1.4).isActive = true
        }
    }
    
    func configView() {
        
    }
    
    func configTitle(_ label:UILabel) {
        label.font = UIFont.boldSystemFont(ofSize: fontSize22)
        label.textColor = #colorLiteral(red: 0.631372549, green: 0.631372549, blue: 0.631372549, alpha: 1)
    }
}

// MARK: - FeatureStreamBlockView
class FeatureStreamBlockView: UIView {
    
    @IBOutlet var lblLive: UILabel!
    @IBOutlet var imvIconCategory: UIImageView!
    @IBOutlet weak var imvUser: UIImageViewRound!
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var imvStream: UIImageView!
    @IBOutlet weak var vwInformation: UIView!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var blurImageView: UIView!
    
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
    func loadObject(object:Stream) {
        self.object = object
        lblTitle.text = object.name
        if object.status == AppConfig.status.stream.streaming() {
            lblLive.text = "\("live".localized().uppercased())"
        } else {
            lblLive.removeFromSuperview()
        }
        imvStream.loadImageUsingCacheWithURLString(object.thumbnailUrl, size: nil, placeHolder: UIImage(named: APP_LOGO_PLACEHOLDER)?.tint(with: #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)))
        if let cate = object.categories.first {
            imvIconCategory.loadImageUsingCacheWithURLString(cate.iconUrl, size: imvIconCategory.frame.size, placeHolder: nil,false)
        }
        
        lblUserName.text = object.user.name
        imvUser.loadImageUsingCacheWithURLString(object.user.avatar, size: nil, placeHolder: UIImage(named: "ic_profile")?.tint(with: #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)))
    }
    
    
    // MARK: - event
    func touchView(_ gesture:UIGestureRecognizer) {
        guard let obj = self.object else { return }
        self.onSelectObject?(obj)
    }
    
    // MARK: - private
    func configView() {
        lblLive.font = UIFont.boldSystemFont(ofSize: fontSize14)
        lblLive.layer.masksToBounds = true
        lblLive.layer.cornerRadius = 3
        
        lblUserName.textColor = #colorLiteral(red: 0.7215686275, green: 0.7215686275, blue: 0.7215686275, alpha: 1)
        lblUserName.font = UIFont.systemFont(ofSize: fontSize13)
        
        lblTitle.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        lblTitle.font = UIFont.systemFont(ofSize:12)
        
        vwInformation.layer.cornerRadius = 3
        imvStream.layer.cornerRadius = 5
        blurImageView.layer.cornerRadius = 5
        
    }
}
