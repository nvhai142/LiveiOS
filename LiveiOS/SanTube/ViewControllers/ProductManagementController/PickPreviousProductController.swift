//
//  PickPreviousProductController.swift
//  SanTube
//
//  Created by Duc Le on 1/31/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

protocol PickPreviousProductDelegate: class {
	func onPickPreviousProduct(_ products: [Product])
}

class PickPreviousProductController: BaseController, ListProductViewDelegate {
	
	@IBOutlet var listProductview: ListProductView!
	@IBOutlet weak var lblEmpty: UILabel!
	@IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
	
	weak var delegate: PickPreviousProductDelegate?
	var listProducts: [Product] = []
	var listPickPreviousProducts: [Product] = []
	var buttonBack: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
		navigationItem.title = "Recent Products"
		
		buttonBack = UIButton(type: .custom)
		buttonBack.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
		buttonBack.setImage(UIImage(named:"icon_back_product")?.tint(with: UIColor.white), for: UIControlState())
		buttonBack.addTarget(self, action: #selector(actionBack(_:)), for: .touchUpInside)
		let itemBack = UIBarButtonItem(customView: buttonBack)
		self.navigationItem.leftBarButtonItems = [itemBack]
		
		listProductview.delegate = self
		listProductview.orderItemViewType = .previous
		
		loadingIndicator.isHidden = false
		loadingIndicator.startAnimating()
		
		guard let user = Account.current else {return}
		Server.shared.getProducts(userId: user.id, streamId: nil) { [unowned self] (products, error) in
			if var listProducts = products {
				if listProducts.count > 20 {
					listProducts = Array(listProducts[0...19])
				}
				
				self.listProducts = listProducts
			}
			
			self.listProductview.listProducts = self.listProducts
			self.listProductview.listPickPreviousProducts = self.listPickPreviousProducts
			self.listProductview.collectView.reloadData()
			self.lblEmpty.isHidden = !(self.listProducts.count == 0)
			
			self.loadingIndicator.isHidden = true
			self.loadingIndicator.stopAnimating()
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// MARK: - IBAction
	func actionBack(_ sender: Any) {
		if listProducts.count > 0 {
			delegate?.onPickPreviousProduct(listProductview.listPickPreviousProducts)
		}
		
		navigationController?.popViewController(animated: true)
	}
	
	// MARK: - Delegate
	func onOpenEditProduct(_ product: Product?, at index: IndexPath) {
		// do nothing
	}
}
