//
//  OrderManagementController.swift
//  SanTube
//
//  Created by Dai Pham on 12/26/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import Daysquare

class OrderManagementController: BaseController {

    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configView()
        listernEvent()
        addMenuBar()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
//        addDefaultMenu()
        
        tableView.pullResfresh {[weak self] in
            guard let _self = self else {return}
            _self.reloadAll = true
            _self.isLoadMore = false
            _self.listOrders = []
            _self.tableView.reloadData()
            _self.loadListOrders()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        isLoadMore = false
        reloadAll = true
        self.listOrders = []
        self.tableView.reloadData()
        setupDate()
        loadListOrders()
    }
    
    // MARK: - event
    @IBAction func segmentTouch(_ sender: UISegmentedControl) {
        let old = isSeller
        if segmentControl.selectedSegmentIndex == 0 {
            isSeller = true
        } else {
            isSeller = false
        }
        if old != isSeller {
            isLoadMore = false
            reloadAll = false
            self.listOrders = []
            self.tableView.reloadData()
            page = 1
        }
    }
    
    func buttonSelect(sender:UIButton) {
        _ = stackControl.arrangedSubviews.map({if let btn = $0 as? UIButton { btn.isSelected = false;btn.layer.borderColor = UIColor.clear.cgColor}})
        sender.isSelected = true
        sender.layer.borderColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        var shouldLoadOrder = true
        _ = listDates.map({
            if  let title = $0["title"] as? String, let date = $0["value"] as? Date{
                if sender.titleLabel?.text == title {
                    if selectedDate.toString(dateFormat: "yyyy-MM-dd") == date.toString(dateFormat: "yyyy-MM-dd") {
                        shouldLoadOrder = false
                    }
                    selectedDate = date
                    vwCalendar.selectedDate = selectedDate
                }
            }
        })
        
        if !shouldLoadOrder {return}
        
        isLoadMore = false
        reloadAll = false
        self.listOrders = []
        self.tableView.reloadData()
        page = 1
    }
    
    func didChangeValue (calendar:DAYCalendarView) {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY/MM/dd"
        _ = stackControl.arrangedSubviews.map({if let btn = $0 as? UIButton { btn.isSelected = false;btn.layer.borderColor = UIColor.clear.cgColor}})
        
        _ = listDates.map({
            if let title = $0["title"] as? String, let date = $0["value"] as? Date{
                if calendar.selectedDate.toString(dateFormat: "yyyy-MM-dd") ==  date.toString(dateFormat: "yyyy-MM-dd"){
                    _ = stackControl.arrangedSubviews.map({ if let btn = $0 as? UIButton {btn.isSelected = false;btn.layer.borderColor = UIColor.clear.cgColor; if btn.titleLabel?.text == title {btn.isSelected = true;btn.layer.borderColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)}}})
                }
            }
        })
        
        if selectedDate.toString(dateFormat: "yyyy-MM-dd") == calendar.selectedDate.toString(dateFormat: "yyyy-MM-dd") {return}
        
        selectedDate = calendar.selectedDate
        
        isLoadMore = false
        reloadAll = false
        self.listOrders = []
        self.tableView.reloadData()
        page = 1
    }
    
    func listernEvent() {
        iconCalendar.addEvent {
            UIView.transition(with: self.vwCalendar, duration: 0.3, options: [.curveEaseInOut], animations: {
                self.vwCalendar.isHidden = !self.vwCalendar.isHidden
                self.iconCalendar.tintColor = self.vwCalendar.isHidden ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) : #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
            }, completion: {isfinished in
                
            })
        }
    }
    // MARK: - private
    private func addMenuBar() {
        menuBar = Bundle.main.loadNibNamed("ExtendedNavBarView", owner: self, options: nil)?.first as! ExtendedNavBarView
        stackContainer.insertArrangedSubview(menuBar, at: 0)
        menuBar.translatesAutoresizingMaskIntoConstraints = false
        menuBar.heightAnchor.constraint(equalToConstant: navigationController!.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.size.height).isActive = true
        menuBar.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        menuBar.controller = self
        menuBar.setTitle("order_history".localized().capitalizingFirstLetter())
    }
    
    fileprivate func deleteOrder(_ complete:@escaping ((Bool)->Void)) {
        guard let order = Support.orderDeleted.getOrderDeleted() else {complete(true); return }
        print("Warning: \(order.id) removed")
        Server.shared.changeStatusOrder(orderIds: [order.id],
                                        status: AppConfig.status.order.delete()) {(order, err) in
                                            if err == nil {
                                                complete(true)
                                            } else {
                                                complete(false)
                                            }
        }
    }
    
    fileprivate func involkeDeleteOrder() {
        deleteOrder {[weak self] (isSuccess) in
            guard let _self = self else {return}
            if isSuccess {
                
                if let order = Support.orderDeleted.getOrderDeleted() {
                    // handle UI
                    for (index,item) in _self.listOrders.enumerated() {
                        if item.id == order.id {
                            _self.listOrders.remove(at: index)
                            _self.tableView.beginUpdates()
                            _self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                            _self.tableView.endUpdates()
                        }
                    }
                }
                
                // remove order deleted
                Support.orderDeleted.saveOrderDeleted()
                
            } else {
                let actionSheetController: UIAlertController = UIAlertController(title: "error".localized().uppercased(), message: "order_delete_failed".localized().capitalizingFirstLetter(), preferredStyle: .alert)
                let cancelAction: UIAlertAction = UIAlertAction(title: "ok".localized().uppercased(), style: .cancel) { action -> Void in
                    //Just dismiss the action sheet
                }
                actionSheetController.addAction(cancelAction)
                _self.present(actionSheetController, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func loadListOrders() {
        
        guard let user = Account.current else {return}
        
        self.tableView.removeNoData()
        
        var p = page
        var numbersize = 20
        if reloadAll {
            self.listOrders = []
            self.tableView.reloadData()
            
            p = 1
            numbersize = page * numbersize
        }
        
        if maxPage <= page && !reloadAll{
            return
        }
        
        #if DEBUG
            print("max: \(maxPage)\npage: \(page)")
        #endif
        
        self.tableView.startLoading(activityIndicatorStyle: .gray)
        
        isLoading = true
        // first delete order missing delete before cause app killed before call api
        deleteOrder {[weak self] isSuccess in
            guard let _self = self else {return}
            
            if isSuccess {
                Support.orderDeleted.saveOrderDeleted()
            }
            
            let sellerId = _self.isSeller ? user.id : nil
            let buyerId = _self.isSeller ? nil : user.id
            
            let fromDate = _self.selectedDate.toString(dateFormat: "yyyy-MM-dd").appending(" 00:00:00")
            let toDate = _self.selectedDate.toString(dateFormat: "yyyy-MM-dd").appending(" 23:59:59")
            
            Server.shared.getOrders(streamId: nil,
                                    buyerId: buyerId,
                                    sellerId: sellerId,
                                    status: nil,
                                    fromDate: fromDate,
                                    toDate: toDate, page: p, pageSize: numbersize) {[weak _self] (list, err) in
                                        guard let __self = _self else {return}
                                        __self.isLoading = false
                                        __self.tableView.stopLoading()
                                        __self.tableView.endPullResfresh()
                                        if err == nil {
                                            if list?.count == 0 {
                                                if __self.page > 1 {
                                                    __self.maxPage = __self.page - 1
                                                    __self.page -= 1
                                                } else {
                                                    __self.maxPage = __self.page
                                                }
                                                
                                                if __self.listOrders.count == 0 {
                                                    __self.tableView.showNoData("no_data_order".localized())
                                                }
                                                return
                                            }
                                            guard let list = list else {
                                                return
                                            }
                                            __self.listOrders.append(contentsOf: list)
                                            __self.tableView.reloadData()
                                        }
                                        if __self.listOrders.count == 0 {
                                            __self.tableView.showNoData("no_data_order".localized())
                                        }
            }
        }
    }
    
    private func setupDate() {
        let currentDate = Date()
        listDates.removeAll()
        view.layoutIfNeeded()
        view.setNeedsDisplay()
        _ = stackControl.arrangedSubviews.map{if $0.isKind(of: UIButton.self) {$0.removeFromSuperview()}}
        let formatter = DateFormatter()
        formatter.dateFormat = "EE\ndd"
        let realSize = Int(view.frame.size.width - 20 - 100) // space - segment width
        var numberButton:Int = Int(realSize/40)
        numberButton = (Int((realSize - (numberButton)*10)) / 40) - 1
        
        var i = 0
        for j in 0..<(numberButton+1) {
            if j == 0 {
                listDates.append(["value":currentDate.addedBy(minutes: j * -1440),"title":"today"])
            } else {
                listDates.append(["value":currentDate.addedBy(minutes: j * -1440),"title":formatter.string(from: currentDate.addedBy(minutes: j * -1440))])
            }
            i += 1
        }

        for item in listDates.reversed() {
            let button = UIButton(type: UIButtonType.custom)
            button.setTitle(item["title"] as? String, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize15)
            button.titleLabel?.textAlignment = .center
            button.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: .selected)
            button.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
            button.setBackgroundImage(#imageLiteral(resourceName: "Pixel").tint(with: #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)), for: .selected)
            button.setBackgroundImage(#imageLiteral(resourceName: "TransparentPixel"), for: .normal)
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10)
            button.addTarget(self, action: #selector(buttonSelect), for: UIControlEvents.touchUpInside)
            if i == 1 {
                button.isSelected = true
                button.layer.borderColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
            }
            i -= 1
            
            stackControl.addArrangedSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            let width = button.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
            width.priority = 1000
            button.addConstraint(width)
//            let height = button.heightAnchor.constraint(equalToConstant: 40)
//            height.priority = 751
//            button.addConstraint(height)
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10)
            button.layer.masksToBounds = true
            button.titleLabel?.numberOfLines = 2
            button.layer.borderWidth = 1.5
            button.layer.cornerRadius = 40/2
            button.layer.borderColor = button.isSelected ? #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1) : UIColor.clear.cgColor
        }
    }
    
    func configView() {
        
        title = "order_history".localized()
        
        tableView.register(UINib(nibName: "OrderManagementCell", bundle: Bundle.main), forCellReuseIdentifier: "cell")
        
        segmentControl.setTitle("sell".localized().capitalized, forSegmentAt: 0)
        segmentControl.setTitle("buy".localized().capitalized, forSegmentAt: 1)
        
        vwCalendar.addTarget(self, action: #selector(didChangeValue(calendar:)), for: .valueChanged)
        vwCalendar.isHidden = true
        vwCalendar.highlightedComponentTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        iconCalendar.image = #imageLiteral(resourceName: "ic_calendar_1").withRenderingMode(.alwaysTemplate)
        iconCalendar.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        vwCalendar.selectedDate = selectedDate
    }
    
    // MARK: - properties
    var menuBar:ExtendedNavBarView!
    var listOrders:[Order] = []
    var listDates:[JSON] = []
    var isSeller:Bool = true
    var selectedDate:Date = Date()
    var timerCountDownRemoveOrder:Timer?
    
    var page:Int = 1 {
        willSet {
            if isLoadMore == false {
                shouldLoadNext = true
            } else {
                shouldLoadNext = (newValue > page)
            }
        }
        
        didSet{
            if page == 1 && !isLoadMore {
                maxPage = 999
            }
            if shouldLoadNext {
                self.loadListOrders()
            }
        }
    }
    
    var shouldLoadNext:Bool = true
    var isLoadMore:Bool = false
    var maxPage:Int = 999
    var isLoading:Bool = false
    var reloadAll:Bool = false
    
    // MARK: - outlet
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var stackControl: UIStackView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var iconCalendar: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var vwCalendar: DAYCalendarView!
    @IBOutlet weak var scrollView: UIScrollView!
}

// MARK: - handle tableview
extension OrderManagementController:UITableViewDelegate, UITableViewDataSource {
    
    // prevent present detail while state cell is wait deleted
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let cell = tableView.cellForRow(at: indexPath) as? OrderManagementCell else {return nil}
        if cell.shouldSelect() {
            return indexPath
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = OrderDetailController(nibName: "OrderDetailController", bundle: Bundle.main)
        vc.type = isSeller ? .process : .view
        vc.order = listOrders[indexPath.row]
        vc.onDissmiss = {[weak self] in
            guard let _self = self else {return}
            _self.reloadAll = true
            _self.loadListOrders()
        }
        self.tabBarController?.present(vc, animated: false, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! OrderManagementCell
        cell.delegate = self
        cell.type = isSeller ? .buyer : .seller
        cell.load(listOrders[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOrders.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row >= self.listOrders.count*90/100 && !self.isLoading && maxPage > page{
            self.isLoadMore = true
            self.isLoading = true
            self.reloadAll = false
            self.page += 1
        }
    }
}

// MARK: - OrderCellDelegate
extension OrderManagementController:OrderManagementCellDelegate {
    func orderCell(delete order: Order, isForceDelete: Bool) {
        
        // 0. save object is deleted: object removed when call api delete done or undo delete
        // 1. user force delete: touch x || begin delete another order
        // 2. timer count down to delete
        // 3. suddenly killed app while timer continue count down => first time goto this view, check that order is deleted
        
        // timer is valid => has order wait deleted. force delete
        if timerCountDownRemoveOrder != nil {
            if timerCountDownRemoveOrder!.isValid {
                timerCountDownRemoveOrder?.invalidate()
                
                // check same order
                if let oldOrder = Support.orderDeleted.getOrderDeleted() {
                    if oldOrder.id == order.id {
                        print("same order \(oldOrder.id) is wait removed")
                        // handle API
                        involkeDeleteOrder()
                        return
                    }
                }
                
                // handle API
                involkeDeleteOrder()
            }
        }

        // save order need deleted
        Support.orderDeleted.saveOrderDeleted(order: order)
        
        if isForceDelete {
            involkeDeleteOrder()
        } else {
            timerCountDownRemoveOrder = Timer.scheduledTimer(withTimeInterval: 4, repeats: false, block: {[weak self] timer in
                guard let _self = self else {return}
                _self.timerCountDownRemoveOrder!.invalidate()
                _self.involkeDeleteOrder()
            })
        }
    }
    
    func orderCell(undo order: Order) {
        if timerCountDownRemoveOrder != nil {
            if timerCountDownRemoveOrder!.isValid {
                timerCountDownRemoveOrder?.invalidate()
            }
        }
        
        Support.orderDeleted.saveOrderDeleted()
    }
}

// MARK: - SCrollview
extension OrderManagementController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 && !vwCalendar.isHidden {
            UIView.transition(with: self.vwCalendar, duration: 0.3, options: [.curveEaseInOut], animations: {
                self.vwCalendar.isHidden = true
                self.iconCalendar.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            }, completion: {isfinished in
                
            })
        }
    }
}
