//
//  AuthenticController.swift
//  BUUP
//
//  Created by Dai Pham on 11/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

enum SupportAuthenticType{
    case register
    case forgot
}

class SupportAuthenticController: UIViewController {

    // MARK: - outlet
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var btnRequest: UIButton!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPassword: UITextField!
    @IBOutlet weak var lblTermOfUse: UITextView!
    @IBOutlet weak var icoCheck: UIImageView!
    
    @IBOutlet weak var txtEmailForgot: UITextField!
    @IBOutlet weak var lblNoteForgot: UILabel!
    
    @IBOutlet weak var btnBack: UIButton!
    
    
    @IBOutlet weak var stackRegister: UIStackView!
    @IBOutlet weak var stackForgot: UIStackView!
    
    
    // MARK: - properties
    var tapGesture:UITapGestureRecognizer?
    var type:SupportAuthenticType = .register
    var isConfirmPolicies:Bool = false
    var emailForgot:String?
    
    // MARK: - closures
    var onForgotSuccess:((String)->Void)?
    var onRegisterSuccess:(()->Void)?
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        // listern behavious keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if type == .register {
            stackForgot.removeFromSuperview()
        } else {
            stackRegister.removeFromSuperview()
        }
        
        // config
        configView()
        configText()
        refreshView()
        
        // add gesture to end edit
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard(_:)))
        scrollView.addGestureRecognizer(tapGesture!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if type == .register {
            icoCheck.addEvent {[weak self] in
                guard let _self = self else {return}
                _self.isConfirmPolicies = !_self.isConfirmPolicies
                _self.refreshView()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if type == .register {
            icoCheck.removeEvent()
        }
    }
    
    // MARK: - event button
    @IBAction func touchButton(_ sender: UIButton) {
        if sender.isEqual(btnBack) {
            self.navigationController?.popViewController(animated: true)
        } else if sender.isEqual(btnRequest) {
            if type == .register {
                validateRegister {email,password,confirmPW,name in
                    sender.startAnimation(activityIndicatorStyle: .white)
                    self.view.endEditing(true)
                    Server.shared.register(email: email,
                                           password: password,
                                           password_confirmation: confirmPW, name) {[weak self] data,err in
                                            guard let _self = self else {return}
                                            sender.stopAnimation()
                                            if err != nil {
                                                if let msg = err as? String {
                                                    _self.notice(msg.capitalizingFirstLetter())
                                                } else {
                                                    _self.notice("service_unavailable".localized().capitalizingFirstLetter())
                                                }
                                            } else {
                                                _self.saveUser(data: data!)
                                            }
                    }
                }
            } else if type == .forgot {
                validateFotgot { email in
                    sender.startAnimation(activityIndicatorStyle: .white)
                    Server.shared.forgotPassword(email: email, {[weak self] (data, err) in
                        guard let _self = self else {return}
                        sender.stopAnimation()
                        var msg = ""
                        if let err = err {
                            switch err {
                            case .missingField:
                                msg = "missing_email_fotgot_password".localized().capitalizingFirstLetter()
                            case .unkownData:
                                msg = "user_not_exist".localized().capitalizingFirstLetter()
                            case .invalidService:
                                msg = "service_unavailable".localized()
                            default:
                                msg = "Unkown error!"
                            }
                            _self.notice(msg)
                        } else {
                            _self.view.endEditing(true)
                            Support.notice(title: "success".localized().capitalizingFirstLetter(), message: "forgot_password_success".localized().replacingOccurrences(of: "[_email_]", with: email).capitalizingFirstLetter(), vc: _self) { _ in
                                _self.onForgotSuccess?(email)
                                _self.navigationController?.popViewController(animated: true)
                            }
                            
                        }
                    })
                }
            }
        }
    }
    
    // MARK: - private
    private func validateRegister(_ completion:((String,String,String,String)->Void)?) {
        if !isConfirmPolicies {
            notice("not_confirm_policies_yet".localized())
            return
        }
        
        if let text = txtName.text {
            if text.removeScript().trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count == 0 {
                txtName.superview!.layer.borderWidth = 1
                notice("your_name_invalid".localized())
                return
            }
            txtName.superview!.layer.borderWidth = 0
        } else {
            txtName.superview!.layer.borderWidth = 1
            notice("your_name_invalid".localized())
            return
        }
        
        if let text = txtEmail.text {
            if text.removeScript().trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count == 0 || !Support.validate.isValidEmailAddress(emailAddressString: text){
                notice("email_invalid".localized())
                txtEmail.superview!.layer.borderWidth = 1
                return
            }
            txtEmail.superview!.layer.borderWidth = 0
        } else {
            notice("email_invalid".localized())
            txtEmail.superview!.layer.borderWidth = 1
            return
        }
        
        if let text = txtPassword.text {
            if text.removeScript().trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count == 0 || !Support.validate.isValidPassword(password: text){
                notice("password_invalid".localized())
                txtPassword.superview!.layer.borderWidth = 1
                return
            }
            txtPassword.superview!.layer.borderWidth = 0
        } else {
            notice("password_invalid".localized())
            txtPassword.superview!.layer.borderWidth = 1
            return
        }
        
        if let text = txtConfirmPassword.text {
            if text.removeScript().trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count == 0 || !Support.validate.isValidPassword(password: text){
                notice("password_not_same".localized())
                txtConfirmPassword.superview!.layer.borderWidth = 1
                return
            }
            txtConfirmPassword.superview!.layer.borderWidth = 0
        } else {
            notice("password_not_same".localized())
            txtConfirmPassword.superview!.layer.borderWidth = 1
            return
        }
        
        if let pw1 = txtPassword.text, let pw2 = txtConfirmPassword.text {
            if pw1.removeScript() != pw2.removeScript() {
                notice("password_not_same".localized())
                txtConfirmPassword.superview!.layer.borderWidth = 1
                return
            }
            txtConfirmPassword.superview!.layer.borderWidth = 0
        } else {
            notice("password_not_same".localized())
            txtConfirmPassword.superview!.layer.borderWidth = 1
            return
        }
        
        completion?(txtEmail.text!.removeScript(),
                    txtPassword.text!.removeScript(),
                    txtConfirmPassword.text!.removeScript(),
                    txtName.text!.removeScript())
    }
    
    private func validateFotgot(_ completion:((String)->Void)?) {
        if let text = txtEmailForgot.text {
            if !text.removeScript().isValidEmail(){
                notice("email_invalid".localized())
                txtEmailForgot.superview!.layer.borderWidth = 1
                return
            }
            txtEmailForgot.superview!.layer.borderWidth = 0
        } else {
            notice("email_invalid".localized())
            txtEmailForgot.superview!.layer.borderWidth = 1
            return
        }
        
        completion?(txtEmailForgot.text!.removeScript())
    }
    
    private func saveUser(data:JSON) {
        AccountManager.saveUserWith(dictionary: data, CoreDataStack.sharedInstance.persistentContainer.viewContext) { isSuccess in
            print("SAVE USER \(isSuccess)")
            self.onRegisterSuccess?()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App::UserRegisterSuccess"), object: nil, userInfo: ["action":"register"])
            }
        }
    }
    
    private func notice(_ message:String) {
        let ac = UIAlertController(title: "notice".localized().capitalizingFirstLetter(), message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "ok".localized().uppercased(), style: .cancel, handler: nil))
        present(ac, animated: true)
    }
    
    private func refreshView() {
        icoCheck.image = isConfirmPolicies ? #imageLiteral(resourceName: "ic_square_checked").tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)) : #imageLiteral(resourceName: "ic_square_uncheck").tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        if type == .register {
            btnRequest.isEnabled = isConfirmPolicies
            btnRequest.alpha = isConfirmPolicies ? 1 : 0.5
        } else {
            btnRequest.isEnabled = true
            btnRequest.alpha = 1
        }
    }
    
    private func configView() {
        btnRequest.layer.cornerRadius = 6
        btnRequest.layer.borderWidth = 1
        btnRequest.layer.borderColor = UIColor.white.cgColor
        btnRequest.setTitleColor(UIColor(hex:"0xFEDA00"), for: UIControlState())
        
        txtEmail.textColor = UIColor.white
        txtEmail.tintColor = UIColor.white
        
        txtEmailForgot.textColor = UIColor.white
        txtEmailForgot.tintColor = UIColor.white
        
        txtPassword.textColor = UIColor.white
        txtPassword.tintColor = UIColor.white
        
        txtConfirmPassword.textColor = UIColor.white
        txtConfirmPassword.tintColor = UIColor.white
        
        txtEmail.delegate = self
        txtPassword.delegate = self
        txtEmailForgot.delegate = self
        txtName.delegate = self
        txtConfirmPassword.delegate = self
        lblTermOfUse.delegate = self
        
        lblNoteForgot.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        lblTermOfUse.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lblTermOfUse.textContainer.lineFragmentPadding = 0;
        lblTermOfUse.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
        lblTermOfUse.font = UIFont.systemFont(ofSize: fontSize16)
        
        configActionButton(btn: btnBack)
        configActionButton(btn: btnRequest)
        
        configTextField(txt: txtName)
        configTextField(txt: txtEmail)
        configTextField(txt: txtEmailForgot)
        configTextField(txt: txtPassword)
        configTextField(txt: txtConfirmPassword)
    }
    
    private func configActionButton(btn:UIButton) {
        btn.addTarget(self, action: #selector(touchButton(_:)), for: .touchUpInside)
    }
    
    private func configTextField(txt:UITextField) {
        txt.superview!.layer.borderColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
    }
    
    private func configText() {
        btnRequest.setTitle(type == .register ? "sign_up".localized().capitalizingFirstLetter() : "reset_password".localized().capitalizingFirstLetter(), for: UIControlState())
        
        txtEmail.attributedPlaceholder = NSAttributedString(string: "email".localized().capitalizingFirstLetter(), attributes: [NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)])
        txtPassword.attributedPlaceholder = NSAttributedString(string: "password".localized().capitalizingFirstLetter(), attributes: [NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)])
        txtEmailForgot.attributedPlaceholder = NSAttributedString(string: "email".localized().capitalizingFirstLetter(), attributes: [NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)])
        txtConfirmPassword.attributedPlaceholder = NSAttributedString(string: "confirm_password".localized().capitalizingFirstLetter(), attributes: [NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)])
        txtName.attributedPlaceholder = NSAttributedString(string: "your_name".localized().capitalizingFirstLetter(), attributes: [NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)])
        
        btnBack.setAttributedTitle(NSAttributedString(string: "sign_in".localized().capitalizingFirstLetter(), attributes: [NSForegroundColorAttributeName:UIColor.white]), for: .normal)
        btnBack.setAttributedTitle(NSAttributedString(string: "sign_in".localized().capitalizingFirstLetter(), attributes: [NSForegroundColorAttributeName:#colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)]), for: .highlighted)
        
        lblNoteForgot.text = "note_reset_password".localized().capitalizingFirstLetter()
        
        if type == .register {
            "note_term_of_use".localized().capitalizingFirstLetter().stringByAddHtml { [weak self] attri in
                guard let _self = self, let attr = attri else {return}
                let para = NSMutableParagraphStyle()
                para.lineSpacing = 0.3 * _self.lblTermOfUse.font!.lineHeight
                let temp = NSMutableAttributedString(attributedString: attr)
                temp.addAttributes([NSParagraphStyleAttributeName : para], range: NSMakeRange(0, attr.length))
                _self.lblTermOfUse.attributedText = temp
            }
        }
        
        if type == .forgot {
            if let email = emailForgot {
                txtEmailForgot.text = email
            }
        }
        
    }
    
    // MARK: - support
    func hideKeyboard(_ sender: UITapGestureRecognizer) {
        self.hideKeyboard()
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        //Need to calculate keyboard exact size due to Apple suggestions
        //        self.scrollVIew.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)
        
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
    }
    
    deinit {
        print("SupportAuthenticController deinit")
    }
}

// MARK: - TEXTFIELD delegate
extension SupportAuthenticController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField.isEqual(txtName) {
            txtName.superview!.layer.borderWidth = 0
        } else if textField.isEqual(txtEmail) {
            txtEmail.superview!.layer.borderWidth = 0
        } else if textField.isEqual(txtEmailForgot) {
            txtEmailForgot.superview!.layer.borderWidth = 0
        } else if textField.isEqual(txtPassword) {
            txtPassword.superview!.layer.borderWidth = 0
        } else if textField.isEqual(txtConfirmPassword) {
            txtConfirmPassword.superview!.layer.borderWidth = 0
        }
        return true
    }
}

// MARK: - TEXTVIEW delegate
extension SupportAuthenticController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print(URL)
        return false
    }
}
