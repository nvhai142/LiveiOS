//
//  CalendarController.swift
//  SanTube
//
//  Created by Dai Pham on 11/29/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class FollowerController: BaseController {

    // MARK: - api
    
    // MARK: - private
    private func addMenuBar() {
        menuBar = Bundle.main.loadNibNamed("ExtendedNavBarView", owner: self, options: nil)?.first as! ExtendedNavBarView
        stackContainer.insertArrangedSubview(menuBar, at: 0)
        menuBar.translatesAutoresizingMaskIntoConstraints = false
        menuBar.heightAnchor.constraint(equalToConstant: navigationController!.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.size.height).isActive = true
        menuBar.controller = self
        menuBar.setTitle("following_stream".localized().capitalizingFirstLetter())
    }
    
    private func openStream(_ streamLocal:Stream) {

        let present = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
        
        if streamLocal.status == AppConfig.status.stream.streaming() {
            let vc = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
            vc.streamVideoController = present
            vc.stream = streamLocal
            vc.onGotoStreamDetail = {[weak self] stream1 in
                guard let _self = self else {return}
                let present1 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                let vc1 = DetailStreamController(nibName: "DetailStreamController", bundle: Bundle.main)
                vc1.streamVideoController = present1
                vc1.stream = stream1
                vc1.onGotoLiveStream = {[weak _self] str in
                    guard let __self = _self else {return}
                    let present2 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                    let vc2 = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
                    vc2.streamVideoController = present2
                    vc2.stream = str
                    vc2.onGotoStreamDetail = {[weak _self] stream1 in
                        guard let _self = _self else {return}
                        let present1 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                        let vc1 = DetailStreamController(nibName: "DetailStreamController", bundle: Bundle.main)
                        vc1.streamVideoController = present1
                        vc1.stream = stream1
                        vc1.onGotoLiveStream = {[weak _self] str in
                            guard let __self = _self else {return}
                            let present2 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                            let vc2 = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
                            vc2.streamVideoController = present2
                            vc2.stream = str
                            __self.tabBarController?.present(vc2, animated: false)
                        }
                        _self.tabBarController?.present(vc1, animated: true)
                    }
                    __self.tabBarController?.present(vc2, animated: false)
                }
                _self.tabBarController?.present(vc1, animated: true)
            }
            self.tabBarController?.present(vc, animated: false)
            return
        }

        let vc = DetailStreamController(nibName: "DetailStreamController", bundle: Bundle.main)
        vc.stream = streamLocal
        vc.streamVideoController = present
        vc.onGotoLiveStream = {[weak self] str in
            guard let _self = self else {return}
            let present = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
            let vc = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
            vc.streamVideoController = present
            vc.stream = str
            _self.present(vc, animated: false)
            vc.onGotoStreamDetail = {[weak _self] stream1 in
                guard let ___self = _self else {return}
                let present1 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                let vc1 = DetailStreamController(nibName: "DetailStreamController", bundle: Bundle.main)
                vc1.streamVideoController = present1
                vc1.stream = stream1
                vc1.onGotoLiveStream = {[weak ___self] str in
                    guard let ____self = ___self else {return}
                    let present2 = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                    let vc2 = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
                    vc2.streamVideoController = present2
                    vc2.stream = str
                    ____self.tabBarController?.present(vc2, animated: false)
                }
                ___self.tabBarController?.present(vc1, animated: true)
            }
        }
        self.tabBarController?.present(vc, animated: true)
    }

    
    private func config() {
        relatedController = RelatedVideoController(nibName: "RelatedVideoController", bundle: Bundle.main)
        relatedController.type = .follower
        self.addChildViewController(relatedController)
        stackContainer.addArrangedSubview(relatedController.view)
        relatedController.onLoadStream = {[weak self] str in
            guard let _self = self else {return}
            _self.openStream(str)
        }
        
        lblNotice.font = UIFont.boldSystemFont(ofSize: fontSize17)
        lblNotice.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        lblNotice.text = "you_dont_have_follower".localized().capitalizingFirstLetter()
        lblNotice.isHidden = true
    }
    
    private func loadFollowingUsers() {
        vwListFollowedUsers.startLoading(isStart: true)
        guard let user = Account.current, !user.is_guest else { return }
        view.startLoading(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        lblNotice.isHidden = true
        Server.shared.getListFollows(userIds: [user.id], isFollowing: true, page: 1) {[weak self] (listUsers, errMSG, morePage) in
            guard let _self = self else {return}
            if let errMsg = errMSG {
                Support.notice(title: "notice".localized().capitalizingFirstLetter(), message: errMsg, vc: _self, ["ok".localized().uppercased()], nil)
            } else {
                _self.vwListFollowedUsers.startLoading(isStart: false)
                _self.view.stopLoading()
                if let list = listUsers {
                    _self.lblNotice.isHidden = list.count > 0
                    _self.vwListFollowedUsers.load(data: list)
                    _self.relatedController.listUserIds = list.flatMap{$0.id}
                } else {
                    _self.lblNotice.isHidden = false
                }
            }
        }
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        config()
        addMenuBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let user = Account.current {
            if user.is_guest && !isShowingLogin{
                isShowingLogin = true
                let vc = AuthenticController(nibName: "AuthenticController", bundle: Bundle.main)
                let nv = UINavigationController(rootViewController: vc)
                self.tabBarController?.present(nv, animated: false)
                vc.onDissmiss = {[weak self] in
                    guard let _self = self, let tabbar = _self.tabBarController else {return}
                    tabbar.selectedIndex = 0
                    _self.isShowingLogin = false
                }
            } else {
                isShowingLogin = false
                loadFollowingUsers()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vwListFollowedUsers.releaseView()
    }
    
    // MARK: - closures
    
    // MARK: - properties
    var relatedController:RelatedVideoController!
    var menuBar:ExtendedNavBarView!
    var isShowingLogin:Bool = false
    
    // MARK: - outlet
    @IBOutlet weak var lblNotice: UILabel!
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var vwListFollowedUsers: FollowedUsersListView!
    
}
