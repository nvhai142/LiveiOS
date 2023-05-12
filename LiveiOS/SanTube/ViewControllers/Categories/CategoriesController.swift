//
//  CategoriesController.swift
//  BUUP
//
//  Created by Dai Pham on 11/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

fileprivate let column = UIDevice.current.userInterfaceIdiom == .pad ? CGFloat(5) : CGFloat(3)
fileprivate let space = CGFloat(10)

class CategoriesController: BaseApplyQuickVideoController {

    // MARK: - outlet
    @IBOutlet weak var stackContainer: UIStackView!
    
    // MARK: - properties
    var categoriesView:CategoriesListView!
    @IBOutlet weak var collectView: UICollectionView!
    
    var page:Int = 1 {
        didSet{
            self.loadStream(from: self.currentCate)
        }
    }
    
    var currentCate:Category?
    var listStreams:[Stream] = []
    var isLoading:Bool = false
    var reloadAll:Bool = false
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add default menu
//        addDefaultMenu()
        
        // add components
        configView()
        
        // listern event
        listernEvent()
        isLoading = true
        Server.shared.getCategories(UserManager.currentUser()?.id,loadCache:true) {[weak self] result in
            guard let _self = self else {return}
            switch result {
            case .success(let list):
                _self.isLoading = false
                let listTemp = list.flatMap{Category.parse(from: $0)}
                _self.categoriesView.load(listTemp.sorted(by: { (item, item1) -> Bool in
                    return item.isMarked && !item1.isMarked
                }))
                
                // delay to sure icons categories loaded
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: {[weak _self] timer in
                    guard let __self = _self else {return}
                    __self.categoriesView.setSelect(index: 0)
                })
            case .failure(let msg):
                print(msg as Any)
            }
            
        }
        
        collectView.pullResfresh {[weak self] in
            guard let _self = self else {return}
            _self.reloadAll = true
            let page = _self.page
            _self.page = page
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        if tabbarVC.isGotoDetail && tabbarVC.vwQuickView.transform.isIdentity == false{
            tabbarVC.isGotoDetail = false
            tabbarVC.vwQuickView.transform = .identity
        }
    }
    
    // MARK: - listern event
    func listernEvent() {
        
        // reload list category selected
        categoriesView.onSelectCategory = {[weak self] category in
            guard let _self = self else {return}
            _self.currentCate = category
            _self.reloadAll = true
            _self.page = 1
        }
        
        // back to home
        categoriesView.onBack = {[weak self] in
            guard let _self = self else {return}
            _self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - private
    func openStream(_ steam:Stream) {
        
        if steam.status == AppConfig.status.stream.streaming() {
            let present = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
            let vc = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
            vc.streamVideoController = present
            vc.stream = steam
            vc.onGotoStreamDetail = {[weak self] stream in
                guard let _self = self else {return}
                let present = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                let vc = DetailStreamController(nibName: "DetailStreamController", bundle: Bundle.main)
                vc.stream = stream
                vc.streamVideoController = present
                vc.onGotoLiveStream = {[weak _self] str in
                    guard let __self = _self else {return}
                    let present = PresentVideoController(nibName: "PresentVideoController", bundle: Bundle.main)
                    let vc = StreamViewController(nibName: "StreamViewController", bundle: Bundle.main)
                    vc.streamVideoController = present
                    vc.stream = str
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
                            __self.tabBarController?.present(vc2, animated: false)
                        }
                        _self.tabBarController?.present(vc1, animated: true)
                    }
                    __self.tabBarController?.present(vc, animated: false)
                }
                _self.tabBarController?.present(vc, animated: true)
            }
            self.tabBarController?.present(vc, animated: false)
            return
        }
        
        prepareToOpenStream()
        configQuickView()
        
        guard let tabbarVC = self.tabBarController as? BaseTabbarController else { return }
        guard let window = tabbarVC.view.window else { return }
        
        if tabbarVC.vwQuickView.transform.isIdentity == false {
            UIView.animate(withDuration: 0.2, animations: {
                tabbarVC.vwQuickView.transform = .identity
            })
        }
        
        let quickViewController = window.quickViewcontroller()
        quickViewController.load(self.listStreams.filter{$0.status != AppConfig.status.stream.streaming()}, start: steam, false)
    }
    
    func loadStream(from cate:Category? = nil) {
        
        guard let c = cate else { return }
        isLoading = true
        self.currentCate = c
        if !self.collectView.isUsingPullRefresh() {
            self.collectView.startLoading(activityIndicatorStyle: .gray)
        }
        var cateIds:[String]?
        if !c.isAll {
            cateIds = [c.id]
        }
        var p = page
        var numbersize = 20
        if reloadAll {
            self.listStreams.removeAll()
            collectView.reloadData()
            p = 1
            numbersize = page * numbersize
        }
        
        Server.shared.getStreams(user_id: nil, category_ids: cateIds, isFeatured: false, page: p, pageSize: numbersize, sortBy: "created_at") { [weak self] result in
            guard let _self = self else {return}
            _self.collectView.stopLoading()
            switch result  {
            case .success(let list):
                if list.count == 0 {
                    // no data_
                    if _self.page == 1 {
                        _self.collectView.showNoData()
                    }
                    _self.isLoading = false
                    _self.collectView.endPullResfresh()
                    return
                }
                _self.collectView.removeNoData()
                let data = list.flatMap{Stream.parse(from:$0)}               
                _self.listStreams.append(contentsOf: data)
                _self.collectView.endPullResfresh()
                _self.collectView.reloadData()
                _self.isLoading = false
                
                // update data for quickview
                guard let tabbarVC = _self.tabBarController as? BaseTabbarController else { return }
                guard let window = tabbarVC.view.window else { return }
                let quickViewController = window.quickViewcontroller()
                quickViewController.listStream = _self.listStreams.filter{$0.status != AppConfig.status.stream.streaming()}
                
            case .failure(_):
                print("No Steam Top View")
                if _self.page == 1 {
                    _self.collectView.showNoData()
                }
                _self.isLoading = false
                _self.collectView.endPullResfresh()
                break
            }
        }
    }
    
    func configView() {
        
//        collectView.backgroundColor = #colorLiteral(red: 0.9764705882, green: 0.9764705882, blue: 0.9764705882, alpha: 1)
        collectView.register(UINib(nibName: "StreamCollectCell", bundle: Bundle.main), forCellWithReuseIdentifier: "cell")

        categoriesView = Bundle.main.loadNibNamed("CategoriesListView", owner: self, options: [:])?.first as! CategoriesListView
        stackContainer.insertArrangedSubview(categoriesView, at: 0)
    }
    
    // MARK: - Override supper class
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

extension CategoriesController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.listStreams.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! StreamCollectCell
        cell.load(stream: listStreams[indexPath.row])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.listStreams[indexPath.row]
        self.openStream(item)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let realspace = space * (column-1)
        
        let width = (collectionView.frame.size.width - realspace)/column - 5/3
        let height = width * 1.4
        return CGSize(width:width, height:height)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row >= self.listStreams.count*90/100 && !self.isLoading {
            self.isLoading = true
            self.reloadAll = false
            self.page += 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(space)
    }
}

extension CategoriesController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.height < 1.5*scrollView.frame.size.height && !categoriesView.scrollViewOne.isHidden {
            return
        }
        categoriesView.hideList(isHide: scrollView.contentOffset.y > CGFloat(10)*scrollView.contentSize.height/100,scrollView)
        stackContainer.spacing = scrollView.contentOffset.y > CGFloat(10)*scrollView.contentSize.height/100 ? -30 : 0
    }
}
