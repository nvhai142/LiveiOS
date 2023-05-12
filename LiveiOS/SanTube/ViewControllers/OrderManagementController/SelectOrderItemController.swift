//
//  SelectOrderItemController.swift
//  SanTube
//
//  Created by Dai Pham on 1/9/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

enum SelectOrderItemType {
    case edit
    case new
}

protocol SelectOrderItemDelegate {
    func getUpdatedOrderStream(from vc:SelectOrderItemController) -> Order?
}

class SelectOrderItemController: BaseController {
    
    // MARK: - action button
    func touchButton(sender:UIButton) {
        if sender.isEqual(btnNext) || sender.isEqual(btnCart){
            if btnCart.isSelected == false {return}
            let vc = OrderConfirmController(nibName: "OrderConfirmController", bundle: Bundle.main)
            navigationController?.pushViewController(vc, animated: true)
            vc.order = order
        }
    }
    
    func listernEvent() {
        vwListProducts.onListProductSelected = {[weak self] listSeleted in
            guard let _self = self, var order = _self.order else {return}
            
            // reset
            for (i,item2) in order.products.enumerated() {
                var pro = item2
                pro.orderQuantity = 0
                order.products[i] = pro
            }
            
            // setup again order selected
            for item in listSeleted {
                for (i,item2) in order.products.enumerated() {
                    var pro = item2
                    if item.id == item2.id {
                        pro.orderQuantity = 1
                        order.products[i] = pro
                    }
                    
                    // if temp first is exist, remove for reset state
                    if _self.tempFirstSelected != nil {
                        for item3 in _self.tempFirstSelected! {
                            if item3.id == pro.id {
                                pro.orderQuantity = item3.orderQuantity
                                break
                            }
                        }
                        order.products[i] = pro
                    }
                }
            }
            
            _self.tempFirstSelected = nil
            
            _self.order = order
            _self.validate()
        }
    }
    
    // MARK: - private
    private func loadOrderItem() {
        guard let order = order else { return }
        self.vwListProducts.listProducts = order.products
        self.vwListProducts.reloadData()
    }
    
    private func configView() {
        vwListProducts.collectView.allowsSelection = false
        vwListProducts.orderItemViewType = .selected
        
        if startPoint == CGPoint.zero {
            startPoint = self.navigationController!.view.center
        }
        
        lblNote.textColor = #colorLiteral(red: 0.368627451, green: 0.368627451, blue: 0.368627451, alpha: 1)
        lblNote.font = UIFont.systemFont(ofSize: fontSize15)
    }
    
    private func configText() {
        lblNote.text = "note_select_order_item".localized()
    }
    
    private func validate() {
        let numberProductSelected = self.order!.products.filter{$0.orderQuantity > 0}.count
        btnNext.isHidden = numberProductSelected == 0
        btnCart.isSelected = numberProductSelected > 0
        btnCart.setBag(numberProductSelected)
    }
    
    func reupdateQuantitySaleProducts() {
        self.order = delegate?.getUpdatedOrderStream(from: self)
        loadOrderItem()
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(reupdateQuantitySaleProducts), name: NSNotification.Name("App:NeedUpdatedQuanityProduct"), object: nil)
        
        title = "order".localized().capitalized
        
        btnBack = UIButton(type: .custom)
        btnBack.frame = CGRect(x: 0, y: 0, width: 40*70/100, height: 40)
        btnBack.contentMode = .scaleAspectFill
        btnBack.clipsToBounds = true
        btnBack.semanticContentAttribute = .forceLeftToRight
        btnBack.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        btnBack.setImage(UIImage(named:"arrow_left_white_48")?.tint(with: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)), for: UIControlState())
        btnBack.addTarget(self, action: #selector(self.menuPress(sender:)), for: .touchUpInside)
        let itemBack = UIBarButtonItem(customView: btnBack)
        self.navigationItem.leftBarButtonItems = [itemBack]
        
        btnNext = UIButton(type: .custom)
        btnNext.frame = CGRect(x: 0, y: 0, width: 40*70/100, height: 40)
        btnNext.contentMode = .scaleAspectFill
        btnNext.clipsToBounds = true
        btnNext.semanticContentAttribute = .forceRightToLeft
        btnNext.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        btnNext.setImage(UIImage(named:"arrow_right_white_48")?.tint(with: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)), for: UIControlState())
        btnNext.addTarget(self, action: #selector(touchButton), for: .touchUpInside)
        let itemRight = UIBarButtonItem(customView: btnNext)
        
        btnCart = UIButton(type: .custom)
        btnCart.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btnCart.contentMode = .center
        btnCart.clipsToBounds = true
        btnCart.setImage(UIImage(named:"ic_cart_128")?.tint(with: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)), for: UIControlState.selected)
        btnCart.setImage(UIImage(named:"ic_cart_128"), for: UIControlState.normal)
        btnCart.addTarget(self, action: #selector(touchButton), for: .touchUpInside)
        let itemCart = UIBarButtonItem(customView: btnCart)
        
        self.navigationItem.rightBarButtonItems = [itemRight,itemCart]

        configView()
        configText()
        
        listernEvent()
        validate()
        
        loadOrderItem()
        self.navigationController!.view.alpha = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        navigationController?.navigationBar.shadowImage = #imageLiteral(resourceName: "TransparentPixel")
        navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "Pixel"), for: .default)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLaunch {
            isFirstLaunch = false
            self.navigationController?.view.transform = CGAffineTransform(translationX: 0, y: self.startPoint.y)
//            self.navigationController!.view.frame = CGRect(origin: self.startPoint, size: CGSize(width: 10, height: 10))
            UIView.animate(withDuration: 0.3, animations: {
                self.navigationController!.view.alpha = 1
                self.navigationController?.view.transform = .identity
//                self.navigationController!.view.frame = CGRect(origin:CGPoint.zero, size: UIScreen.main.bounds.size)
            })
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("App:NeedUpdatedQuanityProduct"), object: nil)
        navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
    }
    
    // MARK: - properties
    var order:Order? {
        didSet {
            
            // if edit, store temp order quantity old products
            // reset orderQuantity when it selected again
            if type == .edit {
                guard let order = order else {return}
                tempFirstSelected = order.products.filter({$0.orderQuantity > 0})
            }
        }
    }
    var tempFirstSelected:[Product]?
    var delegate:SelectOrderItemDelegate?
    var type:SelectOrderItemType = .new
    
    var startPoint:CGPoint = CGPoint.zero
    var isFirstLaunch:Bool = true
    
    var btnNext:UIButton!
    var btnCart:UIButton!
    
    // MARK: - closures
    
    
    // MARK: - outlet
    @IBOutlet weak var lblNote: UILabel!
    @IBOutlet weak var vwListProducts: ListProductView!
    
}
