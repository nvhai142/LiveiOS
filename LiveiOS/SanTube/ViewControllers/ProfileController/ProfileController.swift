//
//  ProfileController.swift
//  BUUP
//
//  Created by Hai NguyenV on 10/31/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import TLPhotoPicker

let CHOSEN_OPTION_TITLE_COLOR = #colorLiteral(red: 0, green: 0.4549019608, blue: 1, alpha: 1)
let UNCHOSEN_OPTION_TITLE_COLOR = #colorLiteral(red: 0.4980392157, green: 0.4980392157, blue: 0.4980392157, alpha: 1)

enum PickingImageType {
	case cover
	case avatar
}

class ProfileController: BasePresentController, TLPhotosPickerViewControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

	@IBOutlet weak var cover: UIImageView!
	@IBOutlet weak var avatar: UIImageView!
	@IBOutlet weak var tfName: UITextField!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var lblEmail: UILabel!
	@IBOutlet weak var tfDOB: UITextField!
	@IBOutlet weak var btnMale: UIButton!
	@IBOutlet weak var btnFemale: UIButton!
	@IBOutlet weak var btnVietnamese: UIButton!
	@IBOutlet weak var btnEnglish: UIButton!
	@IBOutlet weak var tfWebsite: UITextField!
	@IBOutlet weak var tfPhone: UITextField!
	
	@IBOutlet weak var btnDismissKeyboard: UIButton!
	@IBOutlet weak var indicatorView: UIView!
	@IBOutlet weak var indicator: UIActivityIndicatorView!
	
	@IBOutlet weak var btnChangeCover: UIButton!
	@IBOutlet weak var iconChangeCover: UIImageView!
	@IBOutlet weak var btnChangeAvatar: UIButton!
	@IBOutlet weak var iconChangeAvatar: UIImageView!
	@IBOutlet weak var btnLogout: UIButton!
	@IBOutlet weak var btnEditName: UIButton!
	@IBOutlet weak var btnEditDOB: UIButton!
	@IBOutlet weak var btnEditWebsite: UIButton!
	@IBOutlet weak var btnEditPhone: UIButton!
	@IBOutlet weak var btnDone: UIButton!
	
    // MARK: - closures
    var onSignOut:(()->Void)?
    
	let datePicker = UIDatePicker()
	var pickedDate: Date = Date()
	
	var pickingImageType: PickingImageType = .cover
	var pickedCover: UIImage = UIImage()
	var pickedAvatar: UIImage = UIImage()
	var coverChanged: Bool = false
	var avatarChanged: Bool = false
	
	public var user: User? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        guard let acc = Account.current else {self.dismiss(animated: false, completion: nil); return }
        // Do any additional setup after loading the view.
		lblEmail.text = acc.email
		tfDOB.text = acc.dateOfBirth?.toString(dateFormat: "dd/MM/yyyy")
		tfDOB.isUserInteractionEnabled = false
		tfName.text = acc.name
		tfName.isUserInteractionEnabled = false
		tfWebsite.text = acc.website
		tfWebsite.isUserInteractionEnabled = false
		tfPhone.text = acc.phone
		tfPhone.isUserInteractionEnabled = false
		
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
		avatar.layer.cornerRadius = avatar.frame.width / 2
		avatar.layer.borderColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
		avatar.layer.borderWidth = 1
		avatar.loadImageUsingCacheWithURLString(acc.avatar, size: avatar.frame.size, placeHolder: nil) { [unowned self] (image) in
			if image != nil {
				self.pickedAvatar = image!
			}
		}
		
		cover.contentMode = .scaleAspectFill
		cover.clipsToBounds = true
		cover.loadImageUsingCacheWithURLString(acc.cover_image, size: nil, placeHolder: nil) { [unowned self] (image) in
			if image != nil {
				self.pickedCover = image!
			}
		}
		
		if acc.gender == "female" {
			btnMale.setTitleColor(UNCHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
			btnFemale.setTitleColor(CHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
		}
		else {
			btnMale.setTitleColor(CHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
			btnFemale.setTitleColor(UNCHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
		}
		
		if acc.language == "vi" {
			btnEnglish.setTitleColor(UNCHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
			btnVietnamese.setTitleColor(CHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
		}
		else {
			btnEnglish.setTitleColor(CHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
			btnVietnamese.setTitleColor(UNCHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
		}
		
		datePicker.datePickerMode = .date
		datePicker.maximumDate = Date()
		
		// Date Picker
		let btnCancel = UIButton(type: .custom)
		btnCancel.frame = CGRect(x: 0, y: 0, width: 40, height: 30)
		btnCancel.contentMode = .scaleAspectFill
        btnCancel.semanticContentAttribute = .forceLeftToRight
        btnCancel.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
		btnCancel.addTarget(self, action: #selector(self.cancelDatePicker), for: .touchUpInside)
		btnCancel.setImage(UIImage(named:"icon_back_product")?.tint(with: UIColor.white), for: UIControlState())
		let itemCancel = UIBarButtonItem(customView: btnCancel)
		
		let btnDone = UIButton(type: .custom)
		btnDone.frame = CGRect(x: 0, y: 0, width: 50, height: 30)
		btnDone.contentMode = .scaleAspectFill
		btnDone.clipsToBounds = true
		btnDone.addTarget(self, action: #selector(self.doneDatePicker), for: .touchUpInside)
		btnDone.setTitle("Done".localized().capitalized, for: UIControlState())
		btnDone.setTitleColor(UIColor(hex:"0x6599FF"), for: UIControlState())
		let itemDone = UIBarButtonItem(customView: btnDone)
		
		let space = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		let toolBar = UIToolbar.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: 44))
		toolBar.barTintColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
		toolBar.setItems([itemCancel, space, itemDone], animated: true)
		
		tfDOB.inputAccessoryView = toolBar
		tfDOB.inputView = datePicker
		
        title = "profile".localized().uppercased()
//        addDefaultMenu()
        configView()
		
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: .UIKeyboardDidShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        onDissmiss?()
//    }
    
    deinit {
		
        print("ProfileController deinit")
		
		NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - event
    @IBAction func logOut(_ sender: Any) {
        self.onSignOut?()
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func closeView(_ sender: Any) {
        onDissmiss?()
        self.dismiss(animated: false, completion: nil)
    }
    
	@IBAction func dismissKeyboard(_ sender: Any) {
		if tfName.isFirstResponder && tfName.text?.count == 0 {
			let alert = UIAlertController(title: nil, message: "Cannot set empty name", preferredStyle: .alert)
			let dismissAction = UIAlertAction(title: "OK", style: .cancel) { [unowned self] (action) in
				self.btnDismissKeyboard.isHidden = false
			}
			
			alert.addAction(dismissAction)
			self.present(alert, animated: true, completion: nil)
			
			return
		}
		
		tfName.isUserInteractionEnabled = false
		tfWebsite.isUserInteractionEnabled = false
		tfPhone.isUserInteractionEnabled = false
		self.view.endEditing(true)
	}
	
	@IBAction func editName(_ sender: Any) {
		
		tfName.isUserInteractionEnabled = true
		tfName.becomeFirstResponder()
		btnDismissKeyboard.isHidden = false
	}
	
	@IBAction func editDOB(_ sender: Any) {
		
		tfDOB.isUserInteractionEnabled = true
		tfDOB.becomeFirstResponder()
	}
	
	@IBAction func editWebsite(_ sender: Any) {
		
		tfWebsite.isUserInteractionEnabled = true
		tfWebsite.becomeFirstResponder()
		btnDismissKeyboard.isHidden = false
	}
	
	@IBAction func editPhone(_ sender: Any) {
		
		tfPhone.isUserInteractionEnabled = true
		tfPhone.becomeFirstResponder()
		btnDismissKeyboard.isHidden = false
	}
	
	@IBAction func selectGender(_ sender: UIButton) {
		
		switch sender.tag {
		case 101: // Male
			btnMale.setTitleColor(CHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
			btnFemale.setTitleColor(UNCHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
		case 102: // Female
			btnMale.setTitleColor(UNCHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
			btnFemale.setTitleColor(CHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
		default:
			return
		}
	}
	
	@IBAction func selectLanguage(_ sender: UIButton) {
		
		switch sender.tag {
		case 201: // Vietnamese
			btnVietnamese.setTitleColor(CHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
			btnEnglish.setTitleColor(UNCHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
		case 202: // English
			btnVietnamese.setTitleColor(UNCHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
			btnEnglish.setTitleColor(CHOSEN_OPTION_TITLE_COLOR, for: UIControlState())
		default:
			return
		}
	}
	
	@IBAction func changeCover(_ sender: Any) {
		
		pickingImageType = .cover
		showImagePicker()
	}
	
	@IBAction func changeAvatar(_ sender: Any) {
		
		pickingImageType = .avatar
		showImagePicker()
	}
	
	@IBAction func doneEditting(_ sender: Any) {
		
		var profileDict: [String: Any] = [:]
		profileDict.updateValue(tfName.text!, forKey: "name")
		profileDict.updateValue(pickedDate.toString(dateFormat: "yyyy-MM-dd"), forKey: "dateOfBirth")
		profileDict.updateValue((btnMale.currentTitleColor == CHOSEN_OPTION_TITLE_COLOR ? "male" : "female"), forKey: "gender")
		profileDict.updateValue((btnVietnamese.currentTitleColor == CHOSEN_OPTION_TITLE_COLOR ? "vi" : "en"), forKey: "language")
		profileDict.updateValue(tfWebsite.text!, forKey: "website")
		profileDict.updateValue(tfPhone.text!, forKey: "phone")
		
		var coverData: Data? = nil
		var avatarData: Data? = nil
		
		if coverChanged {
			coverData = UIImageJPEGRepresentation(pickedCover, 0.3)
			coverChanged = false
		}
		
		if avatarChanged {
			avatarData = UIImageJPEGRepresentation(pickedAvatar, 0.3)
		}

		indicatorView.isHidden = false
		indicator.startAnimating()
		
		Server.shared.updateUserProfile(coverData: coverData, avatarData: avatarData, profile: profileDict) { [unowned self] (result) in
			
			Server.shared.getCurrentUserProfile() { [unowned self] (result) in
				self.indicatorView.isHidden = true
				self.indicator.stopAnimating()
				
				switch result {
				case .success(let data):
					self.saveUser(data: data)
				case .failure(.some(_)):
					print("get current user profile failed")
				case .failure(.none):
					print("get current user profile failed")
				}
			}
			
			let alert = UIAlertController(title: nil, message: "Update profile completed", preferredStyle: .alert)
			let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
			alert.addAction(dismissAction)
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	// MARK: - UITextFieldDelegate
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		
		if textField == tfName && textField.text?.count == 0 {
			let alert = UIAlertController(title: nil, message: "Cannot set empty name", preferredStyle: .alert)
			let dismissAction = UIAlertAction(title: "OK", style: .cancel) { [unowned self] (action) in
				self.btnDismissKeyboard.isHidden = false
			}
			
			alert.addAction(dismissAction)
			self.present(alert, animated: true, completion: nil)
			
			return false
		}
		
		self.view.endEditing(true)
		return true
	}
	
	// MARK: - TLPhotosPickerViewControllerDelegate
	func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
		// use selected order, fullresolution image
		if let asset = withTLPHAssets.first {
			if let image = asset.fullResolutionImage {
				switch pickingImageType {
				case .cover:
					pickedCover = image
					cover.image = image
					coverChanged = true
					
				case .avatar:
					pickedAvatar = image
					avatar.image = image
					avatarChanged = true
				}
			}
			else {
				print("Failed to select a photo")
			}
		}
		else {
			print("Failed to select a photo")
		}
	}
	
	// MARK: - private
    func configView() {
//        btnLogout.layer.cornerRadius = 7
//        btnLogout.setTitle("logout".localized().uppercased(), for: UIControlState())
//        btnLogout.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize20)
    }
    
    func addDefaultMenu () {
        
        // add right menu
        let btnCancel = UIButton(type: .custom)
        btnCancel.tag = 100
        btnCancel.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btnCancel.contentMode = .scaleAspectFill
        btnCancel.clipsToBounds = true
        btnCancel.semanticContentAttribute = .forceLeftToRight
        btnCancel.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        btnCancel.addTarget(self, action: #selector(self.menuPress(sender:)), for: .touchUpInside)
        btnCancel.setImage(UIImage(named:"arrow_left_white_48")?.tint(with: UIColor.white), for: UIControlState())
        let itemCancel = UIBarButtonItem(customView: btnCancel)
        self.navigationItem.leftBarButtonItem = itemCancel
    }
	
	func disableEditFunction() {
		btnChangeCover.isHidden = true
		iconChangeCover.isHidden = true
		btnChangeAvatar.isHidden = true
		iconChangeAvatar.isHidden = true
		btnLogout.isHidden = true
		btnEditName.isHidden = true
		btnEditDOB.isHidden = true
		btnEditWebsite.isHidden = true
		btnEditPhone.isHidden = true
		btnDone.isHidden = true
	}
	
	func saveUser(data: JSON) {
		AccountManager.saveUserWith(dictionary: data["data"] as! JSON, CoreDataStack.sharedInstance.persistentContainer.viewContext) { [unowned self] (success) in
			print("Save user \(success)")
			
			if self.avatarChanged {
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UpdateButtonProfile"), object: nil)
				self.avatarChanged = false
			}
		}
	}
	
	func showImagePicker() {
		
		let viewController = CustomPhotoPickerViewController()
		viewController.delegate = self
		viewController.didExceedMaximumNumberOfSelection = { (picker) in
			
		}
		
		var configure = TLPhotosPickerConfigure()
		configure.numberOfColumn = 3
		configure.maxSelectedAssets = 1
		configure.allowedVideo = false
		viewController.configure = configure
		
		present(viewController, animated: true, completion: nil)
	}
    
    @objc func menuPress(sender: UIButton) {
		
        if (sender.tag == 100) {
            self.dismiss(animated: true, completion: nil)
        }
		else {
            
        }
    }
	
	@objc func keyboardDidShow(notification: Notification) {
		
		if tfName.isFirstResponder {
			return
		}
		
		var rect: CGRect = CGRect.zero
		if tfDOB.isFirstResponder {
			rect = tfDOB.frame
		}
		else if tfWebsite.isFirstResponder {
			rect = tfWebsite.frame
		}
		else if tfPhone.isFirstResponder {
			rect = tfPhone.frame
		}
		
		let info = notification.userInfo!
		var kbRect: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
		kbRect = self.view.convert(kbRect, from: nil)
		
		let contentInsets: UIEdgeInsets = UIEdgeInsets.init(top: 0.0, left: 0.0, bottom: kbRect.size.height, right: 0.0)
		scrollView.contentInset = contentInsets
		scrollView.scrollIndicatorInsets = contentInsets
		
		if rect.maxY > self.view.frame.maxY - kbRect.height {
			scrollView.scrollRectToVisible(rect, animated: true)
		}
		
		btnDismissKeyboard.isHidden = false
	}
	
	@objc func keyboardWillHide(notification: Notification?) {
		
		scrollView.contentInset = UIEdgeInsets.zero
		scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
		
		btnDismissKeyboard.isHidden = true
	}
	
	@objc func cancelDatePicker() {
		tfDOB.isUserInteractionEnabled = false
		tfDOB.resignFirstResponder()
		keyboardWillHide(notification: nil)
	}
	
	@objc func doneDatePicker() {
		tfDOB.text = datePicker.date.toString(dateFormat: "dd/MM/yyyy")
		pickedDate = datePicker.date
		tfDOB.isUserInteractionEnabled = false
		tfDOB.resignFirstResponder()
		keyboardWillHide(notification: nil)
	}
}
