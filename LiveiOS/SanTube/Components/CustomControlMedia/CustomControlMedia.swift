//
//  CustomControlMedia.swift
//  SanTube
//
//  Created by Dai Pham on 12/21/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class CustomControlMedia: UIView {
    
    // MARK: - outlet
    @IBOutlet weak var iconFullScreen: UIImageView!
    @IBOutlet weak var lbltime: UILabel!
    @IBOutlet weak var iconPlay: UIImageView!
    @IBOutlet weak var sliderSeekTime: UISlider!
    
    // MARK: - properties
    var videoDuration:Float64 = 0
    internal var lastTime: CFTimeInterval = 0.0
    internal var currentTimeVideo: CFTimeInterval = 0.0
    var isUpdatingSliderValue:Bool = false
    fileprivate var displayLinkUpdateSliderValue:CADisplayLink?
    fileprivate var timerCheckPlayerStop:Timer?
    fileprivate var timerAutoHide:Timer?
    fileprivate var isFullScreenState:Bool = false {
        didSet {
            for constraint in iconFullScreen.superview!.constraints {
                if constraint.firstItem.isEqual(iconFullScreen) && constraint.firstAttribute == .top {
                    constraint.constant = isFullScreenState ? 25 : 5
                }
            }
        }
    }
    weak var avPlayerController:AVPlayerViewController? {
        didSet {
            playerRateBeforeSeek = 0
            stopTimerCheckPlayingVideo()
            displayLinkUpdateSliderValue?.invalidate()
            displayLinkUpdateSliderValue = nil
            lbltime.text = ""
            sliderSeekTime.value = 0
            guard let avPlayer = avPlayerController?.player else { return}
            NotificationCenter.default.addObserver(self, selector:#selector(playerDidFinishPlaying),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
        }
    }
    var playerRateBeforeSeek: Float = 0
    
    // MARK: - closure
    var touchFullScreen:((Bool)->Void)?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configView()
        listernEvent()
        setHide(true)
        
        stopTimerCheckPlayingVideo()
        
//        timerCheckPlayerStop = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {[weak self] _ in
//            guard let _self = self else {return}
//
//        })
    }

    override func removeFromSuperview() {
        self.timerAutoHide?.invalidate()
        displayLinkUpdateSliderValue?.invalidate()
        stopTimerCheckPlayingVideo()
        guard let avPlayer = avPlayerController?.player else { return}
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avPlayer.currentItem)
        super.removeFromSuperview()
    }
    
    // MARK: - listern event
    func listernEvent() {
        
        iconPlay.addEvent {
            guard let avPlayer = avPlayerController?.player else { return}
            let playerIsPlaying = avPlayer.rate > 0
            if playerIsPlaying {
                avPlayer.pause()
                displayLinkUpdateSliderValue?.isPaused = true
                self.timerAutoHide?.invalidate()
            } else {
                startTimerHide(false,force: false, completion:{[weak self] done in
                    guard let _ = self else {return}
                    NotificationCenter.default.post(name: NSNotification.Name("App:CustomControlMediaDidHide"), object: nil, userInfo: nil)
                })
                if sliderSeekTime.value == 1 {
                    avPlayer.seek(to: kCMTimeZero)
                    startUpdateValueSlider()
                } else {
                    displayLinkUpdateSliderValue?.isPaused = false
                }
                avPlayer.play()
            }
        }
        
        iconFullScreen.addEvent {
            self.setStateScreenVideo(full: !self.isFullScreenState)
        }
        
    }
    
    func playerDidFinishPlaying(note: NSNotification){
        print("Video Finished")
        currentTimeVideo = 0
        displayLinkUpdateSliderValue?.invalidate()
        self.iconPlay.image = #imageLiteral(resourceName: "ic_play_video_small").withRenderingMode(.alwaysTemplate)
        self.iconPlay.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    
    // MARK: - interface
    func setHide(_ hide:Bool = true,_ force:Bool = false, completion:((Bool)->Void)? = nil) {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = hide ? 0 : 1
            self.transform = hide ? CGAffineTransform(translationX: 0, y: self.frame.size.height + 20) : .identity
        }, completion: {done in
            if done && !hide {completion?(!self.transform.isIdentity)}
        })
        
        startTimerHide(hide,force: force, completion:completion)
    }
    
    func startTimerHide(_ hide:Bool = false,force:Bool = false, completion:((Bool)->Void)? = nil) {
        self.timerAutoHide?.invalidate()
        if hide == false {
            timerAutoHide = Timer.scheduledTimer(withTimeInterval: force ? 0 : 5, repeats: false, block: {[weak self] _ in
                guard let _self = self else {return}
                _self.timerAutoHide?.invalidate()
                UIView.animate(withDuration: 0.3, animations: {
                    _self.transform = CGAffineTransform(translationX: 0, y: _self.frame.size.height + 20)
                    _self.alpha = 0
                }, completion: {done in
                    if done {completion?(!_self.transform.isIdentity)}
                })
                
            })
        } else {
            if force {completion?(!self.transform.isIdentity)}
        }
    }
    
    func setStateScreenVideo(full isFull:Bool,_ isInvolkeOutSide:Bool = true) {
        self.isFullScreenState = isFull
        if isInvolkeOutSide {
            self.touchFullScreen?(self.isFullScreenState)
        }
        self.iconFullScreen.image = (self.isFullScreenState ? #imageLiteral(resourceName: "ic_exit_fullscreen") : #imageLiteral(resourceName: "ic_fullscreen")).withRenderingMode(.alwaysTemplate)
        self.iconFullScreen.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    
    func updateTime(_ time:String,_ timeUpdate:Float64 = 0,_ videoDuration:Float64 = 0,_ onlyUpdateLabelTime:Bool = true) {
        lbltime.text = time
        
        if !onlyUpdateLabelTime {
            self.videoDuration = videoDuration
            if displayLinkUpdateSliderValue == nil {
                startUpdateValueSlider()
            }
        } else {
            currentTimeVideo = timeUpdate
        }
        
//        if sliderSeekTime.value == 0 || sliderSeekTime.value == 1 {
//            iconPlay.image = #imageLiteral(resourceName: "ic_play_video_small").withRenderingMode(.alwaysTemplate)
//            iconPlay.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
//        } else {
//            iconPlay.image = #imageLiteral(resourceName: "ic_pause").withRenderingMode(.alwaysTemplate)
//            iconPlay.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
//        }
        
        guard let avPlayer = self.avPlayerController?.player else { return}
        let playerIsPlaying = avPlayer.rate > 0
        if playerIsPlaying {
            self.iconPlay.image = #imageLiteral(resourceName: "ic_pause").withRenderingMode(.alwaysTemplate)
            self.iconPlay.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        } else {
            self.iconPlay.image = #imageLiteral(resourceName: "ic_play_video_small").withRenderingMode(.alwaysTemplate)
            self.iconPlay.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
    }
    
    func hideFullScreen(_ hide:Bool = true) {
        iconFullScreen.isHidden = hide
    }
    
    // MARK: - event slide
    func sliderBeganTracking(slider: UISlider) {
        guard let avPlayer = avPlayerController?.player else { return}
        playerRateBeforeSeek = avPlayer.rate
        avPlayer.pause()
        displayLinkUpdateSliderValue?.isPaused = true
        timerAutoHide?.invalidate()
    }
    
    func sliderEndedTracking(slider: UISlider) {
        guard let avPlayer = avPlayerController?.player else { return}
        let videoDuration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        let elapsedTime: Float64 = videoDuration * Float64(sliderSeekTime.value)
        let timeRemaining: Float64 = CMTimeGetSeconds(avPlayer.currentItem!.duration) - elapsedTime
        updateTime(String(format: "%02d:%02d", ((lround(timeRemaining) / 60) % 60), lround(timeRemaining) % 60),elapsedTime)
        
        avPlayer.seek(to: CMTimeMakeWithSeconds(elapsedTime, 100)) { (completed: Bool) -> Void in
            if self.playerRateBeforeSeek > 0 {
                self.avPlayerController?.player?.play()
                self.displayLinkUpdateSliderValue?.isPaused = false
            }
        }
        
        startTimerHide(false,force: false, completion:{[weak self] done in
            guard let _ = self else {return}
            NotificationCenter.default.post(name: NSNotification.Name("App:CustomControlMediaDidHide"), object: nil, userInfo: nil)
        })
    }
    
    func sliderValueChanged(slider: UISlider) {
        guard let avPlayer = avPlayerController?.player else { return}
        let videoDuration = CMTimeGetSeconds(avPlayer.currentItem!.duration)
        let elapsedTime: Float64 = videoDuration * Float64(sliderSeekTime.value)
        let timeRemaining: Float64 = CMTimeGetSeconds(avPlayer.currentItem!.duration) - elapsedTime
        updateTime(String(format: "%02d:%02d", ((lround(timeRemaining) / 60) % 60), lround(timeRemaining) % 60),elapsedTime)
        
        lbltime.setNeedsDisplay()
        lbltime.frame = CGRect(origin: setUISliderThumbValueWithLabel(slider: sliderSeekTime), size: lbltime.frame.size)
    }
    
    // MARK: - private
    fileprivate func configView() {
        
        lbltime.font = UIFont.systemFont(ofSize: fontSize13)
        lbltime.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lbltime.text = "-:-"
        lbltime.textAlignment = .left
        lbltime.frame = CGRect(x: 0, y: 0, width: 100, height: 30)
        lbltime.adjustsFontSizeToFitWidth = true
        
        iconFullScreen.layer.cornerRadius = 4
        iconPlay.layer.cornerRadius = 4
        iconFullScreen.backgroundColor = #colorLiteral(red: 0.07843137255, green: 0.08610491071, blue: 0.1154017857, alpha: 0.5)
        iconPlay.backgroundColor = #colorLiteral(red: 0.07843137255, green: 0.08610491071, blue: 0.1154017857, alpha: 0.5)
        
        sliderSeekTime.setThumbImage(#imageLiteral(resourceName: "ic_dot_circle").resizeImageWith(newSize: CGSize(width: 10, height: 10)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: .normal)
        sliderSeekTime.setThumbImage(#imageLiteral(resourceName: "ic_dot_circle").resizeImageWith(newSize: CGSize(width: 10, height: 10)).tint(with: #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)), for: .highlighted)
        
        iconFullScreen.image = #imageLiteral(resourceName: "ic_fullscreen").withRenderingMode(.alwaysTemplate)
        iconFullScreen.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        iconPlay.image = #imageLiteral(resourceName: "ic_pause").withRenderingMode(.alwaysTemplate)
        iconPlay.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        // add event for slide
        sliderSeekTime.addTarget(self, action: #selector(sliderBeganTracking),
                                 for: .touchDown)
        sliderSeekTime.addTarget(self, action: #selector(sliderEndedTracking),
                                 for: [.touchUpInside, .touchUpOutside])
        sliderSeekTime.addTarget(self, action: #selector(sliderValueChanged),
                                 for: .valueChanged)
        sliderSeekTime.value = 0
    }
    
    fileprivate func stopTimerCheckPlayingVideo() {
        if timerCheckPlayerStop != nil {
            if timerCheckPlayerStop!.isValid {
                timerCheckPlayerStop?.invalidate()
            }
        }
    }
    
    private func startUpdateValueSlider() {
        currentTimeVideo = 0
        lastTime = 0
        if displayLinkUpdateSliderValue != nil {
            displayLinkUpdateSliderValue?.invalidate()
            displayLinkUpdateSliderValue = nil
        }
        displayLinkUpdateSliderValue = CADisplayLink(target: self, selector: #selector(updateSliderValue(_:)))
        displayLinkUpdateSliderValue?.add(to: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
    }
    
    @objc private func updateSliderValue(_ displayLink: CADisplayLink) {
        guard let displayLink = displayLinkUpdateSliderValue else {
            return
        }
        
        // get the current time
        let currentTime = displayLink.timestamp
        
        var delta: CFTimeInterval = currentTime - lastTime
        if lastTime == 0 {
            delta = displayLink.duration
        }
        lastTime = currentTime
        currentTimeVideo += delta
        
        self.layoutIfNeeded()
        lbltime.frame = CGRect(origin: setUISliderThumbValueWithLabel(slider: sliderSeekTime), size: lbltime.frame.size)
        // calculate delta (
        sliderSeekTime.setValue(Float(currentTimeVideo/videoDuration), animated: true)
    }
    
    fileprivate func setUISliderThumbValueWithLabel(slider: UISlider) -> CGPoint {
        let slidertTrack : CGRect = slider.trackRect(forBounds: slider.bounds)
        let sliderFrm : CGRect = slider .thumbRect(forBounds: slider.bounds, trackRect: slidertTrack, value: slider.value)
        var x = sliderFrm.origin.x + slider.frame.origin.x
        if x + lbltime.frame.size.width/2 > slider.frame.maxX {
            x = slider.frame.maxX - lbltime.frame.size.width/2
        }
        return CGPoint(x: x, y: slider.superview!.frame.origin.y - 20)
    }
}
