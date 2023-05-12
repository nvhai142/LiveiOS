//
//  TopViewsStreamCell.swift
//  BUUP
//
//  Created by Dai Pham on 11/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import AVFoundation

class ViewsStreamCell: UITableViewCell {

    // MARK: - outlet
    @IBOutlet weak var imgThumbnail: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblInfor: UILabel!
    @IBOutlet var lblLive: UILabel!
    @IBOutlet weak var imvIconCategory: UIImageView!
    
    // MARK: - properties
    var onTouchButton:((Stream)->Void)?
    var object:Stream?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        configView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - interface
    func load(_ stream:Stream) {
        object = stream
        
        if stream.status == AppConfig.status.stream.streaming() {
            lblLive.text = "live".localized().uppercased()
        } else {
            lblLive.isHidden = true
        }
        lblTitle.text = stream.name
        imgThumbnail.loadImageUsingCacheWithURLString(stream.thumbnailUrl,size:CGSize(width:self.frame.size.width,height:self.frame.size.height), placeHolder: UIImage(named: APP_LOGO_PLACEHOLDER)?.tint(with: UIColor.black))
        if let cate = stream.categories.first {
            imvIconCategory.loadImageUsingCacheWithURLString(cate.iconUrl, size:nil, placeHolder: nil,false)
        }
        lblInfor.text = "\(stream.user.name.uppercased()) - \(stream.timeStart())"
    }
    
    // MARK: - private
    func configView() {
//        imgThumbnail.clipsToBounds = true
//        imgThumbnail.layer.cornerRadius = 7
        
//        lblLive.clipsToBounds = true
        lblLive.font = UIFont.boldSystemFont(ofSize: 14)
//        lblLive.layer.cornerRadius = 4
        
        lblTitle.font = UIFont.systemFont(ofSize: fontSize16)
        lblTitle.textColor = #colorLiteral(red: 0.2235294118, green: 0.2235294118, blue: 0.2235294118, alpha: 1)
        
        lblInfor.textColor = #colorLiteral(red: 0.3725490196, green: 0.2784313725, blue: 0.1921568627, alpha: 1)
    }
    
    func configText() {
        
    }
    
//    func startPlay() {
//        if let streammm = self.object {
//            var videoURL = URL(string: "http://\(ConfigStream.current.ip):\(ConfigStream.current.port)/buup_live/\(streammm.id)/playlist.m3u8")
//
//            if streammm.status == AppConfig.status.stream.stop() {
//                videoURL = URL(string: streammm.offlineURL)
//            }
//            if let url = videoURL {
//                let player = AVPlayer(url: url)
//                let playerLayer = AVPlayerLayer(player: player)
////                playerLayer.addObserver(self, forKeyPath: "readyForDisplay", options: [.initial, .new], context: nil)
//                playerLayer.frame = CGRect(origin: CGPoint.zero, size: imgThumbnail.frame.size)
////                objc_setAssociatedObject(self, &AssociatedObjectHandle, playerLayer, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//                imgThumbnail.layer.addSublayer(playerLayer)
//                player.play()
//            }
//        }
//    }
//
//    func stopPlay() {
//        if let players = imgThumbnail.layer.sublayers {
//            for item in players {
//                if item.isKind(of: AVPlayerLayer.self) {
//                    item.removeFromSuperlayer()
//                }
//            }
//        }
//    }
    
    // MARK: - preuse
    override func prepareForReuse() {
//        stopPlay()
        lblLive.isHidden = false
        imgThumbnail.image = nil
        object = nil
        imvIconCategory.image = nil
    }
}
