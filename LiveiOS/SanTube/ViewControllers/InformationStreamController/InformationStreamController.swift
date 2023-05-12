//
//  InformationStreamController.swift
//  SanTube
//
//  Created by Dai Pham on 12/28/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import SocketIO

let kOFFSET_FOR_KEYBOARD:CGFloat = 170
let kHEIGHT_TABLEVIEW:CGFloat = 250


class InformationStreamController: UIViewController {

    let socket = SocketIOClient(socketURL: URL(string: socket_server)!, config: [.log(true), .forceWebsockets(true)])
    
    var room: Room!
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(emitOrderSuccess), name: NSNotification.Name("App::emitOrderSuccess"), object: nil)
        config()
        registerAction()
        loadOrder()
        loadDetailStream()
        checkStreamOwned()
        checkFollow()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {
            view.removeConstraint(self.topConstraintBtnClose)
            view.removeConstraint(self.topConstaintStackviewInfor)
            self.topConstraintBtnClose = iconClose.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 7)
            self.topConstaintStackviewInfor = stackInfor.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10)
            
            view.addConstraint(self.topConstraintBtnClose)
            view.addConstraint(self.topConstaintStackviewInfor)
        }
        
//        if isShowingShowcase || AppConfig.showCase.isShowTutorial(with: VIEW_STREAM_SCENE) || timerCheckingShouldStartShowcase != nil {return}
//        timerCheckingShouldStartShowcase = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {[weak self] timer in
//            guard let _self = self else {return}
//            print("START CHECKING SHOULD START SHOWCASE VIEW STREAM")
//            if let start = _self.shouldStartShowcase?() {
//                if start && !_self.btnOrder.isHidden {
//                    _self.timerCheckingShouldStartShowcase?.invalidate()
//                    _self.timerCheckingShouldStartShowcase = nil
//                    _self.checkNextTutorial()
//                }
//            }
//        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        iconClose.addEvent {
            self.onShouldClose?()
        }
        
        registerAction()
        
        NotificationCenter.default.addObserver(self, selector: #selector(getNotificationFromCustom(_:)), name: NSNotification.Name("App:CustomControlMediaDidHide"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
        tapgesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        tapgesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(tapgesture)
        
        guard let stream = self.stream else { return }
        load(stream)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        iconClose.removeEvent()
        lblActionFollow.removeEvent()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("App:CustomControlMediaDidHide"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        view.removeGestureRecognizer(tapgesture)
        view.endEditing(true)
        
        if timerCheckSendComment != nil {
            timerCheckSendComment.invalidate()
        }
        if timerUpdateTimeLive != nil {
            timerUpdateTimeLive.invalidate()
        }
        if timerAnimation != nil {
            timerAnimation.invalidate()
        }
        socket.disconnect()
    }
    
    func handlingSocket(){
        guard let user = Account.current else {
            return
        }
        socket.disconnect()
        room = Room(dict: [
            "user_id": user.id as AnyObject ,
            "stream_id": self.stream?.id as AnyObject,
            "api_token": user.api_token as AnyObject
            ])
        socket.connect()
        socket.on("connect") {[weak self] data, ack in
            guard let _self = self else {
                return
            }
            _self.socket.emit("join_stream", _self.room.toDict())
        }
        if let str = self.stream {
            if str.status == AppConfig.status.stream.streaming() {
                socket.on("num_of_views") {[weak self] data, ack in
                    guard let _self = self else {
                        return
                    }
                    let num = data[0] as? Int64
                    _self.btnViews.setTitle(num?.toNumberStringView(false), for: .normal)
                }
            }
        }
        socket.on("num_of_likes") {[weak self] data, ack in
            guard let _self = self else {
                return
            }
             let num = data[0] as? Int64
            if let num  = num{
                _self.btnLike.setTitle(num.toNumberStringView(false), for: .normal)
            } else {
                _self.btnLike.setTitle("0", for: .normal)
            }
        }
        socket.on("update_public_quantity") {[weak self] data, ack in
            guard let _self = self else {
                return
            }
            
            if let data = data[0] as? [JSON], let stream = _self.stream {
                let listProducts = stream.products
                var updatedProdcts:[Product] = []
                for item in data {
                    for pro in listProducts {
                        if let id = item["productId"] as? Int, let sale = item["noOfSell"] as? Int {
                            if Int(pro.id) == id {
                                var product = pro
                                product.noOfSell = sale
                                updatedProdcts.append(product)
                            }
                        } else if let id = item["productId"] as? String, let sale = item["noOfSell"] as? String {
                            if pro.id == id {
                                var product = pro
                                product.noOfSell = Int(sale)!
                                updatedProdcts.append(product)
                            }
                        } else if let id = item["productId"] as? Int, let sale = item["noOfSell"] as? String {
                            if Int(pro.id) == id {
                                var product = pro
                                product.noOfSell = Int(sale)!
                                updatedProdcts.append(product)
                            }
                        } else if let id = item["productId"] as? String, let sale = item["noOfSell"] as? Int {
                            if pro.id == id {
                                var product = pro
                                product.noOfSell = sale
                                updatedProdcts.append(product)
                            }
                        }
                    }
                }
                
                _self.stream?.products = updatedProdcts
                NotificationCenter.default.post(name: NSNotification.Name("App:NeedUpdatedQuanityProduct"), object: nil)
            }
            print("==> \(data)")
        }
        socket.on("stream_stoped") {[weak self] data, ack in
            guard let _self = self else {
                return
            }
            
            // show the alert
            _self.onShouldPresentMessage?("this_video_has_been_stop".localized())
 
        }
    }
    
    deinit {
        print("InformationStreamController dealloc")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("App::emitOrderSuccess"), object: nil)
        if self.timerCheckSendComment != nil {
            self.timerCheckSendComment.invalidate()
        }
        if timerAnimation != nil {
            self.timerAnimation.invalidate()
        }
        if timerCheckIsCheckingOrder != nil {
            self.timerCheckIsCheckingOrder?.invalidate()
            self.timerCheckIsCheckingOrder = nil
        }
        
        self.timerUpdateTimeLive.invalidate()
        
        self.timerCheckingShouldStartShowcase?.invalidate()
        self.timerCheckingShouldStartShowcase = nil
    }
    
    // MARK: - api
    func load(_ stream:Stream) {
        self.stream = stream
        
        loadOrder()
        loadDetailStream()
        
        handlingSocket()
        
        if let stream = self.stream {
            let time = Date().timeIntervalSince((stream.startTime).toDate2())
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            formatter.dateFormat = time > 60*60 ? "HH:mm:ss" : "mm:ss"
            
            self.btnTime.setTitle(formatter.string(from: Date(timeIntervalSince1970: (time))), for: UIControlState())
            self.btnTime.isHidden = stream.status != AppConfig.status.stream.streaming()
            self.btnRelated.isHidden = stream.status == AppConfig.status.stream.streaming()
            
            if stream.status != AppConfig.status.stream.streaming() {
                loadRelatedVideos()
            }
        }
        
        if timerUpdateTimeLive != nil {
            timerUpdateTimeLive.invalidate()
        }
        timerUpdateTimeLive = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            if let stream = self.stream {
                let time = Date().timeIntervalSince((stream.startTime).toDate2())
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                formatter.dateFormat = time > 60*60 ? "HH:mm:ss" : "mm:ss"
                self.btnTime.setTitle(formatter.string(from: Date(timeIntervalSince1970: (time))), for: UIControlState())
                
            }
        }
        
        self.btnViews.setTitle(stream.noOfViews.toNumberStringView(false), for: .normal)
        self.btnLike.setTitle(stream.noOfLikes.toNumberStringView(false), for: .normal)
        self.btnOrder.isHidden = stream.products.count == 0
        
        self.btnUser.setTitle(stream.user.name, for: UIControlState())
        UIImageView().loadImageUsingCacheWithURLString(stream.user.avatar, size: nil, placeHolder: nil, false) {[weak self] (image) in
            guard let _self = self, let img = image else {return}
            _self.btnUser.setImage(img.resizeImageWith(newSize: CGSize(width: 25, height: 25)), for: UIControlState())
            _self.btnUser.imageView?.layer.masksToBounds = true
            _self.btnUser.imageView?.layer.cornerRadius = 12.5
        }
    }
    
    func emitOrderSuccess() {
        // emit socket update quantity products
        socket.emit("buy_product", self.room.toDict())
        
        // check user has ordered
        loadOrder()
    }
    
    func updateDuration(duration:Int) {
        btnTime.setTitle("\(duration)", for: UIControlState())
    }
    
    // MARK: - event
    private func registerAction() {
        lblActionFollow.addEvent {
            
            guard let stream = self.stream, let user = Account.current else {return}
            
            if user.is_guest {
                Support.notice(title: "notice".localized().capitalizingFirstLetter(), message: "please_login_to_use_this_function".localized().capitalizingFirstLetter(), vc: self, ["cancel".localized().capitalizingFirstLetter(),"login".localized().capitalizingFirstLetter()], {[weak self] action in
                    guard let _self = self else {return}
                    if action.title == "login".localized().capitalizingFirstLetter() {
                        let vc = AuthenticController(nibName: "AuthenticController", bundle: Bundle.main)
                        vc.shouldGotoStreamAfterLogin = true
                        vc.onQuitStreamToo = {[weak _self] in
                            guard let _self = _self else {return}
                            // reload data for this view
                            _self.handlingSocket()
                            _self.loadDetailStream()
                            _self.loadOrder()
                            _self.checkStreamOwned()
                            _self.checkFollow()
                        }
                        let nv = UINavigationController(rootViewController: vc)
                        _self.parent?.present(nv, animated: true)
                    }
                })
                return
            }
            
            loadingFollow.isHidden = false
            loadingFollow.startAnimating()
            lblActionFollow.isHidden = true
            Server.shared.actionFollow(followerId: stream.user.id, followingId: user.id, unFollow: btnFollow.isSelected, {[weak self] (done, msgErr) in
                guard let _self = self else {return}
                if let msg = msgErr {
                    Support.notice(title: "notice".localized().capitalizingFirstLetter(),
                                   message: msg, vc: _self, ["ok".localized().uppercased()], nil)
                } else {
                    _self.checkFollow()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App::UserActionFollow"), object: nil)
                }
            })
        }
    }
    
    func doubleTap(_ sender:UITapGestureRecognizer) {
        guard let str = self.stream else {
            view.removeGestureRecognizer(sender)
            return
        }
        if str.status == AppConfig.status.stream.streaming() {
            view.removeGestureRecognizer(sender)
            return
        }
        
        if !vwMoreAction.isHidden || !vwRelatedVideos.isHidden {
            return
        }
  
        if let parent = self.parent as? DetailStreamController {
            if let presentVideoController = parent.streamVideoController {
                if presentVideoController.customControlMedia != nil {
                    if !presentVideoController.customControlMedia.transform.isIdentity {
                        presentVideoController.hideCustomMediaControl(false, isForce: false) {[weak self] isHide in
                            guard let _self = self else {return}
                            _self.showControl(isShow: isHide)
                        }
                    } else {
                        self.showControl(isShow:false) {
                            presentVideoController.hideCustomMediaControl(true, isForce: true) {[weak self] isHide in
                                guard let _self = self else {return}
                                _self.showControl(isShow: isHide)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func touchButton(sender:UIButton) {
        guard let user = Account.current else {
            return
        }
        
        // check user is guest
        if sender.isEqual(btnLike) ||
            sender.isEqual(btnReport) ||
            sender.isEqual(btnFollow) ||
            sender.isEqual(btnOrder) {
            if user.is_guest {
                Support.notice(title: "notice".localized().capitalizingFirstLetter(), message: "please_login_to_use_this_function".localized().capitalizingFirstLetter(), vc: self, ["cancel".localized().capitalizingFirstLetter(),"login".localized().capitalizingFirstLetter()], {[weak self] action in
                    guard let _self = self else {return}
                    if action.title == "login".localized().capitalizingFirstLetter() {
                        let vc = AuthenticController(nibName: "AuthenticController", bundle: Bundle.main)
                        vc.shouldGotoStreamAfterLogin = true
                        vc.onQuitStreamToo = {[weak _self] in
                            guard let _self = _self else {return}
                            // reload data for this view
                            _self.handlingSocket()
                            _self.loadDetailStream()
                            _self.loadOrder()
                            _self.checkStreamOwned()
                            _self.checkFollow()
                        }
                        let nv = UINavigationController(rootViewController: vc)
                        _self.parent?.present(nv, animated: true)
                    }
                })
                return
            }
        }
        
        if sender.isEqual(btnRelated) {
            showRelatedVideos(isShow: true)
            return
        }
        
        if sender.isEqual(btnOrder) {
            if isCheckingOrder {
                sender.startAnimation(activityIndicatorStyle: .gray)
                if timerCheckIsCheckingOrder != nil {
                    timerCheckIsCheckingOrder?.invalidate()
                }
                timerCheckIsCheckingOrder = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: {[weak self] timer in
                    guard let _self = self else {return}
                    if !_self.isCheckingOrder {
                        _self.timerCheckIsCheckingOrder?.invalidate()
                        _self.timerCheckIsCheckingOrder = nil
                        
                        _self.gotoChooseOrderItem(_self.listOrders.count > 0)
                    }
                })
                return
            }
            
            gotoChooseOrderItem(self.listOrders.count > 0)
        } else if sender.isEqual(btnSendLike) {
            
            if sender.isSelected != true {
                self.socket.emit("up_like", self.room.toDict())
            }else{
                self.socket.emit("un_like", self.room.toDict())
            }
            sender.isSelected = !sender.isSelected
        } else if sender.isEqual(btnOption) {
            
            showMoreAction(isShow: true)
            
        } else if sender.isEqual(btnReport) {
            UIView.animate(withDuration: 0.3, animations: {
                self.vwMoreAction.transform = CGAffineTransform(translationX: 0, y: self.vwMoreAction.frame.size.height + 40)
            }, completion: { (done) in
                if !done {return}
                let vc = ReportStreamController(nibName: "ReportStreamController", bundle: Bundle.main)
                vc.stream = self.stream
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: {timer in
                    print("CHECK PRESENTING IS DEALLOC")
                    if self.parent?.presentedViewController == nil {
                        timer.invalidate()
//                        self.showControl(isShow: false) {
                            self.parent?.present(vc, animated: false, completion: nil)
//                        }
                    }
                })
                vc.onDissmiss = {[weak self] in
                    guard let _self = self else {return}
                    _self.showControl(isShow: true)
                }
                vc.onReportSuccess = {[weak self] in
                    guard let _self = self else {return}
                    _self.showControl(isShow: true)
                    let textfield = UITextField(frame: _self.view.bounds)
                    textfield.textAlignment = .center
                    textfield.text = "     \("report_success".localized().capitalizingFirstLetter())     "
                    textfield.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    textfield.font = UIFont.boldSystemFont(ofSize: fontSize17)
                    textfield.layer.masksToBounds = true
                    textfield.layer.cornerRadius = 10
                    textfield.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.71)
                    textfield.alpha = 0
                    
                    _self.view.addSubview(textfield)
                    textfield.translatesAutoresizingMaskIntoConstraints = false
                    textfield.centerXAnchor.constraint(equalTo: _self.view.centerXAnchor).isActive = true
                    textfield.centerYAnchor.constraint(equalTo: _self.view.centerYAnchor).isActive = true
                    textfield.heightAnchor.constraint(equalToConstant: 50).isActive = true
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        textfield.alpha = 1
                    }, completion: {done in
                        if !done {return}
                        UIView.animate(withDuration: 3, animations: {
                            textfield.alpha = 0.95
                        }, completion: {done in
                            if done {textfield.removeFromSuperview()}
                        })
                    })
                }
            })
            
        } else if sender.isEqual(btnFollow) {
            guard let stream = self.stream else {return}
            loadingFollow.isHidden = false
            loadingFollow.startAnimating()
            btnFollow.isHidden = true
            Server.shared.actionFollow(followerId: stream.user.id, followingId: user.id, unFollow: btnFollow.isSelected, {[weak self] (done, msgErr) in
                guard let _self = self else {return}
                if let msg = msgErr {
                    Support.notice(title: "notice".localized().capitalizingFirstLetter(),
                                   message: msg, vc: _self, ["ok".localized().uppercased()], nil)
                } else {
                    _self.checkFollow()
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App::UserActionFollow"), object: nil)
                }
            })
        }
    }

    func closeRelatedVideo(_ sender:UIButton) {
        showRelatedVideos(isShow: false)
    }
    
    func closeMorAction(_ sender:UIButton) {
        showMoreAction(isShow: false)
    }
    
    // MARK: - private
    private func gotoChooseOrderItem(_ isEdit:Bool = false) {
        
        guard let stream = stream, let user = Account.current else {return}
        
        let vc = SelectOrderItemController(nibName: "SelectOrderItemController", bundle: Bundle.main)
        vc.type = isEdit ? .edit : .new
        vc.delegate = self
        
        var order = Order()
        
        order.streamId = stream.id
        order.sellerId = stream.user.id
        order.buyerId = user.id
        order.status = AppConfig.status.order.create_new()
        order.products = stream.products
        
        if isEdit /* order has existed, load again to change state edit for next view*/{
            
            // set order is last order with products only selected
            order = listOrders.last!
            for item in stream.products {
                for (i,item1) in order.products.enumerated() {
                    if item.id == item1.id {
                        var pro = item1
                        pro.noOfSell = item.noOfSell
                        pro.limitPerPerson = item.limitPerPerson
                        order.products[i] = pro
                    }
                }
            }
            
            // append another products of Stream
            for item in stream.products {
                if !order.products.contains(where: { (pro) -> Bool in
                    return pro.id == item.id
                }) {
                    order.products.append(item)
                }
            }
        }
        
        vc.order = order
        
        let nv = UINavigationController(rootViewController: vc)
        Support.topVC!.present(nv, animated: false, completion: nil)
    }
    
    private func loadOrder() {
        
        guard let stream = self.stream, let user = Account.current else { return }
        
        //check if stream not products to sales, hide the button order
        isCheckingOrder = true
        let currentDate = Date()
        let yesterday = Date().addingTimeInterval(-60*60*24)
        Server.shared.getOrders(streamId: stream.id,
                                buyerId: user.id,
                                sellerId: stream.user.id,
                                status: nil,
                                fromDate: yesterday.toString(dateFormat: "yyyy-MM-dd").appending(" 00:00:00"),
                                toDate: currentDate.toString(dateFormat: "yyyy-MM-dd").appending(" 23:59:59"), page: 1) {[weak self] (orders, err) in
                                    guard let _self = self else {return}
                                    _self.isCheckingOrder = false
                                    guard let orders = orders else {
                                        _self.btnOrder.setChecked(false)
                                        return
                                    }
                                    _self.listOrders = orders
                                    _self.btnOrder.setChecked(orders.count > 0)
                                    
        }
    }
    
    private func loadDetailStream() {
        guard let stream = self.stream, let user = Account.current else { return }
        Server.shared.getStream(streamId: stream.id,
                                userId: user.id) {[weak self] (str, err) in
                                    if err != nil {return}
                                    guard let _self = self else {return}
                                    if let str = str {
//                                        _self.stream = str
                                        _self.btnSendLike.isSelected = str.isLiked
                                        if str.status == AppConfig.status.stream.streaming() {
                                            _self.btnViews.setTitle(str.noOfViews.toNumberStringView(false), for: .normal)
                                            _self.btnLike.setTitle(str.noOfLikes.toNumberStringView(false), for: .normal)
                                            _self.btnOrder.isHidden = str.products.count == 0
                                        }
                                    }
        }
    }
    
    private func checkStreamOwned() {
        guard let user = Account.current, let stream = self.stream else { return }
        lblActionFollow.isHidden = user.id == stream.user.id
    }
    
    private func checkFollow() {
        guard let user = Account.current, let stream = self.stream, !user.is_guest, user.id != stream.user.id else { return }
        Server.shared.checkFollow(followerId: stream.user.id,
                                  followingId: user.id) {[weak self] (done, msgErr) in
                                    guard let _self = self else {return}
                                    if let msg = msgErr {
                                        Support.notice(title: "notice".localized().capitalizingFirstLetter(),
                                                       message: msg, vc: _self, ["ok".localized().uppercased()], nil)
                                    } else {
                                        guard let done = done else {return}
                                        _self.btnFollow.isSelected = done
                                        _self.btnFollow.layer.borderColor =  (!done ? #colorLiteral(red: 0.9882352941, green: 0.8078431373, blue: 0.1843137255, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)).cgColor
                                        
                                        _self.lblActionFollow.text = (!done ? "  \("follow".localized().capitalizingFirstLetter())  " : "  \("unfollow".localized().capitalizingFirstLetter())  ")
                                        
                                        _self.lblActionFollow.textColor = (!done ? #colorLiteral(red: 0.9882352941, green: 0.8078431373, blue: 0.1843137255, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
                                        _self.lblActionFollow.layer.borderColor = (!done ? #colorLiteral(red: 0.9882352941, green: 0.8078431373, blue: 0.1843137255, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
                                        
                                    }
                                    _self.loadingFollow.isHidden = true
                                    _self.lblActionFollow.isHidden = false
                                    _self.loadingFollow.stopAnimating()
        }
    }
    
    private func loadRelatedVideos() {
        
        if !vwRelatedVideos.isHidden {
            showRelatedVideos(isShow: false)
        }
        
        guard let obj = self.stream else {
            btnRelated.isHidden = true
            return
        }
        guard let cate = obj.categories.first else {
            btnRelated.isHidden = true
            return
        }
        
        Server.shared.getStreams(user_id: nil, category_ids: [cate.id], isFeatured: false, page: 1, pageSize: 20, sortBy: "created_at") { [weak self] result in
            guard let _self = self else {return}
            _self.view.stopLoading()
            switch result  {
            case .success(let list):
                
                let data = list.flatMap{Stream.parse(from:$0)}.filter{$0.id != _self.stream!.id}
                
                if data.count == 0 {
                    _self.btnRelated.isHidden = true
                    return
                }
                for item in _self.stackRelatedVideos.arrangedSubviews.reversed() {
                    item.removeFromSuperview()
                }
                
                for item in data {
                    let cv = Bundle.main.loadNibNamed("RelatedVideoBlockView", owner: self, options: [:])?.first as! RelatedVideoBlockView
                    cv.load(data: item)
                    cv.onSelectObject = {[weak _self] object in
                        guard let _self = _self else {return}
                        _self.onReloadOfflineStream?(object)
                    }
                    _self.stackRelatedVideos.addArrangedSubview(cv)
                    cv.translatesAutoresizingMaskIntoConstraints = false
                    let width:CGFloat = 120
                    cv.widthAnchor.constraint(equalToConstant: width).isActive = true
                    cv.heightAnchor.constraint(equalToConstant: width * 1.4).isActive = true
                }
                
            case .failure(_):
                _self.btnRelated.isHidden = true
                break
            }
        }
    }
    
    private func showControl(isShow:Bool,_ completion:(()->Void)? = nil) {
        if !vwRelatedVideos.isHidden {
            vwRelatedVideos.transform = .identity
            vwRelatedVideos.isHidden = true
        }
        if !vwMoreAction.isHidden {
            vwMoreAction.transform = .identity
            vwMoreAction.isHidden = true
        }
        
        if isShow {
            UIView.animate(withDuration: 0.3, animations: {
                self.vwControls.transform = .identity
            }, completion: { (done) in
                if done {
                    completion?()
                }
            })
            
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.vwControls.transform = CGAffineTransform(translationX: 0, y: self.vwControls.frame.size.height + 40)
            }, completion: { (done) in
                if done {
                   completion?()
                }
            })
        }
    }
    
    private func showRelatedVideos(isShow:Bool) {
        if isShow {
            vwRelatedVideos.transform = CGAffineTransform(translationX: 0, y: vwRelatedVideos.frame.size.height + 40)
            vwRelatedVideos.isHidden = false
            
            UIView.animate(withDuration: 0.3, animations: {
                self.vwControls.transform = CGAffineTransform(translationX: 0, y: 80)
            }, completion: { (done) in
                if done {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.vwRelatedVideos.transform = .identity
                    })
                }
            })
            
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.vwRelatedVideos.transform = CGAffineTransform(translationX: 0, y: self.vwRelatedVideos.frame.size.height + 40)
            }, completion: { (done) in
                if done {
                    self.vwRelatedVideos.isHidden = true
                    UIView.animate(withDuration: 0.3, animations: {
                        self.vwControls.transform = .identity
                    })
                }
            })
        }
    }
    
    private func showMoreAction(isShow:Bool) {
        if isShow {
            vwMoreAction.transform = CGAffineTransform(translationX: 0, y: vwMoreAction.frame.size.height + 40)
            vwMoreAction.isHidden = false
            
            UIView.animate(withDuration: 0.3, animations: {
                self.vwControls.transform = CGAffineTransform(translationX: 0, y: 80)
            }, completion: { (done) in
                if done {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.vwMoreAction.transform = .identity
                    })
                }
            })
            
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.vwMoreAction.transform = CGAffineTransform(translationX: 0, y: self.vwMoreAction.frame.size.height + 40)
            }, completion: { (done) in
                if done {
                    self.vwMoreAction.isHidden = true
                    UIView.animate(withDuration: 0.3, animations: {
                        self.vwControls.transform = .identity
                    })
                }
            })
        }
    }
    
    private func config() {
        _ = [btnLike,btnTime,btnViews,btnSendLike,btnComment,btnComment,btnRelated,btnOrder,btnOption].map{setupCommonButton(button: $0)}
        
        // add action for button
        btnSendLike.addTarget(self, action: #selector(touchButton), for: UIControlEvents.touchUpInside)
        btnOrder.addTarget(self, action: #selector(touchButton), for: UIControlEvents.touchUpInside)
        btnOption.addTarget(self, action: #selector(touchButton), for: UIControlEvents.touchUpInside)
        btnComment.addTarget(self, action: #selector(touchButton), for: UIControlEvents.touchUpInside)
        btnRelated.addTarget(self, action: #selector(touchButton), for: UIControlEvents.touchUpInside)
        
        if UIScreen.main.bounds.size.width <= 320 {
            btnSendLike.setImage(#imageLiteral(resourceName: "ic_unlove").resizeImageWith(newSize: CGSize(width: 20, height: 20)).withRenderingMode(.alwaysTemplate).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: .normal)
            btnSendLike.setImage(#imageLiteral(resourceName: "ic_love").resizeImageWith(newSize: CGSize(width: 20, height: 20)).withRenderingMode(.alwaysTemplate).tint(with: #colorLiteral(red: 0.231372549, green: 0.3490196078, blue: 0.5960784314, alpha: 1)), for: .selected)
            btnSendLike.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        } else {
            btnSendLike.setImage(#imageLiteral(resourceName: "ic_unlove").resizeImageWith(newSize: CGSize(width: 25, height: 25)).withRenderingMode(.alwaysTemplate).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: .normal)
            btnSendLike.setImage(#imageLiteral(resourceName: "ic_love").resizeImageWith(newSize: CGSize(width: 25, height: 25)).withRenderingMode(.alwaysTemplate).tint(with: #colorLiteral(red: 0.231372549, green: 0.3490196078, blue: 0.5960784314, alpha: 1)), for: .selected)
            btnSendLike.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        }
        
        btnOrder.setImage(UIImage(named: "ic_cart_128")?.tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
        
        
        btnViews.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7122304137)
        btnLike.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7122304137)
        btnSendLike.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7122304137)
        btnComment.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7122304137)
        btnRelated.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7122304137)
        btnOption.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7122304137)
        btnOrder.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7122304137)
        
        _ = [btnComment,btnRelated,btnOrder,btnOption].map{resizeImageButton(button: $0)}
        
        if let str = self.stream {
            btnOrder.isHidden = str.products.count == 0
            startAnimations()
        }
        
        lblRelatedVideo.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lblRelatedVideo.font = UIFont.boldSystemFont(ofSize: fontSize20)
        lblRelatedVideo.text = "related_videos".localized()
        
        vwRelatedVideos.layer.masksToBounds = true
        vwRelatedVideos.layer.cornerRadius = 5
        
        btnCloseRelatedVideos.addTarget(self, action: #selector(closeRelatedVideo(_:)), for: .touchUpInside)
        
        // more action config
        
        vwMoreAction.layer.masksToBounds = true
        vwMoreAction.layer.cornerRadius = 5
        
        btnUser.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: UIControlState())
        btnUser.titleLabel?.font = UIFont.systemFont(ofSize: fontSize17)
        btnUser.setImage(UIImage(named: "ic_profile")?.tint(with: #colorLiteral(red: 0.4588235294, green: 0.4588235294, blue: 0.4588235294, alpha: 1)), for: UIControlState())
        
        btnReport.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: UIControlState())
        btnReport.titleLabel?.font = UIFont.systemFont(ofSize: fontSize17)
        btnReport.setImage(#imageLiteral(resourceName: "ic_report").resizeImageWith(newSize: CGSize(width: 25, height: 25)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
        btnReport.setTitle("report".localized().capitalizingFirstLetter(), for: UIControlState())
        
        btnUser.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: UIControlState())
        btnUser.titleLabel?.font = UIFont.systemFont(ofSize: fontSize17)
        
        btnFollow.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .selected)
        btnFollow.setTitleColor(#colorLiteral(red: 0.9882352941, green: 0.8078431373, blue: 0.1843137255, alpha: 1), for:.normal)
        btnFollow.titleLabel?.font = UIFont.systemFont(ofSize: fontSize15)
        lblActionFollow.font = UIFont.systemFont(ofSize: fontSize15)
        
        lblActionFollow.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lblActionFollow.layer.masksToBounds = true
        lblActionFollow.layer.cornerRadius = 3
        lblActionFollow.layer.borderWidth = 1
        lblActionFollow.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lblActionFollow.text = "  \("follow".localized().capitalizingFirstLetter())  "
        
        btnFollow.setTitle("follow".localized().capitalizingFirstLetter(), for: .normal)
        btnFollow.setTitle("unfollow".localized().capitalizingFirstLetter(), for: .selected)
        
        btnFollow.layer.masksToBounds = true
        btnFollow.layer.cornerRadius = 3
        btnFollow.layer.borderWidth = 1
        btnFollow.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        loadingFollow.stopAnimating()
        loadingFollow.isHidden = true
        btnFollow.isHidden = true
        
        btnCloseMoreAction.addTarget(self, action: #selector(closeMorAction(_:)), for: .touchUpInside)
        btnCloseMoreAction.setImage(UIImage(named:"close_preview")?.resizeImageWith(newSize: CGSize(width: 10, height: 10)), for: UIControlState())
        btnFollow.addTarget(self, action: #selector(touchButton(sender:)), for: .touchDown)
        btnReport.addTarget(self, action: #selector(touchButton(sender:)), for: .touchUpInside)
    }
    
    private func startAnimations() {
        if timerAnimation != nil {
            timerAnimation.invalidate()
        }
        timerAnimation = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { (timer) in
            let options: UIViewKeyframeAnimationOptions = [.curveLinear,.allowUserInteraction]
            UIView.animateKeyframes(withDuration: 5, delay: 0, options: options, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform(translationX: 2, y: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.605, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform(translationX: -2, y: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.610, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform(translationX: 2, y: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.615, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform(translationX: -2, y: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.620, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform(translationX: 2, y: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.625, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform(translationX: -2, y: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.630, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform(translationX: 2, y: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.635, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform(translationX: -2, y: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.640, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform(translationX: 2, y: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.645, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform(translationX: -2, y: 0)
                })
                UIView.addKeyframe(withRelativeStartTime: 0.650, relativeDuration: 0.05, animations: {
                    self.btnOrder.transform = CGAffineTransform.identity
                })
            }, completion: nil)
        }
    }
    
    private func resizeImageButton(button:UIButton) {
        if let image = button.image(for: UIControlState()) {
            if UIScreen.main.bounds.size.width <= 320 {
                button.setImage(image.resizeImageWith(newSize: CGSize(width: 20, height: 20)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
                if button.isEqual(btnComment) || button.isEqual(btnRelated) {
                    button.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 5)
                } else {
                    button.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
                }
                
            } else {
                button.setImage(image.resizeImageWith(newSize: CGSize(width: 25, height: 25)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
            }
        }
    }
    
    private func setupCommonButton(button:UIButton) {
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 4
        if let image = button.image(for: UIControlState()) {
            button.setImage(image.withRenderingMode(.alwaysTemplate), for: UIControlState())
            button.imageView?.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        button.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: UIControlState())
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize15)
    }
    
    func keyboardWillChangeFrame(notification:NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            var mix:CGFloat = 0
            if let parent = self.parent {
                if let tabbar = parent.tabBarController {
                    mix = tabbar.tabBar.frame.size.height
                }
            }
            if #available(iOS 11.0,*) {
                heightkeyboard = keyboardRectangle.height - mix - view.safeAreaInsets.bottom
            } else {
                heightkeyboard = keyboardRectangle.height - mix
            }
        }
    }
    
    func keyboardWillShow(notification:NSNotification) {
    }
    
    func keyboardWillHide(notification:NSNotification) {
        
        view.endEditing(true)
        
    }
    
    func getNotificationFromCustom(_ notification:NSNotification) {
        showControl(isShow: true)
    }
    
    fileprivate func setViewTextFieldMove(isUP:Bool) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.28) {
            self.view.layoutIfNeeded()
        }
    }
    
   
    // MARK: - constraint

    
    // MARK: - properties
    var stream:Stream?
    var listComment:[String] = []
    var heightkeyboard = kOFFSET_FOR_KEYBOARD
    var tapgesture:UITapGestureRecognizer!
    var timerUpdateTimeLive:Timer!
    var timerCheckSendComment:Timer!
    var timerAnimation:Timer!
    var timerCheckIsCheckingOrder:Timer?
    var listOrders:[Order] = []
    var isCheckingOrder:Bool = false
    var isShowingShowcase:Bool = false
    var timerCheckingShouldStartShowcase:Timer?
    
    // MARK: - closure
    var onShouldClose:(()->Void)?
    var onShouldPresentMessage:((String)->Void)?
    var shouldStartShowcase:(()->Bool)?
    var onReloadOfflineStream:((Stream)->Void)?
    
    // MARK: - outlet
    @IBOutlet weak var iconClose: UIImageView!
    @IBOutlet weak var btnTime: UIButton!
    @IBOutlet weak var btnLike: UIButton!
    @IBOutlet weak var btnViews: UIButton!
    @IBOutlet weak var btnSendLike: UIButton!
    @IBOutlet weak var btnOrder: UIButton!
    @IBOutlet weak var btnOption: UIButton!
    @IBOutlet weak var topConstaintStackviewInfor: NSLayoutConstraint!
    @IBOutlet weak var topConstraintBtnClose: NSLayoutConstraint!
    @IBOutlet weak var stackInfor: UIStackView!
    @IBOutlet weak var btnComment: UIButton!
    @IBOutlet weak var btnRelated: UIButton!
    @IBOutlet weak var stackButtons: UIStackView!
    @IBOutlet weak var vwControls: UIView!
    @IBOutlet weak var btnCloseRelatedVideos: UIButton!
    
    
    // related Videos
    @IBOutlet weak var vwRelatedVideos: UIView!
    @IBOutlet weak var lblRelatedVideo: UILabel!
    @IBOutlet weak var stackRelatedVideos: UIStackView!
    
    // more action
    @IBOutlet weak var vwMoreAction: UIView!
    @IBOutlet weak var btnUser: UIButton!
    @IBOutlet weak var btnFollow: UIButton!
    @IBOutlet weak var lblActionFollow: UILabel!
    @IBOutlet weak var loadingFollow: UIActivityIndicatorView!
    @IBOutlet weak var btnReport: UIButton!
    @IBOutlet weak var btnCloseMoreAction: UIButton!
    
}

// MARK: - handle tableview
extension InformationStreamController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! CommentInformationCell
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell1")
//        let listComment = ["What are the man and woman mainly discussing?",
//                           "How is the woman traveling?",
//                           "Why aren't the man and woman going together?",
//                           "What does the man have to do today?",
//                           "What can be inferred from the conversation?",
//                           "What does the woman offer to do for the man?",
//                           "I have a doctor's appointment this afternoon. Are you going to be in the office, or do you have a meeting?",
//                           "I'll be here. And, don't worry. I don't have much on for today, so I'll handle all of your calls",
//                           "Thanks. I'm expecting a call from my lawyer. He's supposed to be sending me some changes to the contracts.",
//                           "I'll make sure to take a detailed message if he calls. Is there anything you want to tell him?",
//                           "Well, you could remind him that I'm going to need to come downtown and sign a few papers in front of him. I'll have to set something up for next week."]
        
        let name = NSMutableAttributedString(string:"\("Peter Nguyen: ")", attributes: [NSFontAttributeName:UIFont.boldSystemFont(ofSize: fontSize14),NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)])
        let comment = NSMutableAttributedString(string: listComment.reversed()[indexPath.row],
                                                attributes: [NSFontAttributeName:UIFont.systemFont(ofSize: fontSize14),
                                                             NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)])
        
        let final = NSMutableAttributedString(attributedString: name)
        final.append(comment)
        cell.textLabel?.attributedText = final
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.layer.masksToBounds = false
        cell.textLabel?.layer.cornerRadius = 4
        cell.textLabel?.backgroundColor = #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1)
        cell.backgroundColor = UIColor.clear
        
        // flip cell
        cell.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        
//        cell.load(listComment[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listComment.count
    }
}

// MARK: - handle SelectedOrdeItem delegate
extension InformationStreamController:SelectOrderItemDelegate {
    func getUpdatedOrderStream(from vc:SelectOrderItemController) -> Order? {
        if self.listOrders.count > 0 {
            var order = self.listOrders.last
            for item in stream!.products {
                for (i,item1) in order!.products.enumerated() {
                    if item.id == item1.id {
                        var pro = item1
                        pro.noOfSell = item.noOfSell
                        pro.limitPerPerson = item.limitPerPerson
                        order!.products[i] = pro
                    }
                }
            }
            return order
        } else {
            for item in stream!.products {
                for (i,item1) in vc.order!.products.enumerated() {
                    if item.id == item1.id {
                        var pro = item1
                        pro.noOfSell = item.noOfSell
                        pro.limitPerPerson = item.limitPerPerson
                        vc.order!.products[i] = pro
                    }
                }
            }
            return vc.order
        }
    }
}

// MARK: - handle textfield
//extension InformationStreamController: UITextFieldDelegate {
//
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        if bottomConstraintvwTextField.constant == 0 {
//            setViewTextFieldMove(isUP: true)
//        }
//    }
//
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        #if DEBUG
//            print("PRESS SEND")
//        #endif
//        if txtComment.text?.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count == 0 {return false}
//        self.listComment.append(txtComment.text!)
//        if self.tableView.contentOffset.y < 100  && self.listComment.count <= 50{
//            self.tableView.beginUpdates()
//            let numberNeedUpdate = self.listComment.count - self.tableView.numberOfRows(inSection: 0)
//            var listIndexPath:[IndexPath] = []
//            for i in 0..<numberNeedUpdate {
//                listIndexPath.append(IndexPath(row: i, section: 0))
//            }
//            self.tableView.insertRows(at: listIndexPath, with: UITableViewRowAnimation.top)
//            self.tableView.endUpdates()
//            self.txtComment.text = ""
//            self.view.endEditing(true)
//        }
//        return true
//    }
//}

// MARK: - ShowCase
extension InformationStreamController: MaterialShowcaseDelegate {
    
    func checkNextTutorial() {
        return
        isShowingShowcase = true
        if !AppConfig.showCase.isShowTutorial(with: VIEW_STREAM_SCENE) {
            startTutorial()
        }
    }
    
    // MARK: - init showcase
    func startTutorial(_ step:Int = 1) {
        // showcase
        configShowcase(MaterialShowcase(), step) { showcase, shouldShow in
            if shouldShow {
                showcase.delegate = self
                showcase.show(completion: nil)
            }
        }
    }
    
    func configShowcase(_ showcase:MaterialShowcase,_ step:Int = 1,_ shouldShow:((MaterialShowcase,Bool)->Void)) {
        if step == 1 {
            showcase.setTargetView(view: self.btnOrder, #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1))
            showcase.primaryText = ""
            showcase.identifier = ORDER_BUTTON_STREAM
            showcase.secondaryText = "click_here_go_to_list_products_page".localized().capitalizingFirstLetter()
            shouldShow(showcase,true)
        } else {
            shouldShow(showcase,false)
            if step > 1 {
                AppConfig.showCase.setFinishShowcase(key: VIEW_STREAM_SCENE)
                checkNextTutorial()
            }
        }
    }
    
    // MARK: - showcase delegate
    func showCaseDidDismiss(showcase: MaterialShowcase) {
        if let step = showcase.identifier {
            if let s = Int(step) {
                let ss = s + 1
                startTutorial(ss)
            }
        }
        
    }
}
