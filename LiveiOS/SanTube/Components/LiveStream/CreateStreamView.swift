//
//  CreateStreamView.swift
//  SanTube
//
//  Created by Hai NguyenV on 11/22/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

protocol CreateStreamViewDelegate: class {
    func onChooseCate(_ cateId: String?)
    func onCreateStream(_ cateID: String? , titleStream: String?,_ type:Bool?)
    func onCameraChange()
    func onUploadThumbClick()
    func onFacebookClick()
    func onBackClick()
    func onCreateProduct()
}
class CreateStreamView: UIView, UITextFieldDelegate {

    @IBOutlet weak var viewBg: UIView!
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var buttonCreate:  UIButton!
    @IBOutlet var contentView: UIView!
    weak var delegate: CreateStreamViewDelegate?
    @IBOutlet weak var tfTitle: UITextField!
    @IBOutlet weak var btnUploadThumb: UIButton!
   // @IBOutlet weak var imgCate: UIImageView!
    @IBOutlet weak var lbCatename: UILabel!
    @IBOutlet weak var btnCreateProduct: UIButton!
    @IBOutlet weak var btnFilter: UIButton!
    @IBOutlet weak var btnTypeStream: UIButton!
    @IBOutlet weak var lblOpenShop: UILabel!
    
    // view chooseType
    @IBOutlet weak var vwChooseType: UIView!
    @IBOutlet weak var btnChooseTypePublic: UIButton!
    @IBOutlet weak var btnChooseTypePrivate: UIButton!
    @IBOutlet weak var imvCheckedPublic: UIImageView!
    @IBOutlet weak var imvCheckedPrivate: UIImageView!
    @IBOutlet weak var imvTargetChooseType: UIImageView!
    @IBOutlet weak var vwStoreButtonType: UIView!
    
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var cardID: String!
    var titleStream: String!
    
    var tapGesture:UITapGestureRecognizer?
    
    var shouldStartTutorial:(()->Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    private func commonInit(){
        Bundle.main.loadNibNamed("CreateStreamView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        
        buttonCreate.layer.cornerRadius = buttonCreate.frame.size.height/2
        buttonCreate.layer.masksToBounds = true
      //  imgCate.backgroundColor = UIColor.clear
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.touchView(_:)))
        tapGesture?.cancelsTouchesInView = true
        if let tap = tapGesture {
            viewBg.addGestureRecognizer(tap)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardHideNotification(notification:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: NSNotification.Name.UIKeyboardDidChangeFrame, object: nil)
        
        buttonCreate.isEnabled = false
        buttonCreate.alpha = 0.5
       // tfTitle.becomeFirstResponder()
        tfTitle.autocapitalizationType = .words
        tfTitle.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        tfTitle.attributedPlaceholder = NSAttributedString(string: "Enter your stream title", attributes: [NSForegroundColorAttributeName: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)])
        tfTitle.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        tfTitle.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        btnTypeStream.setImage(#imageLiteral(resourceName: "ic_earth").resizeImageWith(newSize: CGSize(width: 25, height: 25)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
        btnTypeStream.addTarget(self, action: #selector(actionTypeStream(_:)), for: UIControlEvents.touchUpInside)
        
        btnCreateProduct.layer.masksToBounds = true
        btnCreateProduct.layer.cornerRadius = btnCreateProduct.frame.size.width/2
        btnCreateProduct.backgroundColor = #colorLiteral(red: 0.9882352941, green: 0.8078431373, blue: 0.1843137255, alpha: 1)
        btnCreateProduct.setImage(#imageLiteral(resourceName: "open_shop").resizeImageWith(newSize: CGSize(width: 24, height: 24)).tint(with: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)), for: UIControlState())
        
        // choose type for Stream
        vwChooseType.isHidden = true
        vwChooseType.layer.masksToBounds = true
        vwChooseType.layer.cornerRadius = 5
        vwStoreButtonType.layer.masksToBounds = true
        vwStoreButtonType.layer.cornerRadius = 5
        imvTargetChooseType.image = #imageLiteral(resourceName: "ic_triangle_down").resizeImageWith(newSize: CGSize(width: 10, height: 10)).tint(with: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5))
        btnChooseTypePublic.setImage(#imageLiteral(resourceName: "ic_earth").resizeImageWith(newSize: CGSize(width: 20, height: 20)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
        btnChooseTypePrivate.setImage(#imageLiteral(resourceName: "ic_private").resizeImageWith(newSize: CGSize(width: 20, height: 20)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
        
        imvCheckedPrivate.image = nil
        imvCheckedPublic.image = #imageLiteral(resourceName: "ic_check_white_96").resizeImageWith(newSize: CGSize(width: 15, height: 15))
        
        btnChooseTypePublic.addTarget(self, action: #selector(actionTypeStream(_:)), for: UIControlEvents.touchUpInside)
        btnChooseTypePrivate.addTarget(self, action: #selector(actionTypeStream(_:)), for: UIControlEvents.touchUpInside)
    }
    deinit {
        if let tap = tapGesture {
            viewBg.removeGestureRecognizer(tap)
        }
    }
    func keyboardNotification(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if bottomConstraint.constant == 0{
                bottomConstraint.constant += keyboardSize.height
            }
        }
        self.shouldStartTutorial?()
    }
    func keyboardHideNotification(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if bottomConstraint.constant != 0{
                bottomConstraint.constant = 0
            }
        }
    }
    func keyboardWillChangeFrame(notification:NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            if bottomConstraint.constant == 0{
                bottomConstraint.constant += keyboardRectangle.size.height
            }else if bottomConstraint.constant != 0{
                bottomConstraint.constant = 0
            }
        }
    }
    
    func actionTypeStream(_ sender: UIButton) {
        if sender.isEqual(btnChooseTypePrivate) {
            imvCheckedPublic.image = nil
            imvCheckedPrivate.image = #imageLiteral(resourceName: "ic_check_white_96").resizeImageWith(newSize: CGSize(width: 15, height: 15))
            btnTypeStream.setImage(#imageLiteral(resourceName: "ic_private").resizeImageWith(newSize: CGSize(width: 25, height: 25)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
            btnTypeStream.isSelected = true
        } else if sender.isEqual(btnChooseTypePublic) {
            imvCheckedPrivate.image = nil
            imvCheckedPublic.image = #imageLiteral(resourceName: "ic_check_white_96").resizeImageWith(newSize: CGSize(width: 15, height: 15))
            btnTypeStream.setImage(#imageLiteral(resourceName: "ic_earth").resizeImageWith(newSize: CGSize(width: 25, height: 25)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
            btnTypeStream.isSelected = false
        }
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.vwChooseType.isHidden = !self.vwChooseType.isHidden
        }, completion: nil)
    }
    
    func touchView(_ gesture:UIGestureRecognizer) {
        self.tfTitle.resignFirstResponder()
    }
    @IBAction func actionBackView(_ sender: Any) {
        delegate?.onBackClick()
    }
    @IBAction func actionCamera(_ sender: Any) {
        delegate?.onCameraChange()
    }
    @IBAction func actionUploadThumb(_ sender: Any) {
        delegate?.onUploadThumbClick()
    }
    @IBAction func actionCreated(_ sender: UIButton) {
        self.titleStream = tfTitle.text
        if self.cardID?.isEmpty == false && self.titleStream?.isEmpty == false  {
            delegate?.onCreateStream(cardID, titleStream: titleStream, btnTypeStream.isSelected)
        }
    }
    @IBAction func actionCreateProduct(_ sender: UIButton) {
        delegate?.onCreateProduct()
    }
    /*
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
        self.titleStream = textField.text
        if self.cardID?.isEmpty == false && self.titleStream?.isEmpty == false  {
            buttonCreate.isEnabled = true
            buttonCreate.alpha = 1.0
        }else{
            buttonCreate.isEnabled = false
            buttonCreate.alpha = 0.5
        }
        return true
    }
    */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        self.titleStream = tfTitle.text
        if self.cardID?.isEmpty == false && self.titleStream?.isEmpty == false  {
            buttonCreate.isEnabled = true
            buttonCreate.alpha = 1.0
        }
        return true
    }
    func textFieldDidChange(_ textField: UITextField) {
        self.titleStream = textField.text
        if self.cardID?.isEmpty == false && self.titleStream?.isEmpty == false  {
            buttonCreate.isEnabled = true
            buttonCreate.alpha = 1.0
        }else{
            buttonCreate.isEnabled = false
            buttonCreate.alpha = 0.5
        }
    }
    
    
}
