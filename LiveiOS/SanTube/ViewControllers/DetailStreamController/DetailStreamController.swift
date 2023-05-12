//
//  DetailStreamController.swift
//  SanTube
//
//  Created by Dai Pham on 12/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class DetailStreamController: BaseController {

    // MARK: - outlet common
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var vwVideo: UIView!
    @IBOutlet weak var btnInfo: UIButton!
    @IBOutlet weak var btnComments: UIButton!
    @IBOutlet weak var btnRelatedVideos: UIButton!
    @IBOutlet weak var vwInfo: UIScrollView!
    
    // MARK: - outlet info
    @IBOutlet weak var lblTitleStream: UILabel!
    @IBOutlet weak var btnNumberOfLikes: UILabel!
    @IBOutlet weak var btnNumberOfViews: UILabel!
    @IBOutlet weak var imvStreamCate: UIImageView!
    @IBOutlet weak var lblTimeStartStream: UILabel!
    @IBOutlet weak var lblNumberOfShares: UILabel!
    @IBOutlet weak var lblNumberOfComments: UILabel!
    @IBOutlet weak var imvAvatar: UIImageViewRound!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var btnFollow: UIButton!
    @IBOutlet weak var imvIconShare: UIImageView!
    @IBOutlet weak var imvIconComment: UIImageView!
    @IBOutlet weak var imvIconLikes: UIImageView!
    @IBOutlet weak var imvIconViews: UIImageView!
    
    
    // MARK: - properties
    var btnSelected:UIButton?
    var stream:Stream?
    var inforStreamController:InformationStreamController!
    var streamVideoController:PresentVideoController?
    var isGoDirect:Bool = false // check if go from quickview
    
    // MARK: - closures
    var onViewDidLoad:(()->Void)?
    var onGotoLiveStream:((Stream)->Void)?
    
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        // add information controller to view stream
        inforStreamController = InformationStreamController(nibName: "InformationStreamController", bundle: Bundle.main)
        inforStreamController.stream = self.stream
        self.addChildViewController(inforStreamController)
        self.view.addSubview(inforStreamController.view)
        self.view.bringSubview(toFront: inforStreamController.view)
        inforStreamController.view.translatesAutoresizingMaskIntoConstraints = false
        inforStreamController.view.topAnchor.constraint(equalTo: inforStreamController.view.superview!.topAnchor).isActive = true
        inforStreamController.view.leadingAnchor.constraint(equalTo: inforStreamController.view.superview!.leadingAnchor).isActive = true
        inforStreamController.view.trailingAnchor.constraint(equalTo: inforStreamController.view.superview!.trailingAnchor).isActive = true
        inforStreamController.view.bottomAnchor.constraint(equalTo: inforStreamController.view.superview!.bottomAnchor).isActive = true
        inforStreamController.onShouldClose = {[weak self] in
            guard let _self = self else {return}
//            _self.closeStream(isForce: false)
            _self.dismiss(animated: true, completion: nil)
        }
        
        inforStreamController.onReloadOfflineStream = {[weak self] str in
            guard let _self = self else {return}
            _self.stream = str
            if str.status == AppConfig.status.stream.streaming() {
                _self.onGotoLiveStream?(str)
                _self.dismiss(animated: true, completion: nil)
                return
            }
            _self.streamVideoController?.stopPlay()
            _self.streamVideoController?.stream = str
            _self.streamVideoController?.playStream()
            _self.inforStreamController.stream = str
            _self.inforStreamController.load(str)
        }
        
        configView()
        addDefaultMenu()
        
        onViewDidLoad = {[weak self] in
            guard let _self = self else {return}
            if let str = _self.stream, let present = _self.streamVideoController {
                _self.loadStream(stream: str, vc: present)
            }
        }
        
        onViewDidLoad?()
    }
    
    deinit {
        streamVideoController?.shouldAddCustomMedia = false
        onDissmiss?()
        if let strController =  streamVideoController, let str = self.stream {
            strController.forceOpenPlayBackControl = false
            strController.onTurnOffStream?(str,strController)
        }
    }
    
    // MARK: - interface
    func loadStream(stream:Stream,vc:PresentVideoController) {
        self.stream = stream
        isGoDirect = vc.parent == nil
        if !isGoDirect {
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
        }
        self.addChildViewController(vc)
        vwVideo.addSubview(vc.view)
        vc.didMove(toParentViewController: self)
        if vc.view.translatesAutoresizingMaskIntoConstraints {
           vc.view.translatesAutoresizingMaskIntoConstraints = false
        }
        vc.view.topAnchor.constraint(equalTo: vc.view.superview!.topAnchor, constant: 0).isActive = true
        vc.view.trailingAnchor.constraint(equalTo: vc.view.superview!.trailingAnchor, constant: 0).isActive = true
        vc.view.bottomAnchor.constraint(equalTo: vc.view.superview!.bottomAnchor, constant: 0).isActive = true
        vc.view.leadingAnchor.constraint(equalTo: vc.view.superview!.leadingAnchor, constant: 0).isActive = true
        if !isGoDirect {vc.type = .full}
        vc.forceOpenPlayBackControl = false
        vc.shouldAddCustomMedia = true
        vc.showCustomControlMedia()
        UIApplication.shared.keyWindow?.bringSubview(toFront: vc.customControlMedia)
        if isGoDirect {
            streamVideoController?.stream = stream
            streamVideoController?.type = .full
            streamVideoController?.playStream()
        }
//        vc.avPlayerViewController.player?.play()
    }
    
    // MARK: - private    
    func configView() {
    }
}
