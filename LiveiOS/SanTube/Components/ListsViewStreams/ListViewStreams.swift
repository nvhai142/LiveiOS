//
//  TopViewStreamView.swift
//  BUUP
//
//  Created by Dai Pham on 11/7/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

// MARK: - INIT & CONFIG
class ListViewStreams: UIView {
    
    // MARK: - IBOulet
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    var refreshControl: UIRefreshControl!
    
    // MARK: - properties
    var featureView:FeatureStreamView!
    var isLoadingData:Bool = false
    
    var listStream:[Stream] = []
    var focusStreams:[Stream] = []
    var numberSection = 1
    
    // MARK: - closures
    var onTouchButtonTopStreamCell:((Stream)->Void)?
    var onDidSelect:((Stream,Bool)->Void)?
    var onSelectAllCateogires:(()->Void)?
    var getMoreStreams:(()->Void)?
    var isGettingData:Bool = false
    var isForceStopLoadMore:Bool = false
    var needRefreshData:(()->Void)?
    var endRefreshData:(()->Void)?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configView()
        
        tableView.pullResfresh {[weak self] in
            guard let _self = self else {return}
            if _self.isLoadingData {return}
            _self.needRefreshData?()
        }
    }
    
    // MARK: - api
    func startLoadFakeContent(isLoad:Bool) {
        isLoadingData = isLoad
        if isLoadingData {tableView.reloadData()}
        if isLoad {
            Loader.addLoaderTo(self.tableView)
//            Loader.addLoaderToViews([featureView])
        }  else {
            Loader.removeLoaderFrom(self.tableView)
//            Loader.removeLoaderFromViews([featureView])
        }
    }
    
    func load(_ data:[Stream], title:String,_ isAppend:Bool = false) {
        
        if tableView.tableFooterView?.isHidden == false {
            tableView.tableFooterView?.isHidden = true
        }
        
        lblTitle.text = title
        if !isAppend {
            focusStreams.removeAll()
            listStream.removeAll()
        }
        
        for item in data {
            // for ipad, we will display five items
            if focusStreams.count < (UIDevice.current.userInterfaceIdiom == .pad ? 5 : 2) {
                focusStreams.append(item)
            } else {
                listStream.append(item)
            }
        }
        
        featureView.loadListFeature(focusStreams)
        tableView.reloadData()
        
        isGettingData = data.isEmpty
        stopPullRefresh()
        if listStream.count == 0 && focusStreams.count == 0 {
//            tableView.showNoData("no_data_stream".localized().capitalizingFirstLetter())
        } else {
            tableView.removeNoData()
        }
    }
    
    func stopPullRefresh() {
        tableView.endPullResfresh()
    }
    
    // MARK: - private
    func configView() {
        lblTitle.text = ""
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 98
        
        tableView.register(UINib(nibName: "RelatedVideoCell", bundle: Bundle.main), forCellReuseIdentifier: "cell")
        
        featureView = Bundle.main.loadNibNamed("FeatureStreamView", owner: self, options: [:])?.first as! FeatureStreamView
    }
    
    func configTitle(_ label:UILabel) {
        label.font = UIFont.boldSystemFont(ofSize: fontSize18)
        label.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
}

// MARK: - TABLEVIEW DELEGATE
fileprivate var HEADER_TABLE:String = "HEADER_TABLE"
extension ListViewStreams:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section > 0 || self.numberSection < 2 {
            self.onDidSelect?(self.listStream[indexPath.row],false)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isLoadingData {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! RelatedVideoCell
            return cell
        }
        
        if indexPath.section == 1 || numberSection < 2 {
            
//            if focusStreams.count == 0 {
//                let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell1")
//                cell.textLabel?.text = "no_data_stream".localized()
//                return cell
//            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! RelatedVideoCell
            
            cell.load(data:listStream[indexPath.row])
            
            return cell
            
        } else {
            let cell = featureView
            cell?.selectionStyle = .none
            
            // go to stream view
            featureView.onSelectObject = {[weak self] stream in
                guard let _self = self else {return}
                // push to stream View
                _self.onDidSelect?(stream,false)
            }
            return cell!
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isLoadingData {return 1}
        return numberSection
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoadingData {
            return Int(tableView.frame.size.height/146)
        }
        if numberSection < 2 {
            return listStream.count// == 0 ? 1 : listStream.count
        }
        if section == 1 {
            return listStream.count// == 0 ? 1 : listStream.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if isLoadingData {return nil}
        if section == 1 || numberSection < 2 {
            if listStream.count == 0 {return nil}
            let view = UIView(frame:CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
            view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            let label = UILabel(frame: view.bounds)
            configTitle(label)
            label.text = "maybe_you_are_interested".localized().capitalizingFirstLetter()
            label.textAlignment = .left
            view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.leftAnchor.constraint(equalTo: label.superview!.leftAnchor, constant: 10).isActive = true
            label.superview!.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 0).isActive = true
            label.superview!.rightAnchor.constraint(equalTo: label.rightAnchor, constant: 10).isActive = true
            objc_setAssociatedObject(self, &HEADER_TABLE, view, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return view
        } else {
            return nil
        }
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if isLoadingData {return}
//        if numberSection < 2 || indexPath.section == 1 {
//            if indexPath.row > self.listStream.count * 70/100 && !isGettingData{
//                isGettingData = true
//                if !isForceStopLoadMore {
//                    let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
//                    spinner.startAnimating()
//                    spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(44))
//                    
//                    tableView.tableFooterView = spinner
//                    tableView.tableFooterView?.isHidden = false
//                    self.getMoreStreams?()
//                }
//            }
//        }
//    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isLoadingData {return 0}
        if section == 1 && listStream.count > 0{
            return 30
        }
        return 0
    }
}

extension ListViewStreams: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.height < 1.5*scrollView.frame.size.height {return}
        if let view = objc_getAssociatedObject(self, &HEADER_TABLE) as? UIView {
            UIView.animate(withDuration: 0.25, animations: {
                view.backgroundColor = scrollView.contentOffset.y > CGFloat(10)*scrollView.contentSize.height/100 ? UIColor.black : UIColor.white
                view.alpha = scrollView.contentOffset.y > CGFloat(10)*scrollView.contentSize.height/100 ? 0.3 : 1
                if let lbl = view.subviews.first as? UILabel {
                    lbl.textColor = scrollView.contentOffset.y > CGFloat(10)*scrollView.contentSize.height/100 ? UIColor.white : UIColor.black
                }
            })
        }
    }
}
