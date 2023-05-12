//
//  RelatedVideoController.swift
//  SanTube
//
//  Created by Dai Pham on 12/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

enum RelatedVideoType {
    case categories // display related video from stream
    case follower // display stream from list userids
}

// MARK: - Common
class RelatedVideoController: BaseController {

    // MARK: - outlet
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - clousers
    var onLoadStream:((Stream)->Void)?
    
    // MARK: - properties
    var isLoading:Bool = false
    var reloadAll:Bool = false
    var listStreams:[Stream] = []
    var listUserIds:[String]? = nil {
        didSet {
            if listUserIds != nil {
                loadData(true)
            }
        }
    }
    var type:RelatedVideoType = .categories
    
    var page:Int = 1 {
        didSet{
            loadData()
        }
    }
    var stream:Stream? = nil {
        didSet{
            loadData(true)
        }
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "RelatedVideoCell", bundle: Bundle.main), forCellReuseIdentifier: "cell")
        
        tableView.pullResfresh {[weak self] in
            guard let _self = self else {return}
            _self.loadData(true)
        }
    }
    
    // MARK: - interface
    func load(data:[Stream]) {
        listStreams = data
        
        tableView.reloadData()
    }
    
    // MARK: - private
    func loadData(_ isReloadAll:Bool = false) {
        
        var cateIds:[String]?
        
        if type == .categories {
            guard let obj = self.stream else {return}
            guard let cate = obj.categories.first else { return}
            cateIds = [cate.id]
            listUserIds = nil
        }
        
        isLoading = true
        self.view.startLoading(activityIndicatorStyle: .gray)
        
        
        
        var p = page
        var numbersize = 20
        if isReloadAll {
            self.listStreams.removeAll()
            tableView.reloadData()
            p = 1
            numbersize = page * numbersize
        }
        
        Server.shared.getStreams(user_id: listUserIds, category_ids: cateIds, isFeatured: false, page: p, pageSize: numbersize, sortBy: "created_at") { [weak self] result in
            guard let _self = self else {return}
            _self.view.stopLoading()
            switch result  {
            case .success(let list):
                
                let data = _self.type == .categories ? list.flatMap{Stream.parse(from:$0)}.filter{$0.id != _self.stream!.id} : list.flatMap{Stream.parse(from:$0)}
                
                if data.count == 0 {
                    // no data_
                    if _self.page == 1 && _self.listUserIds == nil {
                        _self.tableView.showNoData()
                    }
                    _self.isLoading = false
                    _self.tableView.endPullResfresh()
                    return
                }
                _self.tableView.removeNoData()
                
                _self.listStreams.append(contentsOf: data)
                _self.tableView.endPullResfresh()
                _self.tableView.reloadData()
                _self.isLoading = false
            case .failure(_):
                print("No Steam Top View")
                if _self.page == 1 {
                    _self.tableView.showNoData()
                }
                _self.isLoading = false
                _self.tableView.endPullResfresh()
                break
            }
        }
        
    }
}

// MARK: - Tableview delegate
extension RelatedVideoController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onLoadStream?(listStreams[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! RelatedVideoCell
        
        cell.load(data: listStreams[indexPath.row])
       
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return listStreams.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= self.listStreams.count*80/100 && !self.isLoading {
            self.isLoading = true
            self.reloadAll = false
            self.page += 1
        }
    }
}
