//
//  CreateProductView.swift
//  SanTube
//
//  Created by Hai NguyenV on 1/9/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import TLPhotoPicker
import Photos

protocol CreateProductViewDelegate: class {
    func onRemoveView(_ view: UIView?)
	func onStartUploading()
	func onUploadingSuccess()
	func onUploadingFailed()
	func onShowKeyboard(_ view: UIView?)
    func onHideKeyboard(_ view: UIView?)
}

class CreateProductView: UIView,TLPhotosPickerViewControllerDelegate, UITextFieldDelegate {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var imvProduct: UIImageView!
    @IBOutlet weak var imvIconCamera: UIImageView!
	@IBOutlet weak var uploadingIndicator: UIActivityIndicatorView!
	
    @IBOutlet var imvIconCameraChoise: UIImageView!
    @IBOutlet weak var tfProductname: UITextField!
    @IBOutlet weak var tfQuantity: UITextField!
    @IBOutlet weak var tfPrice: UITextField!
    var tapGesture:UITapGestureRecognizer?
    var tapGestureView:UITapGestureRecognizer?
    weak var delegate: CreateProductViewDelegate?
    var selectedAssets = [TLPHAsset]()
    var productData: Product?
	var editingPrice: String?
	
	@IBOutlet weak var vwLimitNumber: UIView!
	@IBOutlet weak var btnLimitCheck: UIButton!
	@IBOutlet weak var btnLimitDown: UIButton!
	@IBOutlet weak var btnLimitUp: UIButton!
	@IBOutlet weak var tfLimitNumber: UITextField!
	let uncheckImage = UIImage(named: "ic_circle")?.tint(with: #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1))
	let checkedImage = #imageLiteral(resourceName: "ic_check_circle_128").tint(with: #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1))
	var limitChecked: Bool = false
	var limitNumber: Int = 1
	
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit(){
        Bundle.main.loadNibNamed("CreateProductView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        
        imvProduct.layer.borderWidth = 1
        imvProduct.layer.borderColor = UIColor.darkGray.cgColor
        imvProduct.layer.cornerRadius = 5.0
        imvProduct.layer.masksToBounds = true
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.touchView(_:)))
        tapGesture?.cancelsTouchesInView = true
        if let tap = tapGesture {
            imvProduct.addGestureRecognizer(tap)
        }
        tapGestureView = UITapGestureRecognizer(target: self, action: #selector(self.touchViewMain(_:)))
        //tapGestureView?.cancelsTouchesInView = true
        if let tap = tapGestureView {
            self.addGestureRecognizer(tap)
        }
		
		uploadingIndicator.isHidden = true
		uploadingIndicator.stopAnimating()
		
		let substractImage = #imageLiteral(resourceName: "ic_substract").tint(with: #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1))
		let plusImage = #imageLiteral(resourceName: "ic_plus").tint(with: #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1))
		btnLimitDown.setImage(substractImage, for: .normal)
		btnLimitUp.setImage(plusImage, for: .normal)
		btnLimitCheck.setImage(uncheckImage, for: .normal)
		vwLimitNumber.isHidden = !limitChecked
		
        if productData != nil {
            tfProductname.text = productData?.name
			editingPrice = String.init(format: "%.0f", (productData?.price)!)
            tfPrice.text = CGFloat((editingPrice! as NSString).floatValue).toPrice()
            tfQuantity.text = String(describing: productData?.quantity)
			limitChecked = ((productData?.limitPerPerson)! > 0)
			btnLimitCheck.setImage((limitChecked ? checkedImage : uncheckImage), for: .normal)
			vwLimitNumber.isHidden = !limitChecked
			limitNumber = limitChecked ? (productData?.limitPerPerson)! : 1
			tfLimitNumber.text = String(limitNumber)
            imvProduct.loadImageUsingCacheWithURLString((productData?.image)!, size: nil, placeHolder: nil, false) {[weak self] image in
                guard let img = image, let _self = self else {return}
                _self.imvProduct.image = img.withRenderingMode(.alwaysTemplate)
            }
        }
    }
    
    func setDataProduct(product: Product){
        self.productData = product
        if productData != nil{
            tfProductname.text = productData?.name
			editingPrice = String.init(format: "%.0f", (productData?.price)!)
			tfPrice.text = CGFloat((editingPrice! as NSString).floatValue).toPrice()
            tfQuantity.text = productData?.quantity.description
			limitChecked = ((productData?.limitPerPerson)! > 0)
			btnLimitCheck.setImage((limitChecked ? checkedImage : uncheckImage), for: .normal)
			vwLimitNumber.isHidden = !limitChecked
			limitNumber = limitChecked ? (productData?.limitPerPerson)! : 1
			tfLimitNumber.text = String(limitNumber)
            imvProduct.loadImageUsingCacheWithURLString((productData?.image)!, size: nil, placeHolder: nil, false) {[weak self] image in
                guard let img = image, let _self = self else {return}
                _self.imvProduct.image = img
                _self.imvIconCamera.isHidden = true
                _self.imvIconCameraChoise.isHidden = false
            }
        }
    }
	
    func prepareDataToUpload() -> Product? {
		touchViewMain(tapGestureView!)
		
        if productData != nil {
			if tfPrice.text?.count == 0 {
				productData?.price = -1
			}
			else {
				productData?.price = NSString(string: editingPrice!).floatValue
			}
			
            productData?.name = (tfProductname.text)!
            productData?.quantity = NSString(string: tfQuantity.text!).integerValue
			productData?.limitPerPerson = (limitChecked ? limitNumber : 0)
            if productData?.image.characters.count == 0 {
                return nil
            }
            return productData!
        }else{
            return nil
        }
    }
	
    @IBAction func actionRemove(_ sender: Any) {
        delegate?.onRemoveView(self)
    }
	
	@IBAction func actionLimitCheck(_ sender: Any) {
		limitChecked = !limitChecked
		btnLimitCheck.setImage((limitChecked ? checkedImage : uncheckImage), for: .normal)
		vwLimitNumber.isHidden = !limitChecked
	}
	
	@IBAction func actionLimitDown(_ sender: Any) {
		if limitNumber == 1 {
			return
		}
		
		limitNumber -= 1
		tfLimitNumber.text = String(limitNumber)
	}
	
	@IBAction func actionLimitUp(_ sender: Any) {
		limitNumber += 1
		tfLimitNumber.text = String(limitNumber)
	}
	
    func touchView(_ gesture:UIGestureRecognizer) {
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self
        
        var configure = TLPhotosPickerConfigure()
        configure.numberOfColumn = 3
        configure.maxSelectedAssets = 1
        configure.allowedVideo = false
        viewController.configure = configure
        viewController.selectedAssets = self.selectedAssets
        
        let currentController = self.getCurrentViewController()
        currentController?.present(viewController, animated: true, completion: nil)
    }
    func touchViewMain(_ gesture:UIGestureRecognizer) {
        tfPrice.resignFirstResponder()
        tfQuantity.resignFirstResponder()
        tfProductname.resignFirstResponder()
		tfLimitNumber.resignFirstResponder()
    }
    func getCurrentViewController() -> UIViewController? {
        
        if let rootController = UIApplication.shared.keyWindow?.rootViewController {
            var currentController: UIViewController! = rootController
            while( currentController.presentedViewController != nil ) {
                currentController = currentController.presentedViewController
            }
            return currentController
        }
        return nil
        
    }
    ////////////////
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // use selected order, fullresolution image
        self.selectedAssets = withTLPHAssets
        getFirstSelectedImage()
    }
    
    func getFirstSelectedImage() {
        if let asset = self.selectedAssets.first {
            
            if let image = asset.fullResolutionImage {
                self.imvProduct.image = image
                self.imvIconCamera.isHidden = true
                self.imvIconCameraChoise.isHidden = false
                if productData == nil {
                    productData = Product()
                }
                let imageView: UIImage = image.resizeImageWith(newSize: CGSize(width: 200, height: 200*(image.size.height/image.size.width)))
                if let imageData = UIImageJPEGRepresentation(imageView, 0.5) as NSData? {

                    imvProduct.isUserInteractionEnabled = false
					uploadingIndicator.isHidden = false
					uploadingIndicator.startAnimating()
					delegate?.onStartUploading()
					
                    Server.shared.uploadThumbStream(imageData: imageData as Data, { [weak self] result in
                        guard let _self = self else {return}
						
						_self.imvProduct.isUserInteractionEnabled = true
						_self.uploadingIndicator.isHidden = true
						_self.uploadingIndicator.stopAnimating()
						
                        switch result {
                        case .success(let data):
                            _self.productData?.image = (data["imageThumbUrl"] as? String)!
							_self.delegate?.onUploadingSuccess()
                        case .failure(.some(_)):
                            print("upload failed")
							_self.imvProduct.image = nil
							_self.delegate?.onUploadingFailed()
                        case .failure(.none):
                            print("upload failed")
							_self.imvProduct.image = nil
							_self.delegate?.onUploadingFailed()
                        }
						
                    })
                }
            }
        }
    }
    
    func dismissPhotoPicker(withPHAssets: [PHAsset]) {
        // if you want to used phasset.
    }
    
    func photoPickerDidCancel() {
        // cancel
    }
    
    func dismissComplete() {
        // picker dismiss completion
    }
    
    func didExceedMaximumNumberOfSelection(picker: TLPhotosPickerViewController) {
        
    }
    //----------------
    public func textFieldDidBeginEditing(_ textField: UITextField){
		if textField == tfPrice {
			tfPrice.text = editingPrice
		}
		
        delegate?.onShowKeyboard(self)
    }
    public func textFieldDidEndEditing(_ textField: UITextField){
		if textField == tfPrice {
			editingPrice = tfPrice.text
			tfPrice.text = CGFloat((editingPrice! as NSString).floatValue).toPrice()
		}
		
        delegate?.onHideKeyboard(self)
    }
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if textField == tfLimitNumber {
			let oldText: NSString = (textField.text ?? "") as NSString
			var newText: NSString = oldText.replacingCharacters(in: range, with: string) as NSString
			
			if newText.length == 0 || newText.integerValue == 0 {
				newText = "1"
				textField.text = newText as String
				limitNumber = 1
				return false
			}
			else if newText.integerValue > 9999 {
				newText = "9999"
				textField.text = newText as String
				limitNumber = 9999
				return false
			}
			
			limitNumber = newText.integerValue
			return true
		}
		
		return true
	}
}
