//
//  HomeController.swift
//  BUUP
//
//  Created by Dai Pham on 11/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

let DATA_TO_TOPVIEW = "DATA_TO_TOPVIEW"
let DATA_TO_SUGGESTION = "DATA_TO_SUGGESTION"

class FeaturedController: BaseApplyQuickVideoController {

    // MARK: - outlet
    @IBOutlet weak var stackContainer: UIStackView!
    
    // MARK: - properties
    var topView:ListViewStreams!
    var page:Int = 1 {
        didSet {
            reloadData(false)
        }
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController!.navigationBar.shadowImage = #imageLiteral(resourceName: "TransparentPixel")
        
        // add two components
        configView()
        
        // listern event from components
        listernEvent()
        
        addDefaultMenu()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        if tabbarVC.isGotoDetail && tabbarVC.vwQuickView.transform.isIdentity == false{
            tabbarVC.vwQuickView.transform = .identity
        } else {
            self.closeQuickView()
            reloadData(true)
        }
        
        tabbarVC.isGotoDetail = false
    }
    
    // MARK: - process event
    func listernEvent() {
        
        topView.onDidSelect = {[weak self] stream, isTopView in
            guard let _self = self else {return}
            //push to stream view
            _self.openStream(stream,isTopView)
        }
        
        topView.onSelectAllCateogires = {[weak self] in
            guard let _self = self else {return}
            _self.closeQuickView()
            let vc = CategoriesController(nibName: "CategoriesController", bundle: Bundle.main)
            _self.navigationController?.pushViewController(vc, animated: true)
        }
        
        topView.getMoreStreams = {[weak self] in
            guard let _self = self else {return}
//            _self.page += 1
        }
        
        topView.needRefreshData = {[weak self] in
            guard let _self = self else {return}
            _self.reloadData(true)
        }
    }
    
    // MARK: - private
    func openStream(_ streamLocal:Stream,_ isTopView:Bool = false) {
        
        if streamLocal.status == AppConfig.status.stream.streaming() {
            let present = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
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
        
        prepareToOpenStream()
        configQuickView()
        
        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        guard let window = tabbarVC.view.window else { return }
        
        let quickViewController = window.quickViewcontroller()
        if tabbarVC.vwQuickView.transform.isIdentity == false {
            UIView.animate(withDuration: 0.2, animations: {
                tabbarVC.vwQuickView.transform = .identity
            })
        }
        if isTopView {
            quickViewController.identifier = DATA_TO_TOPVIEW
            // need refine this, avoid use properties of another view
            quickViewController.load(self.topView.featureView.listDatas.filter{$0.status != AppConfig.status.stream.streaming()}, start: streamLocal, false)
        } else {
            quickViewController.identifier = DATA_TO_SUGGESTION
            var focusList = self.topView.focusStreams.filter{$0.status != AppConfig.status.stream.streaming()}
            let listStream = self.topView.listStream.filter{$0.status != AppConfig.status.stream.streaming()}
            if listStream.count > 0 {
                focusList.append(contentsOf: listStream)
            }
            quickViewController.load(focusList, start: streamLocal, false)
        }
    }
    
    func reloadData(_ reloadAll:Bool = false) {

        // load top Stream
        if reloadAll || self.page == 1 {
//            self.topView.startLoading(activityIndicatorStyle: .gray)
            self.topView.startLoadFakeContent(isLoad: true)
        }
        Server.shared.getCategories(nil, loadCache: true) {[weak self] (result) in
        guard let _self = self else {return}
            switch result {
            case .success(let data):
                let ids = data.flatMap{Category.parse(from: $0)}.filter{$0.isMarked}.flatMap{$0.id}
//                _self.getSuggestionStreams(ids, reloadAll)
                _self.getFeatureAndSuggestStreams(ids.count > 0 ? ids : nil)
                break
            case .failure(_):
                _self.getFeatureAndSuggestStreams(nil)
//                _self.getSuggestionStreams(nil, reloadAll)
                break
            }
        }
    }
    
    func getSuggestStreamNotPaging(_ categoriesIds:[String]? = nil) {
        guard let user = Account.current else { return}
        Server.shared.getStreamsSuggestion(user_id:user.is_guest ? nil : user.id, category_ids: categoriesIds, page: 1, pageSize: 20, sortBy: "created_at") { [weak self] result in
            guard let _self = self else {return}
            switch result  {
            case .success(let list):
                if list.count == 0 && _self.topView.focusStreams.count == 0 {
                    if categoriesIds == nil {
                        //                        _self.topView.stopLoading()
                        _self.topView.startLoadFakeContent(isLoad: false)
                        //                        // no data_
                        _self.topView.load([], title: "suggestions".localized(),true)
                        _self.checkNextTutorial()
                        return
                    }
                }
                
                // fitler same stream if have
                let data = list.flatMap{Stream.parse(from:$0)}.filter({
                    for item in _self.topView.listStream {
                        for item in _self.topView.focusStreams {
                            if item.id == $0.id {
                                return false
                            }
                        }
                        if item.id == $0.id {
                            return false
                        }
                    }
                    return true
                })
                
                var max = 20 - _self.topView.listStream.count - _self.topView.focusStreams.count
                
                if max > data.count {
                    max = data.count
                }
                
                var listStream:[Stream] = []
                for i in 0 ..< max {
                    listStream.append(data[i])
                }
                
                _self.topView.startLoadFakeContent(isLoad: false)
                _self.topView.load(listStream, title: "suggestions".localized(),true)
                // if suggestions not fill 20, then request another categories streams

                _self.checkNextTutorial()
                
                // update data for quickview
                guard let tabbarVC = _self.tabBarController as? BaseTabbarController else { return }
                guard let window = tabbarVC.view.window else { return }
                
                let quickViewController = window.quickViewcontroller()
                if quickViewController.identifier == DATA_TO_TOPVIEW {return}
                quickViewController.listStream = _self.topView.listStream.filter{$0.status != AppConfig.status.stream.streaming()}
                
                
            case .failure(_):
                if categoriesIds == nil {
                    // no data_
                    _self.topView.startLoadFakeContent(isLoad: false)
                    _self.topView.load([], title: "suggestions".localized(),true)
                }
            }
        }
    }
    
    func getFeatureAndSuggestStreams(_ categoriesIds:[String]? = nil) {
        
        Server.shared.getStreams(user_id: nil, category_ids: nil, isFeatured: true, page: 1, pageSize: 20, sortBy: "created_at") {[weak self] result in
            guard let _self = self else {return}
            switch result  {
            case .success(let list):
                if list.count == 0 && _self.topView.focusStreams.count == 0 {
                    _self.getSuggestStreamNotPaging(categoriesIds)
                    return
                }
                
                // fitler same stream if have
                let data = list.flatMap{Stream.parse(from:$0)}
                
                var max = 9999999
                
//                if categoriesIds == nil { // change max <= 20 when suggestion from favourite not enough
                    max = 20 //- _self.topView.listStream.count - _self.topView.focusStreams.count
//                }
                
                if max > data.count {
                    max = data.count
                }
                
                var listStream:[Stream] = []
                for i in 0 ..< max {
                    listStream.append(data[i])
                }
                
                
                _self.topView.load(listStream, title: "suggestions".localized(),false)
                // if suggestions not fill 20, then request another categories streams
                if list.count < 20 && _self.topView.listStream.count + _self.topView.focusStreams.count < 20 {
                    _self.getSuggestStreamNotPaging(categoriesIds)
                    return
                } else {
                    _self.topView.startLoadFakeContent(isLoad: false)
//                                        _self.topView.stopLoading()
                }
                
                // update data for quickview
                guard let tabbarVC = _self.tabBarController as? BaseTabbarController else { return }
                guard let window = tabbarVC.view.window else { return }
                
                let quickViewController = window.quickViewcontroller()
                if quickViewController.identifier == DATA_TO_TOPVIEW {return}
                quickViewController.listStream = _self.topView.listStream.filter{$0.status != AppConfig.status.stream.streaming()}
                
                
            case .failure(_):
                _self.getSuggestStreamNotPaging(categoriesIds)
                break
            }
        }
    }
    
    func getSuggestionStreams(_ categoriesIds:[String]? = nil,_ reloadAll:Bool = false) {
        var pg = page
        var pgSize = 20
        
        if categoriesIds != nil {
            if reloadAll {
                pg = 1
                pgSize = page * pgSize
            }
        } else {
            pg = 1
            pgSize = 40
            
            // if list suggest enough 20, then force stop load more
            if self.topView.listStream.count >= 20
            {
                self.topView.isForceStopLoadMore = true
            }
        }
        
        guard let user = Account.current else { return }
        
        Server.shared.getStreamsSuggestion(user_id:user.is_guest ? nil : user.id, category_ids: categoriesIds, page: pg, pageSize: pgSize, sortBy: "created_at") { [weak self] result in
            guard let _self = self else {return}
            switch result  {
            case .success(let list):
                if list.count == 0 && _self.topView.listStream.count == 0 {
                    if categoriesIds == nil {
//                        _self.topView.stopLoading()
                        _self.topView.startLoadFakeContent(isLoad: false)
//                        // no data_
                        _self.topView.load([], title: "suggestions".localized(),!reloadAll)
                        return
                    } else {
                        if _self.topView.listStream.count < 20 {
                            _self.getSuggestionStreams()
                        }
                    }
                }
                
                // fitler same stream if have
                let data = list.flatMap{Stream.parse(from:$0)}.filter({
                    if reloadAll {return true}
                    for item in _self.topView.listStream {
                        if item.id == $0.id {
                            return false
                        }
                    }
                    return true
                })
                
                var max = 9999999
                
                if categoriesIds == nil { // change max <= 20 when suggestion from favourite not enough
                    max = 20 - _self.topView.listStream.count
                }
                
                if max > data.count {
                    max = data.count
                }
                
                var listStream:[Stream] = []
                for i in 0 ..< max {
                    listStream.append(data[i])
                }
                
                _self.topView.startLoadFakeContent(isLoad: false)
                _self.topView.load(listStream, title: "suggestions".localized(),!reloadAll)
                // if suggestions not fill 20, then request another categories streams
                if list.count < 20 && categoriesIds != nil && _self.topView.listStream.count < 20 {
                    _self.getSuggestionStreams()
                } else {
//                    _self.topView.stopLoading()
                }
                
                // update data for quickview
                guard let tabbarVC = _self.tabBarController as? BaseTabbarController else { return }
                guard let window = tabbarVC.view.window else { return }
                
                let quickViewController = window.quickViewcontroller()
                if quickViewController.identifier == DATA_TO_TOPVIEW {return}
                quickViewController.listStream = _self.topView.listStream.filter{$0.status != AppConfig.status.stream.streaming()}
                
                
            case .failure(_):
                if categoriesIds == nil {
                    // no data_
                    _self.topView.startLoadFakeContent(isLoad: false)
                    _self.topView.load([], title: "suggestions".localized(),!reloadAll)
                } else {
                    _self.getSuggestionStreams()
                }
                break
            }
        }
    }
    
    func configView() {
        topView = Bundle.main.loadNibNamed("ListViewStreams", owner: self, options: [:])?.first as! ListViewStreams
        topView.numberSection = 2
        stackContainer.addArrangedSubview(topView)
    }

    // MARK: - override super class
    override func configQuickView() {
        super.configQuickView()
        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        guard let window = tabbarVC.view.window else { return }
        let quickViewController = window.quickViewcontroller()
        quickViewController.needLoadMore = {[weak self] in
            guard let _self = self else {return}
            _self.page += 1
        }
    }
}

// MARK: - ShowCase
extension FeaturedController: MaterialShowcaseDelegate {
    
    func checkNextTutorial() {
        if !AppConfig.showCase.isShowTutorial(with: HOME_SCENE) {
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
            showcase.setTargetView(tabBar: self.tabBarController!.tabBar, itemIndex: 2)
            showcase.primaryText = ""
            showcase.identifier = TABBAR_BUTTON_LIVESTREAM
            showcase.secondaryText = "click_here_to_create_stream".localized().capitalizingFirstLetter()
            shouldShow(showcase,true)
        } else {
            shouldShow(showcase,false)
            if step > 1 {
                AppConfig.showCase.setFinishShowcase(key: HOME_SCENE)
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
