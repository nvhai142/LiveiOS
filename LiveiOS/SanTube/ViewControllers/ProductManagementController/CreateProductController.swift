//
//  CreateProductController.swift
//  SanTube
//
//  Created by Hai NguyenV on 1/5/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

protocol CreateProductDelegate: class {
    func onSaveProduct(_ products: [Product])
	func onDeleteProduct(_ productIds: [String])
}

class CreateProductController: BaseController, CreateProductViewDelegate, PickPreviousProductDelegate {
	
    func onRemoveView(_ view: UIView?) {
		if let productView = view as? CreateProductView, let id = productView.productData?.id {
			if id.count > 0 {
				listDeletedProductIds.append(id)
			}
		}
		
        //let frame = scrollView.convert((view?.frame)!, from:stackContainer)
        view?.removeFromSuperview()
		listView.remove(at: listView.index(of: view as! CreateProductView)!)
    }
	
	func onStartUploading() {
		buttonProduct.isEnabled = false
	}
	
	func onUploadingSuccess() {
		checkUploadingStatus()
	}
	
	func onUploadingFailed() {
		let alert = UIAlertController(title: nil, message: "Upload image failed", preferredStyle: .alert)
		let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
		alert.addAction(ok)
		present(alert, animated: true, completion: nil)
		
		checkUploadingStatus()
	}
	
	func onPickPreviousProduct(_ products: [Product]) {

		_ = stackContainer.arrangedSubviews.map({ (view) in
			let v = view as! CreateProductView
			for product in listProducts{
				if product.isPickPrevious && product.id == v.productData?.id {
					onRemoveView(v)
					listProducts = listProducts.filter { $0.id != product.id }
					return
				}
			}
		})
		
		listPickPreviousProducts = products
		
		for data in products {
			if !listProducts.contains(where: { (product) -> Bool in
				product.id == data.id
			}) {
				var newData = data
				newData.isPickPrevious = true
				listProducts.append(newData)
				createProductForm(product: newData)
			}
		}
	}
	
	func checkUploadingStatus() {
		var allImageUploaded: Bool = true
		
		_ = stackContainer.arrangedSubviews.map({ (view) in
			let v = view as! CreateProductView
			if v.uploadingIndicator.isAnimating {
				allImageUploaded = false
			}
		})
		
		buttonProduct.isEnabled = allImageUploaded
	}
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var scrollView: UIScrollView!
    var buttonBack:UIButton!
    var buttonProduct:UIButton!
    @IBOutlet weak var stackContainer: UIStackView!
	@IBOutlet weak var buttonLeadingConstraint: NSLayoutConstraint!
	@IBOutlet weak var buttonTrailingConstraint: NSLayoutConstraint!
	
    weak var delegate: CreateProductDelegate?
    var listProducts: [Product] = []
	var listPickPreviousProducts: [Product] = []
    var listView = [CreateProductView]()
    var streamID:String?
	var listDeletedProductIds: [String] = []
	var scrollOpenEditIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        buttonBack = UIButton(type: .custom)
        buttonBack.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        buttonBack.semanticContentAttribute = .forceLeftToRight
        buttonBack.setImage(UIImage(named:"icon_back_product")?.tint(with: UIColor.white), for: UIControlState())
        buttonBack.addTarget(self, action: #selector(actionBack(_:)), for: .touchUpInside)
        let itemBack = UIBarButtonItem(customView: buttonBack)
        self.navigationItem.leftBarButtonItems = [itemBack]
        
        buttonProduct = UIButton(type: .custom)
        buttonProduct.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        buttonProduct.contentMode = .scaleAspectFill
        buttonProduct.clipsToBounds = true
        buttonProduct.semanticContentAttribute = .forceLeftToRight
        buttonProduct.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 0)
        buttonProduct.setTitle("Save".localized().capitalized, for: UIControlState())
        buttonProduct.addTarget(self, action: #selector(actionSaveProduct(_:)), for: .touchUpInside)
        let itemProduct = UIBarButtonItem(customView: buttonProduct)
        self.navigationItem.rightBarButtonItems = [itemProduct]
        
        if listProducts.count == 0 {
            createProductForm(product: nil)
        }else{
            for data in listProducts{
                createProductForm(product: data)
            }
        }
        bottomConstraint.constant = 10
		
		let sideSpacing = ((UIApplication.shared.keyWindow?.bounds.width)! - 290) / 3 // 290 = 2 buttons width (150 + 140)
		buttonLeadingConstraint.constant = sideSpacing
		buttonTrailingConstraint.constant = sideSpacing
		
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardHideNotification(notification:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if scrollOpenEditIndex > 0 {
			let bottomOffset = CGPoint(x: 0, y: CGFloat(scrollOpenEditIndex + 1) * 375 - self.scrollView.bounds.height)
			self.scrollView.setContentOffset(bottomOffset, animated: true)
			scrollOpenEditIndex = 0
		}
	}
    
    func createProductForm(product:Product!){
        let productView = CreateProductView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: 375))
        productView.delegate = self
		
        if product != nil{
            productView.productData = product
            productView.setDataProduct(product: product)
        }
        
        stackContainer.addArrangedSubview(productView)
        listView.append(productView)
		
		if stackContainer.arrangedSubviews.count > 1 {
			let bottomOffset = CGPoint(x: 0, y: CGFloat(stackContainer.arrangedSubviews.count) * productView.frame.height - scrollView.bounds.height)
			scrollView.setContentOffset(bottomOffset, animated: true)
		}
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //------- keyboard handle ------
    func keyboardNotification(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if bottomConstraint.constant == 10{
                print("\(keyboardSize.height)")
                bottomConstraint.constant = 210
            }
        }
    }
    func keyboardHideNotification(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if bottomConstraint.constant != 10{
                bottomConstraint.constant = 10
            }
        }
    }
    func keyboardWillChangeFrame(notification:NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            if bottomConstraint.constant == 10{
                print("\(keyboardRectangle.size.height)")
                bottomConstraint.constant = 210
            }else if bottomConstraint.constant != 10{
                bottomConstraint.constant = 10
            }
        }
    }
    func onShowKeyboard(_ view: UIView?){
        let frame = scrollView.convert((view?.frame)!, from:stackContainer)
        scrollView.setContentOffset(CGPoint(x:0.0,y:frame.origin.y+100), animated: true)
        
    }
    func onHideKeyboard(_ view: UIView?){
        let frame = scrollView.convert((view?.frame)!, from:stackContainer)
        scrollView.setContentOffset(CGPoint(x:0.0,y:frame.origin.y), animated: true)
    }
    //////
    func actionBack(_ sender: Any) {
		let alert = UIAlertController(title: nil, message: "Discard changes, if any?", preferredStyle: .alert)
		
		let yes = UIAlertAction(title: "Yes".localized(), style: .default, handler: { [unowned self] (action) in
			self.navigationController?.popViewController(animated: true)
		})
		
		let no = UIAlertAction(title: "No".localized(), style: .cancel, handler: nil)
		
		alert.addAction(yes)
		alert.addAction(no)
		present(alert, animated: true, completion: nil)
    }
	
    func actionSaveProduct(_ sender: Any) {
        
        var listData = [Product]()
        for view in listView {
            let product = view.prepareDataToUpload()
            if product != nil {
				if (product?.price)! < Float(0.0) {
					let alert = UIAlertController(title: nil, message: "Please input price for all products", preferredStyle: .alert)
					let ok = UIAlertAction(title: "OK", style: .cancel, handler: { [unowned self] (action) in
						let viewIndex = self.listView.index(of: view)?.toIntMax()
						if viewIndex! > 0 {
							let bottomOffset = CGPoint(x: 0, y: CGFloat(viewIndex! + 1) * view.frame.height - self.scrollView.bounds.height)
							self.scrollView.setContentOffset(bottomOffset, animated: true)
						}
					})
					
					alert.addAction(ok)
					present(alert, animated: true, completion: nil)
					
					return
				}
				
				if product!.image == "" {
					let alert = UIAlertController(title: nil, message: "Please set image for all products", preferredStyle: .alert)
					let ok = UIAlertAction(title: "OK", style: .cancel, handler: { [unowned self] (action) in
						let viewIndex = self.listView.index(of: view)?.toIntMax()
						if viewIndex! > 0 {
							let bottomOffset = CGPoint(x: 0, y: CGFloat(viewIndex! + 1) * view.frame.height - self.scrollView.bounds.height)
							self.scrollView.setContentOffset(bottomOffset, animated: true)
						}
					})
					
					alert.addAction(ok)
					present(alert, animated: true, completion: nil)
					
					return
				}
				
                listData.append(product!)
            }
        }
		
        if listData.count > 0 {
            guard let user = Account.current else {return}
			
			for i in 0 ..< listData.count {
				if listData[i].isPickPrevious {
					listData[i].id = ""
				}
			}
			
            Server.shared.createProducts(userId: user.id, streamId: self.streamID, products: listData.flatMap{$0.toDict()}) { [weak self] result, error in
                if result != nil {
                     self?.delegate?.onSaveProduct(result!)
                     self?.navigationController?.popViewController(animated: true)
                }else{
                    
                }
            }
        }
		else if listDeletedProductIds.count > 0 {
			Server.shared.deleteProducts(productIds: listDeletedProductIds, completion: { [unowned self] (result) in
				if result == nil { // success
					
				}
				self.delegate?.onDeleteProduct(self.listDeletedProductIds)
				self.listDeletedProductIds.removeAll()
				self.navigationController?.popViewController(animated: true)
			})
		}
		else {
			navigationController?.popViewController(animated: true)
		}
    }
    
    @IBAction func actionAddProduct(_ sender: Any) {
        createProductForm(product: nil)
    }
	
    @IBAction func actionPickPrevious(_ sender: Any) {
		let vc = PickPreviousProductController(nibName: "PickPreviousProductController", bundle: Bundle.main)
		vc.delegate = self
		vc.listPickPreviousProducts = self.listPickPreviousProducts
		self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
