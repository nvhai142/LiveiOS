//
//  PresentVideoController.swift
//  SanTube
//
//  Created by Dai Pham on 11/16/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

private var AVPLayerLayerObject: UInt8 = 0

protocol PresentViewControllerDelegate {
    func presentVideo(failed:Any?)
}

enum PresentVideoType {
    case quick
    case full
    case minimize
}

class PresentVideoController: BaseController, UIGestureRecognizerDelegate {

    // MARK: - outlet
    @IBOutlet weak var vwVideoContainer: UIStackView!
    @IBOutlet weak var vwVideo: UIStackView!
    @IBOutlet var vwQuickViews: [UIView]!
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var imvThumbnail: UIImageView!
    @IBOutlet weak var iconPlay: UIImageView!
    
    //quick view
    @IBOutlet weak var lblTitleStreamQuick: UILabel!
    @IBOutlet weak var imvUser: UIImageViewRound!
    @IBOutlet weak var lblNameUser: UILabel!
    @IBOutlet weak var imvGoDetail: UIImageView!
    @IBOutlet weak var icMinimize: UIImageView!
    @IBOutlet weak var vwTitle: UIView!
    
    
    // MARK: - constraint
    @IBOutlet weak var heightConstrantVideo: NSLayoutConstraint!
    @IBOutlet weak var centerConstraintStackContainer: NSLayoutConstraint!
    @IBOutlet weak var multiplierWidthHeightVideo: NSLayoutConstraint!
    
    // MARK: - properties
    var delegate:PresentViewControllerDelegate?
    var isUpdatedView:Bool = false
    var avPlayerViewController:AVPlayerViewController!
    var avPlayerStream: IJKFFMoviePlayerController!
    var timerCheckingPlayItem:Timer?
    var customControlMedia:CustomControlMedia!
    var timeObserver: AnyObject!
    var tapGesture:UITapGestureRecognizer!
    var doubleTap:UITapGestureRecognizer!
    var shouldAddCustomMedia:Bool = false
    var forceOpenPlayBackControl:Bool = false {
        didSet {
            forceOpenPlayBackControl = false
        }
    }
    var isBackFromDetail:Bool = false
    
    // fill infor stream when getting data
    var stream:Stream? = nil {
        didSet{
            if self.stream == nil {return}
            if self.stream?.status == AppConfig.status.stream.streaming() {
                iconPlay.isHidden = true
            }
            imvUser.loadImageUsingCacheWithURLString(self.stream!.user.avatar, size: nil, placeHolder: UIImage(named: "ic_profile"), true, nil)
            imvThumbnail.loadImageUsingCacheWithURLString(self.stream!.thumbnailUrl)
            lblNameUser.text = self.stream!.user.name
            lblTitleStreamQuick.text = self.stream!.name
        }
    }
    
    // resort constraint for view
    var type:PresentVideoType = .quick {
        didSet {
            refreshLayout()
        }
    }

    // MARK: - closures
    var onMinimize:((Stream,PresentVideoController)->Void)?
    var onRestoreScreen:((Stream,PresentVideoController)->Void)?
    var onPlayStream:((Stream,PresentVideoController)->Void)?
    var onTurnOffStream:((Stream,PresentVideoController)->Void)?
    var onGotoDetailStream:((Stream,PresentVideoController,IJKFFMoviePlayerController?)->Void)?
    var onVideoFullScreen:((Bool)->Void)?
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configView()
        listernEvent()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        imvGoDetail.addEvent {[weak self] in
            guard let _self = self, let str = stream else {return}
            _self.onGotoDetailStream?(str,_self,str.status == AppConfig.status.stream.streaming() ? avPlayerStream : nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imvGoDetail.removeEvent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshLayout()
    }
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent)
        forceOpenPlayBackControl = parent != nil
        if avPlayerStream != nil {
            iconPlay.isHidden = true
            imvThumbnail.isHidden = true
        }
        if avPlayerViewController != nil {
            avPlayerViewController.showsPlaybackControls = forceOpenPlayBackControl
        }
        if forceOpenPlayBackControl && customControlMedia != nil {
            customControlMedia.isHidden = true
        }
    }
    
    deinit {
        
        if let timer = timerCheckingPlayItem {
            timer.invalidate()
            self.timerCheckingPlayItem = nil
        }
    }
    
    // MARK: - listern event
    func listernEvent() {
        iconPlay.addEvent {[weak self] in
            guard let _self = self else {return}
            _self.onPlayStream?(_self.stream!,_self)
        }
        
        icMinimize.addEvent {[weak self] in
            guard let _self = self else {return}
            guard let str = _self.stream else {return}
            _self.onMinimize?(str,_self)
            if _self.customControlMedia != nil {
                _self.customControlMedia.setHide(true,true)
            }
        }
    }
    
    // MARK: - interface
    func stopPlay() {
        
        iconPlay.isHidden = false
        imvThumbnail.isHidden = false
        icMinimize.isHidden = true
//        if customControlMedia != nil {
//            if customControlMedia.superview != nil {
//                customControlMedia.avPlayerController = nil
//                customControlMedia.removeFromSuperview()
//            }
//        }
        
        if let timer = timerCheckingPlayItem {
            timer.invalidate()
            self.timerCheckingPlayItem = nil
        }
        
        if let str = stream {
            if str.status == AppConfig.status.stream.stop() {
                if avPlayerViewController == nil {return}
                avPlayerViewController.player?.pause()
                avPlayerViewController.player?.replaceCurrentItem(with: nil)
                avPlayerViewController.view.removeGestureRecognizer(tapGesture)
                if doubleTap != nil {
                    avPlayerViewController.view.removeGestureRecognizer(doubleTap)
                }
                if avPlayerViewController != nil {
                    print("TEST DEALLOC")
                    if timeObserver != nil && avPlayerViewController.player?.currentItem != nil {
                        avPlayerViewController.player?.removeTimeObserver(timeObserver)
                    }
                }
                avPlayerViewController.view.removeFromSuperview()
                avPlayerViewController.removeFromParentViewController()
                avPlayerViewController = nil
//                isShouldRemoveObserver = false
                print("STOP PLAY OFFLINE")
                
            } else if str.status == AppConfig.status.stream.streaming() {
                if avPlayerStream == nil {return}
                avPlayerStream.view.removeGestureRecognizer(tapGesture)
                avPlayerStream.pause()
                avPlayerStream.stop()
                avPlayerStream.didShutdown()
//                avPlayerStream.shutdown()
                avPlayerStream.view.removeFromSuperview()
                avPlayerStream = nil
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.IJKMPMoviePlayerLoadStateDidChange, object: nil)
                print("STOP PLAY LIVE")
            }
        }
    }
    
    func playStream(_ stream1:Stream? = nil) {

        iconPlay.isHidden = true
        self.isUpdatedView = false // mark update view is finish
        
        self.view.startLoading(activityIndicatorStyle: .whiteLarge)
        
        var streamPlay = stream1
        if streamPlay == nil {
            streamPlay = self.stream
        }
        
        guard let stream = streamPlay else {return}
        
        if stream.status == AppConfig.status.stream.streaming() {
            let urlString = "rtmp://santube.s3corp.vn:1935/santube/" + stream.id
            avPlayerStream = IJKFFMoviePlayerController(contentURLString: urlString, with: IJKFFOptions.byDefault())  //contetURLStrint helps you making a complete stream at rooms with special characters.
            
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapEvent))
            avPlayerStream.view.addGestureRecognizer(tapGesture)
            tapGesture.cancelsTouchesInView = true
            tapGesture.delegate = self
            
            avPlayerStream.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            avPlayerStream.view.frame = vwVideo.bounds
            vwVideoContainer.addArrangedSubview(avPlayerStream.view)
            avPlayerStream.prepareToPlay()
            
            avPlayerStream.play()
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.IJKMPMoviePlayerLoadStateDidChange, object: avPlayerStream, queue: OperationQueue.main, using: { [weak self] notification in
                
                guard let this = self else {
                    return
                }
                let state = this.avPlayerStream.loadState
                switch state {
                case IJKMPMovieLoadState.playable:
                    print("this.statusLabel.text")
                case IJKMPMovieLoadState.playthroughOK:
                    print("this.statusLabel.text")
                case IJKMPMovieLoadState.stalled:
                    print("this.statusLabel.text")
                default:
                    print("this.statusLabel.text")
                    this.view.stopLoading()
                    // updated views for this stream
                    if !this.isUpdatedView {
                        this.icMinimize.isHidden = false
                        this.imvThumbnail.isHidden = true
                        this.isUpdatedView = true
                        if let user = Account.current {
                            Server.shared.viewStream(user_id: user.id, stream_id: stream.id, nil)
                        }
                    }
                }

                
            })
            NotificationCenter.default.addObserver(forName: NSNotification.Name.IJKMPMoviePlayerPlaybackStateDidChange, object: avPlayerStream, queue: OperationQueue.main, using: { [weak self] notification in
                
                guard let this = self else {
                    return
                }
               
                if this.avPlayerStream == nil {return}
                let statePlay = this.avPlayerStream.playbackState
                switch statePlay {
                case IJKMPMoviePlaybackState.stopped:
                    guard let vc = this.parent as? StreamViewController else {return}
                    let alert = UIAlertController(title: "", message: "this_video_has_been_stop".localized(), preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: {[weak this] action in
                        guard let _this = this else {return}
                        guard let vc = _this.parent as? StreamViewController else {return}
                        vc.forceCloseStreamAndQuickView()
                        
                    }))
                    vc.present(alert,animated:false,completion:nil)
                case IJKMPMoviePlaybackState.paused:
                    this.view.startLoading(activityIndicatorStyle: .whiteLarge)
                case IJKMPMoviePlaybackState.interrupted:
                    this.view.startLoading(activityIndicatorStyle: .whiteLarge)
                case IJKMPMoviePlaybackState.playing:
                    this.view.stopLoading()
                default:
                    this.view.stopLoading()
                }
                
            })
            
        } else if stream.status == AppConfig.status.stream.stop() {
            if avPlayerViewController == nil {
                avPlayerViewController  = AVPlayerViewController()
            }
            self.addChildViewController(avPlayerViewController)
            var videoURL = URL(string: "https://s3.envato.com/h264-video-previews/3209013.mp4")
            if stream.status == AppConfig.status.stream.stop() {
                videoURL = URL(string: stream.offlineURL)
            }
            if let url = videoURL {
                let player = AVPlayer(url: url)
                avPlayerViewController.player = player
                vwVideoContainer.addArrangedSubview(avPlayerViewController.view)
                avPlayerViewController.allowsPictureInPicturePlayback = false
                avPlayerViewController.showsPlaybackControls = false
                avPlayerViewController.player?.play()

                tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapEvent))
                avPlayerViewController.view.addGestureRecognizer(tapGesture)
//                tapGesture.cancelsTouchesInView = true
                tapGesture.delegate = self
                
                doubleTap = UITapGestureRecognizer(target: self, action: #selector(actionDoubleTap(_:)))
                doubleTap.delegate = self
                doubleTap.numberOfTapsRequired = 2
                avPlayerViewController.view.addGestureRecognizer(doubleTap)
                
                // register observer
                if let item = avPlayerViewController.player?.currentItem {
                    timerCheckingPlayItem = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: {[weak self] _ in
                        print("CHECKING play video")
                        guard let _self = self else {return}
                        
                        if item.status == AVPlayerItemStatus.unknown || item.status == AVPlayerItemStatus.failed {
//                            if let timer = _self.timerCheckingPlayItem {
//                                timer.invalidate()
//                            }
                            _self.view.stopLoading()
                            
                        } else if item.status == AVPlayerItemStatus.readyToPlay {
                            
                            if let timer = _self.timerCheckingPlayItem {
                                timer.invalidate()
                            }
                            _self.imvThumbnail.isHidden = true
                            _self.view.stopLoading()
                            if !_self.forceOpenPlayBackControl && _self.shouldAddCustomMedia {
                                _self.showCustomControlMedia()
                            }
                            
                            // observer time player to update custom control media
                            let timeInterval: CMTime = CMTimeMakeWithSeconds(1.0, 10)
                            _self.timeObserver = _self.avPlayerViewController.player!.addPeriodicTimeObserver(forInterval: timeInterval,
                                                                                                  queue: DispatchQueue.main) {[weak _self] (elapsedTime: CMTime) -> Void in
                                                                                                    guard let __self = _self else {return}
                                                                                                    __self.observeTime(elapsedTime: elapsedTime)
                                } as AnyObject
                            
                            // updated views for this stream
                            if !_self.isUpdatedView {
                                _self.icMinimize.isHidden = false
                                _self.isUpdatedView = true
                                if let user = Account.current, let str = _self.stream {
                                    Server.shared.viewStream(user_id: user.id, stream_id: str.id, nil)
                                }
                            }
                        }
                    })
                }
            }
        }
        view.bringSubview(toFront: imvThumbnail)
    }
    
    func hideCustomMediaControl(_ isHide:Bool = true, isForce:Bool = false,_ completion:((Bool)->Void)? = nil) {
        if customControlMedia != nil {
            customControlMedia.setHide(isHide, isForce){bool in completion?(bool)}
        }
    }
    
    func dontShowMediaControl(_ isShow:Bool = true) {
        avPlayerViewController.showsPlaybackControls = false//isShow
    }
    
    // MARK: - event
    func actionDoubleTap(_ sender: UITapGestureRecognizer) {
        guard let str = self.stream else { return }
        self.onGotoDetailStream?(str,self,str.status == AppConfig.status.stream.streaming() ? avPlayerStream : nil)
//        self.onVideoFullScreen?(type == .full ? false : true)
//        type = .full
    }
    
    // MARK: - private
    func refreshLayout() {
        if vwVideo == nil {return}
        _ = vwQuickViews.map{$0.isHidden = false}
        icMinimize.isHidden = false
        vwTitle.isHidden = false
        if type == .quick {
            
            // check if height constraint in case removed, add again
            if self.heightConstrantVideo == nil {
                
                self.heightConstrantVideo = vwVideo.heightAnchor.constraint(equalToConstant: UI_USER_INTERFACE_IDIOM() == .pad ? self.view.frame.size.height * 70/100 : self.view.frame.size.height * 70/100)
                self.heightConstrantVideo.priority = 1000
                vwVideo.addConstraint(self.heightConstrantVideo)
                
                for constraint in stackContainer.superview!.constraints.reversed() {
                    if constraint.firstAttribute == .top && constraint.firstItem.isEqual(stackContainer) {
                        stackContainer.superview!.removeConstraint(constraint)
                    }
                    if constraint.firstAttribute == .bottom && constraint.firstItem.isEqual(stackContainer) {
                        stackContainer.superview!.removeConstraint(constraint)
                    }
                }
                
                centerConstraintStackContainer = stackContainer.centerYAnchor.constraint(equalTo: stackContainer.superview!.centerYAnchor)
                stackContainer.superview!.addConstraint(centerConstraintStackContainer)
            }

            // set up it with 1/2 screen
            self.heightConstrantVideo.constant = UI_USER_INTERFACE_IDIOM() == .pad ? self.view.frame.size.height * 70/100 : self.view.frame.size.height * 70/100
            
        } else if type == .full || type == .minimize {
            
            
            if self.heightConstrantVideo != nil {
                vwVideo.removeConstraint(self.heightConstrantVideo)
            }
            if self.centerConstraintStackContainer != nil {
                stackContainer.removeConstraint(centerConstraintStackContainer)
            }
            stackContainer.topAnchor.constraint(equalTo: stackContainer.superview!.topAnchor).isActive = true
            stackContainer.bottomAnchor.constraint(equalTo: stackContainer.superview!.bottomAnchor).isActive = true
            stackContainer.leadingAnchor.constraint(equalTo: stackContainer.superview!.leadingAnchor,constant:0).isActive = true
            let trailing =  stackContainer.trailingAnchor.constraint(equalTo: stackContainer.superview!.trailingAnchor,constant:0)
            trailing.priority = 750
            stackContainer.superview!.addConstraint(trailing)
            
            _ = vwQuickViews.map{$0.isHidden = true}
            icMinimize.isHidden = true
            vwTitle.isHidden = true
        }
    }
    
    func configView() {
        
        lblNameUser.text = " "
        lblTitleStreamQuick.text = " "
        
        lblNameUser.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lblNameUser.font = UIFont.systemFont(ofSize: fontSize14)
        
        lblTitleStreamQuick.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lblTitleStreamQuick.font = UIFont.systemFont(ofSize: fontSize16)
        
        imvGoDetail.image = UIImage(named:"ic_goto")?.withRenderingMode(.alwaysTemplate)
        imvGoDetail.tintColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
        
        icMinimize.image = UIImage(named:"ic_minimize")?.withRenderingMode(.alwaysTemplate)
        icMinimize.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        imvUser.layer.borderColor = UIColor(hex:"0xFEDA00").cgColor
//        imvUser.backgroundColor = UIColor.clear
        imvUser.layer.borderWidth = 1
        
        iconPlay.image = UIImage(named: "ic_play_video")?.withRenderingMode(.alwaysTemplate)
        iconPlay.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        iconPlay.addMask(color: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), 0.3, true)
    }
    
    func showCustomControlMedia() {
        
        if customControlMedia != nil {
            if customControlMedia.superview != nil {
                return
            }
        }
        
        customControlMedia = Bundle.main.loadNibNamed("CustomControlMedia", owner: self, options: nil)?.first as! CustomControlMedia
        self.parent?.view.addSubview(customControlMedia)
        customControlMedia.translatesAutoresizingMaskIntoConstraints = false
        customControlMedia.topAnchor.constraint(equalTo: vwVideoContainer.topAnchor).isActive = true
        customControlMedia.bottomAnchor.constraint(equalTo: vwVideoContainer.bottomAnchor).isActive = true
        customControlMedia.leadingAnchor.constraint(equalTo: vwVideoContainer.leadingAnchor).isActive = true
        customControlMedia.trailingAnchor.constraint(equalTo: vwVideoContainer.trailingAnchor).isActive = true
        self.parent?.view.bringSubview(toFront: customControlMedia)
        
        customControlMedia.avPlayerController = self.avPlayerViewController
        customControlMedia.setStateScreenVideo(full:self.type != .quick,false)
        customControlMedia.touchFullScreen = {[weak self] isFullScreen in
            guard let __self = self else {return}
            __self.onVideoFullScreen?(isFullScreen)
        }
    }
    
    func tapEvent(event:UITapGestureRecognizer) {
        if type == .minimize && !forceOpenPlayBackControl {
            self.onRestoreScreen?(self.stream!,self)
            if customControlMedia != nil {
                customControlMedia.setHide(false,true)
            }
            return
        }
        
        if !forceOpenPlayBackControl {
            if customControlMedia != nil {
                if customControlMedia.superview != nil {
                    customControlMedia.setHide(false)
                }
            }
        } else {
//            if avPlayerViewController == nil {return}
//            if !avPlayerViewController.showsPlaybackControls {
//                avPlayerViewController.showsPlaybackControls = !avPlayerViewController.showsPlaybackControls
//            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - handle custom media control
extension PresentVideoController {
    fileprivate func observeTime(elapsedTime: CMTime) {
        print("TimeObServer is running")
        guard let _ = avPlayerViewController else { return }
        if let player = avPlayerViewController.player {
            if let item = player.currentItem {
                let duration = CMTimeGetSeconds(item.duration)
                if duration.isFinite {
                    let elapsedTime = CMTimeGetSeconds(elapsedTime)
                    let timeRemaining: Float64 = CMTimeGetSeconds(item.duration) - elapsedTime
                    if customControlMedia != nil {
                        customControlMedia.updateTime(String(format: "%02d:%02d", ((lround(timeRemaining) / 60) % 60), lround(timeRemaining) % 60), elapsedTime, duration, false)
                    }
                }
            }
        }
    }
}
