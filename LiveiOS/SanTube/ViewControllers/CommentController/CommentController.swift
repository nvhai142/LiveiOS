//
//  CommentController.swift
//  SanTube
//
//  Created by Dai Pham on 12/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class CommentController: BaseController {

    // MARK: - outlet
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - properties
    var listComments:[JSON] = []
    var isLoading:Bool = false
    var reloadAll:Bool = false
    
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
    
    // MARK: - closures
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.register(UINib(nibName: "CommentCell", bundle: Bundle.main), forCellReuseIdentifier: "cell")
    }
    
    // MARK: - interface
    func load(data:[JSON]) {
        listComments = data
        
        tableView.reloadData()
    }
    
    // MARK: - private
    func loadData(_ isReloadAll:Bool = false) {
        for _ in 0..<50 {
            self.listComments.append(["test":"abc"])
        }
        
        tableView.reloadData()
        
//        guard let obj = self.stream else {return}
//
//        isLoading = true
//        self.view.startLoading(activityIndicatorStyle: .gray)
//
//        let cateIds:[String] = [cate.id]
//
//        var p = page
//        var numbersize = 20
//        if isReloadAll {
//            self.listStreams.removeAll()
//            tableView.reloadData()
//            p = 1
//            numbersize = page * numbersize
//        }
//
//        Server.shared.getStreams(user_id: nil, category_ids: cateIds, isFeatured: false, page: p, pageSize: numbersize, sortBy: "created_at") { [weak self] result in
//            guard let _self = self else {return}
//            _self.view.stopLoading()
//            switch result  {
//            case .success(let list):
//
//                let data = list.flatMap{Stream.parse(from:$0)}.filter{$0.id != obj.id}
//
//                if data.count == 0 {
//                    // no data_
//                    if _self.page == 1 {
//                        _self.tableView.showNoData()
//                    }
//                    _self.isLoading = false
//                    _self.tableView.endPullResfresh()
//                    return
//                }
//                _self.tableView.removeNoData()
//
//                _self.listStreams.append(contentsOf: data)
//                _self.tableView.endPullResfresh()
//                _self.tableView.reloadData()
//                _self.isLoading = false
//            case .failure(_):
//                print("No Steam Top View")
//                if _self.page == 1 {
//                    _self.tableView.showNoData()
//                }
//                _self.isLoading = false
//                _self.tableView.endPullResfresh()
//                break
//            }
//        }
        
    }
}

// MARK: - Tableview delegate
extension CommentController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! CommentCell
        
        cell.load(data:listComments[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listComments.count
    }
}
