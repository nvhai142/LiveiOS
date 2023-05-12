//
//  OrderItem.swift
//  SanTube
//
//  Created by Dai Pham on 1/8/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

enum OrderItemViewType {
    case edit
    case view
	case previous
    case selected
    case shop
    case shopOwner
    case viewHistory
}

class OrderItemView: UIView {

    // MARK: - api
    func loadProduct(product:Product,_ type:OrderItemViewType = .view) {
        
        self.type = type
        
        self.product = product
        lblName.text = product.name
        lblPrice.text = "\(CGFloat(product.price).toPrice()) VND"
        lblProductQuantity.text = "\("quantity".localized().capitalized): \(product.quantity)"
        lblProductQuantity.isHidden = (product.quantity == 0)
        lblQuantity.text = "\(product.quantity)"
        imvProduct.loadImageUsingCacheWithURLString(product.image, size: nil, placeHolder: nil, false) {[weak self] image in
            guard let _self = self else {return}
            _self.imvProduct.image = image
        }
        
        updateQuantity()
        
        updateViewForType()
        
        // selected if edit => detect order is choose before
        if type == .selected {
            if product.orderQuantity > 0 {
                actionButton(btnBuy)
            }
        }
        
        if product.quantity <= 0 {
            barprogressQuantity.isHidden = true
            return
        }
        
        // Int/Int will be equal 0
        var progress = CGFloat(Double(product.noOfSell) * 1.0 / Double(product.quantity) * 1.0)
        if progress > 1 {
            progress = 1
        }
        
        barprogressQuantity.progress = Float(progress)
    }
    
    func resetState() {
        lblProductQuantity.isHidden = false
        vwControlQuantity.isHidden = false
        vwControlSelected.isHidden = false
        barprogressQuantity.isHidden = false
        self.isSelected = false
        type = .view
        self.product = nil
        imvProduct.image = nil
        updateViewForType()
    }
    
    // MARK: - action button
    func actionButton(_ sender:UIButton) {
        if sender.isEqual(btnDiv) || sender.isEqual(btnPlus) {
            updateQuantity(sender.isEqual(btnDiv) ? 0 : 1)
        } else if sender.isEqual(btnBuy) {
            guard let pro = self.product else {return}
            self.isSelected = !self.isSelected
            self.onSelect?(pro,self.isSelected,self)
            btnBuy.isSelected = self.isSelected
            btnBuy.backgroundColor = self.isSelected ? #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1) : #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
    }
    
    // MARK: - listernEvent
    
    // MARK: - private
    private func updateQuantity(_ oper:Int? = nil) {
        guard var product = self.product else { return }
        var orderQuantity = product.orderQuantity
        if let o = oper {
            if o == 0  {
                orderQuantity -= 1
            } else if o == 1 {
                orderQuantity += 1
            }
        }
        if orderQuantity < 1 {
            orderQuantity = 1
        }
        if product.limitPerPerson != 0{
            if orderQuantity > product.limitPerPerson {
                orderQuantity = product.limitPerPerson
            }
        }
        product.orderQuantity = orderQuantity
        self.product = product
        lblQuantity.text = "\(orderQuantity)"
        onUpdateOrderQuantity?(self.product)
    }
    
    private func updateViewForType() {
        self.setBag(0)
        switch type {
        case .edit:
            vwControlSelected.isHidden = true
            vwControlQuantity.isHidden = true
            barprogressQuantity.isHidden = true
            lblProductQuantity.isHidden = true
            if let product = product {
                self.setBag(product.orderQuantity,2,CGSize(width: 20, height: 20))
            }
		case .previous:
			vwControlSelected.isHidden = true
			vwControlQuantity.isHidden = true
			vwControlProcess.isHidden = true
			lblProductQuantity.isHidden = (product?.quantity == 0)
			
        case .view: // show list product when create stream
            vwControlSelected.isHidden = true
            vwControlQuantity.isHidden = true
            vwControlProcess.isHidden = true
            lblProductQuantity.isHidden = (product?.quantity == 0)
            
        case .selected: // show list product when order
            vwControlSelected.isHidden = false
            vwControlQuantity.isHidden = true
            barprogressQuantity.isHidden = false
            lblProductQuantity.isHidden = true
        case .shop:
            vwControlSelected.isHidden = true // button select
            vwControlQuantity.isHidden = false // change quantity
            vwControlProcess.isHidden = true  // view processs
            lblProductQuantity.isHidden = true // display label quantity
        case .shopOwner: // show list product for streamer check quantity
            vwControlSelected.isHidden = true // button select
            vwControlQuantity.isHidden = true // change quantity
            barprogressQuantity.isHidden = false  // processs
            lblProductQuantity.isHidden = true // display label quantity
        case .viewHistory: // show in order history
            vwControlSelected.isHidden = true
            vwControlQuantity.isHidden = true
            vwControlProcess.isHidden = true
            lblProductQuantity.isHidden = true
            if let product = product {
                self.setBag(product.orderQuantity,2,CGSize(width: 20, height: 20))
            }
        }
    }
    
    private func configView() {
        
        for btn in [btnDiv,btnPlus,btnBuy] {
            setupButton(button: btn!)
        }
        
        lblName.numberOfLines = 2
        
        lblName.font = UIFont.boldSystemFont(ofSize: fontSize15)
        lblPrice.font = UIFont.systemFont(ofSize: fontSize15)
        lblProductQuantity.font = UIFont.systemFont(ofSize: fontSize15)
        lblQuantity.font = UIFont.systemFont(ofSize: fontSize16)
        
        lblPrice.adjustsFontSizeToFitWidth = true
        lblQuantity.adjustsFontSizeToFitWidth = true
        
        btnPlus.setImage(#imageLiteral(resourceName: "ic_plus").withRenderingMode(.alwaysTemplate), for: UIControlState())
        btnDiv.setImage(#imageLiteral(resourceName: "ic_substract").withRenderingMode(.alwaysTemplate), for: UIControlState())
        
        btnPlus.imageView!.tintColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
        btnDiv.imageView!.tintColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
        
        imvProduct.layer.cornerRadius = 5
        
        btnBuy.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize17)
        btnBuy.setImage(nil, for: UIControlState.normal)
        btnBuy.setImage(#imageLiteral(resourceName: "ic_check_white_96"), for: UIControlState.selected)
        btnBuy.setTitle("buy".localized().uppercased(), for: UIControlState.normal)
        btnBuy.setTitle("", for: UIControlState.selected)
        btnBuy.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        btnBuy.layer.masksToBounds = true
        btnBuy.layer.cornerRadius = 5
        btnBuy.layer.borderWidth = 1.5
        btnBuy.layer.borderColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
        btnBuy.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0), for: .selected)
        btnBuy.setTitleColor(#colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1), for: .normal)
    }
    
    private func setupButton(button:UIButton) {
        button.addTarget(self, action: #selector(actionButton), for: .touchUpInside)
        button.layer.masksToBounds = true
        var width:CGFloat = 30
        self.layoutIfNeeded()
        for constraint in button.constraints {
            if constraint.firstAttribute == .width && constraint.firstItem.isEqual(button) {
                width = constraint.constant
            }
        }
        button.layer.cornerRadius = width/2
    }
    
    func setNib() {
        Bundle.main.loadNibNamed("OrderItemView", owner: self, options: nil)
        guard let content = contentView else { return }
        content.frame = self.bounds
        content.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        content.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        content.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: content.bottomAnchor).isActive = true
        
        configView()
    }
    
    // MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setNib()
    }
    
    // MARK: - properties
    var type:OrderItemViewType = .view
    var product:Product?
    var isSelected:Bool = false
    
    // MARK: - closures
    var onSelect:((Product,Bool,OrderItemView)->Void)?
    var onUpdateOrderQuantity:((Product?)->Void)?
    
    // MARK: - outlet
    @IBOutlet weak var contentView: UIView?
    @IBOutlet weak var vwControlQuantity: UIView!
    @IBOutlet weak var imvProduct: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var btnDiv: UIButton!
    @IBOutlet weak var btnPlus: UIButton!
    @IBOutlet weak var lblQuantity: UILabel!
    @IBOutlet weak var lblProductQuantity: UILabel!
    @IBOutlet weak var vwControlSelected: UIView!
    @IBOutlet weak var btnBuy: UIButton!
    @IBOutlet var vwControlProcess: UIView!
    @IBOutlet weak var barprogressQuantity: UIProgressView!
    
}
