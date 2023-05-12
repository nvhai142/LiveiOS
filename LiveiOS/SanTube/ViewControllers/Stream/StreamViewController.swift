//
//  StreamViewController.swift
//  SanTube
//
//  Created by Hai NguyenV on 11/28/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class StreamViewController: BaseController {
    
    // MARK: - outlet
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: - properties
     var player: IJKFFMoviePlayerController!
    var stream: Stream!
    var isUpdatedViews:Bool = false
    var streamVideoController:PresentVideoController!
    var isGoDirect = true // check if presentVideoController has parent then this view dont called direct then set stream and start play
    var timerCheckingStatus:Timer? // check status stream every 30 seconds. in Case stream stop, notice user
    
    // MARK: - closures
    var onViewDidLoad:(()->Void)?
    var onGotoStreamDetail:((Stream)->Void)?
    
    
    // MARK: - api
    func forceCloseStreamAndQuickView() {
        onDissmiss?()
        self.dismiss(animated: false, completion: nil)
    }
    
    // MARK: - private
    private func loadStream(stream:Stream, vc: PresentVideoController) {
        
        if vc.parent != nil {
            isGoDirect = false
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
        }
        self.addChildViewController(vc)
        view.addSubview(vc.view)
        vc.didMove(toParentViewController: self)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.topAnchor.constraint(equalTo: vc.view.superview!.topAnchor, constant: 0).isActive = true
        vc.view.trailingAnchor.constraint(equalTo: vc.view.superview!.trailingAnchor, constant: 0).isActive = true
        vc.view.bottomAnchor.constraint(equalTo: vc.view.superview!.bottomAnchor, constant: 0).isActive = true
        vc.view.leadingAnchor.constraint(equalTo: vc.view.superview!.leadingAnchor, constant: 0).isActive = true
        vc.type = .full
        if isGoDirect {
            streamVideoController = vc
            vc.stream = stream
            vc.playStream()
            
            startCheckStatus()
        }
        
        // add information controller to view stream
        let vc1 = InformationStreamController(nibName: "InformationStreamController", bundle: Bundle.main)
        vc1.stream = self.stream
        self.addChildViewController(vc1)
        self.view.addSubview(vc1.view)
        vc1.view.translatesAutoresizingMaskIntoConstraints = false
        vc1.view.topAnchor.constraint(equalTo: vc1.view.superview!.topAnchor).isActive = true
        vc1.view.leadingAnchor.constraint(equalTo: vc1.view.superview!.leadingAnchor).isActive = true
        vc1.view.trailingAnchor.constraint(equalTo: vc1.view.superview!.trailingAnchor).isActive = true
        vc1.view.bottomAnchor.constraint(equalTo: vc1.view.superview!.bottomAnchor).isActive = true
        vc1.onShouldClose = {[weak self] in
            guard let _self = self else {return}
            _self.closeStream(isForce: false)
            _self.dismiss(animated: false, completion: nil)
        }
//        vc1.shouldStartShowcase = {[weak self] in
//            guard let _self = self else {return false}
//            if _self.streamVideoController == nil {
//                return false
//            } else {
//                return _self.streamVideoController.avPlayerStream.isPlaying()
//            }
//        }
    }
    
    private func startCheckStatus() {
        self.removeAllTimers()
        if stream == nil {return}
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: {[weak self] timer in
            timer.invalidate()
            guard let _self = self else {return}
            Server.shared.getStream(streamId: _self.stream.id) {[weak _self] str, err in
                guard let __self = _self else {return}
                if let strea = str {
                    print("RESULT STATUS FOR STREAM: \(strea.id) is \(strea.status) - \(strea.offlineURL)")
                    if strea.status != AppConfig.status.stream.streaming() {
                        __self.notice(strea)
                    }
                }
            }
        })
        
        timerCheckingStatus = Timer.scheduledTimer(withTimeInterval: 30, repeats: true, block: {[weak self] timer in
            guard let _self = self else {return}
            print("START CHECKING STATUS FOR STREAM: \(_self.stream.id)")
            // get status again of stream, sure video is streaming else back and go to detail stream offline
            Server.shared.getStream(streamId: _self.stream.id) {[weak _self] str, err in
                guard let __self = _self else {return}
                if let strea = str {
                    print("RESULT STATUS FOR STREAM: \(strea.id) is \(strea.status) - \(strea.offlineURL)")
                    if strea.status != AppConfig.status.stream.streaming() {
                        __self.removeAllTimers()
                        __self.notice(strea)
                    }
                }
            }
        })
    }
    
    private func notice(_ strea:Stream) {
        let ac = UIAlertController(title: "notice".localized().capitalizingFirstLetter(), message: "notice_stream_has_stopped".localized().capitalizingFirstLetter(), preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "exit".localized().capitalizingFirstLetter(), style: .cancel, handler: {[weak self] action in
            guard let _self = self else {return}
            _self.closeStream(isForce: false)
            _self.dismiss(animated: false, completion: nil)
        }))
        ac.addAction(UIAlertAction(title: "detail".localized().capitalizingFirstLetter(), style: .default, handler: {[weak self] action in
            guard let _self = self else {return}
            _self.closeStream(isForce: false)
            _self.onGotoStreamDetail?(strea)
            _self.dismiss(animated: false, completion: nil)
        }))
        present(ac, animated: true)
    }
    
    private func removeAllTimers() {
        timerCheckingStatus?.invalidate()
        timerCheckingStatus = nil
    }
    
    private func closeStream(isForce:Bool) {
        if isGoDirect {
            streamVideoController?.stopPlay()
        }
        // handle when view is dissmiss
        if isForce {
            onDissmiss?()
        }
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onViewDidLoad = {[weak self] in
            guard let _self = self else {return}
            _self.loadStream(stream: _self.stream, vc: _self.streamVideoController)
        }
        
        onViewDidLoad?()
    }
    
    deinit {
        self.removeAllTimers()
        if let strController =  streamVideoController {
            strController.forceOpenPlayBackControl = false
            strController.onTurnOffStream?(stream,strController)
        }
    }
    
    @IBAction func closeButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}
