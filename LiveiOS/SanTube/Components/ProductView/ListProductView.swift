//
//  ListProductView.swift
//  SanTube
//
//  Created by Hai NguyenV on 1/5/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

fileprivate let column = CGFloat(3)
fileprivate let space = CGFloat(10)
fileprivate let height = CGFloat(240)

protocol ListProductViewDelegate: class {
	func onOpenEditProduct(_ product: Product?, at index: IndexPath)
}

class ListProductView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var collectView: UICollectionView!
    weak var delegate: ListProductViewDelegate?
    var listProducts:[Product] = []
    
    var orderItemViewType:OrderItemViewType = .view
    var listSelectedProducts:[Product] = []
	var listPickPreviousProducts:[Product] = []
    var onListProductSelected:(([Product])->Void)?
    var onChoseProduct:((Product,OrderItemView)->Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit(){
        Bundle.main.loadNibNamed("ListProductView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        
        collectView.register(UINib(nibName: "ProductItemCollectionCell", bundle: Bundle.main), forCellWithReuseIdentifier: "ProductCell")
        
        collectView.reloadData()
    }
    
    func reloadData(){
        collectView.reloadData()
    }

}
// MARK: - Extension Collectview delegate
extension ListProductView:UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listProducts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectView.dequeueReusableCell(withReuseIdentifier: "ProductCell", for: indexPath) as! ProductItemCollectionCell
        
        cell.onSelect = {[weak self] product, isSelected, orderItemView in
            guard let _self = self else {return}
            if isSelected {
                _self.listSelectedProducts.append(product)
                _self.onChoseProduct?(product,orderItemView)
            } else {
                var index:Int = -1
                for (i,item) in _self.listSelectedProducts.enumerated() {
                    if item.id == product.id {
                        index = i
                        break
                    }
                }
                if index > -1 && index < _self.listSelectedProducts.count {
                    _self.listSelectedProducts.remove(at: index)
                }
            }
            _self.onListProductSelected?(_self.listSelectedProducts)
        }
        
        let item = self.listProducts[indexPath.row]
		let isCheck = listPickPreviousProducts.contains(where: { (product) -> Bool in
			product.id == item.id
		})
		
        cell.load(product: item, check: isCheck, self.orderItemViewType)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

		let item = self.listProducts[indexPath.row]
		
		if orderItemViewType == .previous {
			if listPickPreviousProducts.contains(where: { (product) -> Bool in
				product.id == item.id
			}) {
				listPickPreviousProducts.remove(at: listPickPreviousProducts.index(where: { (product) -> Bool in
					product.id == item.id
				})!)
			}
			else {
				listPickPreviousProducts.append(item)
			}
		}
		
		delegate?.onOpenEditProduct(item, at: indexPath)
		self.collectView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let realspace = space * (column - 1)
        
        let width = (collectionView.frame.size.width - realspace)/3 - 5/3
        return CGSize(width:width, height: orderItemViewType == .selected ? 245 : height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(space)
    }
}
