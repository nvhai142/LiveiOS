//
//  AuthenticController.swift
//  BUUP
//
//  Created by Dai Pham on 11/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class AuthenticController: BaseController {

    // MARK: - outlet
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var btnSignInFB: UIButton!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var btnRegister: UIButton!
    @IBOutlet weak var btnForgetPassword: UIButton!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var vwTwoButton: UIView!
    @IBOutlet weak var btnSignInFBTWO: UIButton!
    @IBOutlet weak var btnSignInEmailTWO: UIButton!
    @IBOutlet weak var vwControlSignEmail: UIView!
    @IBOutlet weak var vwControlRegister: UIStackView!
    @IBOutlet weak var topConstraintButtonClose: NSLayoutConstraint!
    
    // MARK: - properties
    var tapGesture:UITapGestureRecognizer?
    var shouldGotoStreamAfterLogin:Bool = false
    
    // MARK: - closures
    var onLogInSuccessInApp:(()->Void)?
    var onQuitStreamToo:(()->Void)?
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        // listern behavious keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // config
        configText()
        configView()
        
        // add gesture to end edit
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard(_:)))
        scrollView.addGestureRecognizer(tapGesture!)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - event button
    @IBAction func touchButton(_ sender: UIButton) {
        if sender.isEqual(btnSignInFB) || sender.isEqual(btnSignInFBTWO){
            sender.startAnimation(activityIndicatorStyle: .white)
            // call api login fb
            if !sender.isEqual(btnSignInFB) {btnSignInEmailTWO.isHidden = true}
            Server.shared.loginFB {[weak self] result in
                guard let _self = self else {return}
                if !sender.isEqual(_self.btnSignInFB) {_self.btnSignInEmailTWO.isHidden = false}
                sender.stopAnimation()
                switch result {
                case .success(let data):
                    _self.saveUser(data:data,true) {
                        if !_self.shouldGotoStreamAfterLogin {
                            UserDefaults.standard.removeObject(forKey: "App::StreamID")
                            UserDefaults.standard.synchronize()
                            _self.touchButton(_self.btnClose)
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App::UserLoginSuccess"), object: nil, userInfo: ["action":"login"])
                            }
                        } else {
                            _self.onQuitStreamToo?()
                            _self.dismiss(animated: true, completion: nil)
                        }
                    }
                    
                case .failure(.some(_)):
                    print("login failed")
                case .failure(.none):
                    print("login failed")
                }
                
            }
        } else if sender.isEqual(btnClose) {
            self.onDissmiss?()
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func displayFormEmail(_ sender: Any) {
        vwTwoButton.removeFromSuperview()
        vwControlSignEmail.isHidden = false
        vwControlRegister.isHidden = false
        btnSignInFB.isHidden = false
    }
    
    @IBAction func processLoginEmailPassword(_ sender: UIButton) {
        let server = Server.self
        validate {[weak self] email, password in
            guard let _self = self else {return}
            sender.startAnimation(activityIndicatorStyle: .white)
            _self.btnRegister.isEnabled = false
            _self.btnForgetPassword.isEnabled = false
            _self.btnSignInFB.isEnabled = false
            _self.view.endEditing(true)
            server.shared.login(email:email, password:password) {[weak _self] result in
                guard let __self = _self else {return}
                __self.btnRegister.isEnabled = true
                __self.btnForgetPassword.isEnabled = true
                __self.btnSignInFB.isEnabled = true
                sender.stopAnimation()
                switch result {
                case .success(let data):
                    __self.saveUser(data:data,true) {
                        DispatchQueue.main.async {
                            if !__self.shouldGotoStreamAfterLogin {
                                UserDefaults.standard.removeObject(forKey: "App::StreamID")
                                UserDefaults.standard.synchronize()
                                __self.touchButton(__self.btnClose)
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "App::UserLoginSuccess"), object: nil, userInfo: ["action":"login"])
                            } else {
                                __self.onQuitStreamToo?()
                                __self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                case .failure(_):
                    Support.notice(title: "notice".localized().capitalizingFirstLetter(), message: "login_failed".localized().capitalizingFirstLetter(), vc: __self, ["ok".localized().uppercased()],nil)
                }
                
            }
        }
    }
    
    @IBAction func register(_ sender: Any) {
        let vc = SupportAuthenticController(nibName: "SupportAuthenticController", bundle: Bundle.main)
        vc.type = .register
        self.navigationController?.pushViewController(vc, animated: true)
        vc.onRegisterSuccess = {[weak self] in
            guard let _self = self else {return}
            _self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func forgetPassword(_ sender: Any) {
        let vc = SupportAuthenticController(nibName: "SupportAuthenticController", bundle: Bundle.main)
        vc.type = .forgot
        if let email = txtEmail.text {
            if email.isValidEmail() {
                vc.emailForgot = email.removeScript()
            }
        }
        vc.onForgotSuccess = {[weak self] email in
            guard let _self = self else {return}
            _self.txtEmail.text = email
            _self.txtPassword.becomeFirstResponder()
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    // MARK: - private
    private func validate(_ completion:((String,String)->Void)?) {
        if let text = txtEmail.text {
            if !text.removeScript().isValidEmail(){
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
            if !text.isValidPassword(){
                notice("password_invalid".localized())
                txtPassword.superview!.layer.borderWidth = 1
                return
            }
            txtEmail.superview!.layer.borderWidth = 0
        } else {
            notice("password_invalid".localized())
            txtEmail.superview!.layer.borderWidth = 1
            return
        }
        
        completion?(txtEmail.text!.removeScript(),
                    txtPassword.text!.removeScript())
    }
    
    private func configTextField(txt:UITextField) {
        txt.superview!.layer.borderColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
    }
    
    private func notice(_ message:String) {
        let ac = UIAlertController(title: "notice".localized().capitalizingFirstLetter(), message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "ok".localized().uppercased(), style: .cancel, handler: nil))
        present(ac, animated: true)
    }
    
    func saveUser(data:JSON,_ isGotoLaunch:Bool = true,_ done:(()->Void)? = nil) {
        let navigation = AppConfig.navigation.self
        AccountManager.saveUserWith(dictionary: data, CoreDataStack.sharedInstance.persistentContainer.viewContext) { isSuccess in
            print("SAVE USER \(isSuccess)")
            if isGotoLaunch {
                let vc = LaunchController(nibName: "LaunchController", bundle: Bundle.main)
                navigation.changeRootControllerTo(viewcontroller: vc)
            } else {
                done?()
            }
        }
    }
    
    func configView() {
        
        // show button close when login in app
        if let user = Account.current {
            if user.is_guest {
                btnClose.isHidden = false
            }
        }
        
        if #available(iOS 11.0, *) {
            
        } else {
            topConstraintButtonClose.constant = 20
        }
        
        btnLogin.layer.cornerRadius = 6
        btnLogin.layer.borderWidth = 1
        btnLogin.layer.borderColor = UIColor.white.cgColor
        btnLogin.setTitleColor(UIColor(hex:"0xFEDA00"), for: UIControlState())
        
        txtEmail.textColor = UIColor.white
        txtEmail.tintColor = UIColor.white
        
        txtPassword.textColor = UIColor.white
        txtPassword.tintColor = UIColor.white
        
        txtEmail.delegate = self
        txtPassword.delegate = self
        
        btnRegister.setTitleColor(UIColor.white, for: UIControlState())
        btnForgetPassword.setTitleColor(UIColor.white, for: UIControlState())
        btnSignInFB.setTitleColor(UIColor(hex:"0x3b5998"), for: UIControlState())
        
        btnSignInFBTWO.setTitleColor(UIColor.white, for: UIControlState())
        btnSignInFBTWO.layer.backgroundColor = UIColor(hex:"0x3b5998").cgColor
        
        btnSignInEmailTWO.setTitleColor(UIColor.white, for: UIControlState())
        btnSignInEmailTWO.layer.backgroundColor = UIColor.red.cgColor
        
        btnSignInEmailTWO.layer.cornerRadius = 6
        btnSignInFBTWO.layer.cornerRadius = 6
        
        configTextField(txt: txtEmail)
        configTextField(txt: txtPassword)
        
        btnClose.addTarget(self, action: #selector(touchButton(_:)), for: .touchUpInside)
    }
    
    func configText() {
        btnSignInFB.setTitle("login_with_fb".localized(), for: UIControlState())
        btnRegister.setTitle("new_account".localized(), for: UIControlState())
        btnSignInFB.setTitle("login_with_facebook".localized(), for: UIControlState())
        btnLogin.setTitle("login".localized().uppercased(), for: UIControlState())
        btnForgetPassword.setTitle("forget_your_password".localized(), for: UIControlState())
        
        btnSignInFBTWO.setTitle("signin_with_facebook".localized(), for: UIControlState())
        btnSignInEmailTWO.setTitle("signin_with_email".localized(), for: UIControlState())
        
        txtEmail.attributedPlaceholder = NSAttributedString(string: "email".localized(), attributes: [NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)])
        txtPassword.attributedPlaceholder = NSAttributedString(string: "password".localized(), attributes: [NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)])
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
        print("AuthenticController deinit")
    }
}

// MARK: - TEXTFIELD delegate
extension AuthenticController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.superview!.layer.borderWidth = 0
        return true
    }
}
