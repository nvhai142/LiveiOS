//
//  ShopProductView.swift
//  SanTube
//
//  Created by Hai NguyenV on 1/12/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

protocol ShopProductViewDelegate: class {
    func onRemoveShopView()
    func onChangePublic()
}
class ShopProductView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var btnPublic: UIButton!
    var listProducts:[Product] = []
    weak var delegate: ShopProductViewDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("ShopProductView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        
        btnPublic.layer.cornerRadius = 5.0
        btnPublic.layer.masksToBounds = true
    }
    func setShopData(_ products:[Product]){
        if products.count > 0 {
            for data in listProducts{
                createProductItem(product: data)
            }
        }
    }
    func reloadShopData(){
        _ = stackContainer.arrangedSubviews.map({ (view) in
            let v = view as! OrderItemView
            for product in listProducts{
                if Int(product.id)! == v.tag{
                    v.loadProduct(product: product, .shopOwner)
                }
            }
        })
    }
    func createProductItem(product:Product!){
        let v = OrderItemView(frame:CGRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 200)))
        stackContainer.addArrangedSubview(v)
        v.tag = Int(product.id)!
        v.loadProduct(product: product, .shopOwner)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
    @IBAction func actionPublic(_ sender: Any) {
        btnPublic.isSelected = !btnPublic.isSelected
        delegate?.onChangePublic()
    }
    @IBAction func actionClose(_ sender: Any) {
        delegate?.onRemoveShopView()
    }
}
