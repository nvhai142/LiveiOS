//
//  ListProductController.swift
//  SanTube
//
//  Created by Hai NguyenV on 1/4/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit
protocol ListProductDelegate: class {
    func onOpenShop(_ products: [Product])
}
class ListProductController: BaseController,CreateProductDelegate,ListProductViewDelegate {
    
    func onSaveProduct(_ products: [Product]) {
        listProductview.listProducts = products
        listProductview.collectView.reloadData()
        listProduct = products
    }
	
	func onDeleteProduct(_ productIds: [String]) {
		listProduct = listProduct.filter { (product) -> Bool in
			if !productIds.contains(product.id) {
				return true
			}
			
			return false
		}
		
		listProductview.listProducts = listProduct
		listProductview.collectView.reloadData()
	}
    
    var buttonBack:UIButton!
    var buttonProduct:UIButton!
    @IBOutlet var listProductview:ListProductView!
    var listProduct:[Product] = []
    weak var delegate: ListProductDelegate?
    var streamID:String?
	var appearFirstTime: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // back
        listProductview.delegate = self
        buttonBack = UIButton(type: .custom)
        buttonBack.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        buttonBack.setImage(UIImage(named:"icon_back_product")?.tint(with: UIColor.white), for: UIControlState())
        buttonBack.addTarget(self, action: #selector(actionBack(_:)), for: .touchUpInside)
        let itemBack = UIBarButtonItem(customView: buttonBack)
        self.navigationItem.leftBarButtonItems = [itemBack]
        
        buttonProduct = UIButton(type: .custom)
        buttonProduct.frame = CGRect(x: 0, y: 0, width: 30, height: 40)
        buttonProduct.clipsToBounds = true
        buttonProduct.semanticContentAttribute = .forceLeftToRight
        buttonProduct.setImage(UIImage(named:"manager_product")?.tint(with: UIColor.white), for: UIControlState())
        buttonProduct.addTarget(self, action: #selector(actionCreateProduct(_:)), for: .touchUpInside)
        let itemProduct = UIBarButtonItem(customView: buttonProduct)
        self.navigationItem.rightBarButtonItems = [itemProduct]
        
        listProductview.listProducts = listProduct
        listProductview.collectView.reloadData()
        
        self.navigationItem.title = "List Products"
		
		if listProduct.count == 0 {
			actionCreateProduct(buttonProduct)
		}
		
		appearFirstTime = true
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if appearFirstTime {
			appearFirstTime = false
		}
		else {
			if listProduct.count == 0 {
				navigationController?.dismiss(animated: true, completion: nil)
			}
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
     func actionBack(_ sender: Any) {
        if listProduct.count > 0 {
            delegate?.onOpenShop(listProduct)
        }
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    func actionCreateProduct(_ sender: Any) {
        let vc = CreateProductController(nibName: "CreateProductController", bundle: Bundle.main)
        vc.streamID = self.streamID
        vc.delegate = self
        vc.delegate = self
        vc.listProducts = self.listProduct
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
	func onOpenEditProduct(_ product: Product?, at index: IndexPath) {
        let vc = CreateProductController(nibName: "CreateProductController", bundle: Bundle.main)
        vc.streamID = self.streamID
        vc.delegate = self
        vc.delegate = self
        vc.listProducts = self.listProduct
		vc.scrollOpenEditIndex = index.row
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
