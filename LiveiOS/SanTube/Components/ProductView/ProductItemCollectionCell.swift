//
//  ProductItemCollectionCell.swift
//  SanTube
//
//  Created by Hai NguyenV on 1/8/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class ProductItemCollectionCell: UICollectionViewCell {

    // MARK: - outlet
    @IBOutlet weak var itemView: OrderItemView!
    
    // MARK: - closures
    var onSelect:((Product,Bool,OrderItemView)->Void)?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        itemView.onSelect = {[weak self] product, isSelected,view in
            guard let _self = self else {return}
            _self.onSelect?(product,isSelected,view)
        }
    }
    // MARK: - interface
    func load(product:Product, check:Bool,_ type:OrderItemViewType = .view) {
        itemView.loadProduct(product: product, type)
		if type == .previous {
			itemView.setChecked(check, 2, CGSize(width: 20, height: 20))
		}
    }
    
    override func prepareForReuse() {
        itemView.resetState()
        itemView.onSelect = nil
    }
}
