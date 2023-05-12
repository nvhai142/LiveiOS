//
//  InputCodeController.swift
//  SanTube
//
//  Created by Dai Pham on 3/9/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class InputCodeController: BasePresentController {

    // MARK: - api
    
    // MARK: - action
    func touchButton(_ sender:UIButton) {
        
        if sender.isEqual(btnPublic) || sender.isEqual(btnPrivate) {
            if sender.isSelected {return}
            // change state button
            btnPrivate.isSelected = false
            btnPublic.isSelected = false
            
            sender.isSelected = true
            
            lblTitle.text = sender.isEqual(btnPublic) ? "title_input_stream_code".localized().capitalizingFirstLetter() : "title_input_stream_password".localized().capitalizingFirstLetter()
            
            // reload number input square
            createInput()
        } else if sender.isEqual(btnOK) {
            findStream()
        }
    }
    
    func close(_ sender:UIButton) {
       closeView()
    }
    
    func closeFromTap(_ sender:UITapGestureRecognizer) {
        closeView()
    }
    
    // MARK: - private
    fileprivate func findStream() {
        var code = ""
        for item in listTextField {
            if let text = item.text {
                code.append(text)
            }
        }
        
        if code.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count != listTextField.count {
            Support.notice(title: "notice".localized().capitalizingFirstLetter(),
                           message: "code_invalid".localized().capitalizingFirstLetter(),
                           vc: self,
                           ["ok".localized().uppercased()],
                           {[weak self] action in
                            guard let _self = self else {return}
                            var isShouldLast = true
                            for txt in _self.listTextField {
                                if txt.text?.characters.count == 0 {
                                    txt.becomeFirstResponder()
                                    isShouldLast = false
                                    break
                                }
                            }
                            if isShouldLast {
                                _self.listTextField.last?.becomeFirstResponder()
                            }
            })
        } else {
            disableTextField()
            btnOK.startLoading(activityIndicatorStyle: .white)
            Server.shared.findStream(code: code,
                                     type: btnPublic.isSelected ? "public" : "private", {[weak self] (stream, errMsg) in
                                        guard let _self = self else {return}
                                        if let msg = errMsg {
                                            _self.enableTextField()
                                            _self.btnOK.stopLoading()
                                            Support.notice(title: "notice".localized().capitalizingFirstLetter(),
                                                           message: msg,
                                                           vc: _self,
                                                           ["ok".localized().uppercased()],
                                                           {[weak self] action in
                                                            guard let _self = self else {return}
                                                            _self.listTextField.last?.becomeFirstResponder()
                                            })
                                            return
                                        } else {
                                            if let stream = stream {
                                                _self.enableTextField()
                                                _self.btnOK.stopLoading()
                                                _self.onGotoStream?(stream)
                                                _self.closeView()
                                                return
                                            } else {
                                                _self.enableTextField()
                                                _self.btnOK.stopLoading()
                                                Support.notice(title: "notice".localized().capitalizingFirstLetter(),
                                                               message: "Unkown error",
                                                               vc: _self,
                                                               ["ok".localized().uppercased()],
                                                               {[weak self] action in
                                                                guard let _self = self else {return}
                                                                _self.listTextField.last?.becomeFirstResponder()
                                                })
                                            }
                                        }
            })
        }
    }
    
    private func disableTextField() {
        _ = listTextField.map{$0.isEnabled = false}
//        vwLoading.isHidden = false
    }
    
    private func enableTextField() {
        _ = listTextField.map{$0.isEnabled = true}
//        vwLoading.isHidden = true
    }
    
    private func createInput() {
        var number = 5
        if btnPrivate.isSelected {
            number = 6
        }
        _ = stackInputs.arrangedSubviews.reversed().map{$0.removeFromSuperview()}
        listTextField.removeAll()
        
        for i in 0..<number {
            let txt = UITextFieldDisabledCopyPaste(frame: self.view.bounds)
            let v = UIViewCustomBorder(frame: self.view.bounds, [.bottom])
            v.alpha = 0
            v.addSubview(txt)
            v.translatesAutoresizingMaskIntoConstraints = false
            txt.translatesAutoresizingMaskIntoConstraints = false
            txt.widthAnchor.constraint(equalToConstant: 30).isActive = true
            txt.heightAnchor.constraint(equalToConstant: 30).isActive = true
            txt.leadingAnchor.constraint(equalTo: v.leadingAnchor).isActive = true
            v.trailingAnchor.constraint(equalTo: txt.trailingAnchor).isActive = true
            v.bottomAnchor.constraint(equalTo: txt.bottomAnchor).isActive = true
            txt.topAnchor.constraint(equalTo: v.topAnchor).isActive = true
            
            self.stackInputs.addArrangedSubview(v)
            
            txt.font = UIFont.boldSystemFont(ofSize: fontSize22)
            txt.tag = i
            txt.textAlignment = .center
            txt.delegate = self
            txt.myDelegate = self
            if i == 0 {
                txt.becomeFirstResponder()
            }
            self.listTextField.append(txt)
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: .allowUserInteraction, animations: {
            self.view.layoutIfNeeded()
        }, completion: {isDone in
            _ = self.stackInputs.arrangedSubviews.map({$0.alpha = 1})
        })
    }
    
    private func closeView() {
        view.endEditing(true)
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        },completion:{isDone in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    private func config() {
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeFromTap(_:)))
        vwClose.addGestureRecognizer(tapGesture)
        
        vwContainer.layer.masksToBounds = true
        vwContainer.layer.shadowColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1).cgColor
        vwContainer.layer.shadowOffset = CGSize(width:0.5, height:4.0)
        vwContainer.layer.shadowOpacity = 0.5
        vwContainer.layer.shadowRadius = 5.0
        vwContainer.layer.cornerRadius = 5
        
        lblTitle.font = UIFont.boldSystemFont(ofSize: fontSize17)
        lblTitle.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        lblTitle.text = "title_input_stream_code".localized().capitalizingFirstLetter()
        
        btnClose.setImage(#imageLiteral(resourceName: "ic_close_black_76").resizeImageWith(newSize: CGSize(width: 10, height: 10)), for: UIControlState())
        
        btnOK.setTitle("ok".localized().uppercased(), for: UIControlState())
        btnOK.layer.masksToBounds = true
        btnOK.layer.cornerRadius = 3
        btnOK.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        btnOK.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: UIControlState())
        btnOK.addTarget(self, action: #selector(touchButton(_:)), for: .touchUpInside)
        
        btnPublic.setTitle("public".localized().capitalizingFirstLetter(), for: UIControlState())
        btnPrivate.setTitle("private".localized().capitalizingFirstLetter(), for: UIControlState())
        configButton(btn: btnPublic)
        configButton(btn: btnPrivate)

        btnClose.addTarget(self, action: #selector(close(_:)), for: .touchUpInside)
    }
    
    private func configButton(btn:UIButton) {
        
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize16)
        
        btn.setImage(#imageLiteral(resourceName: "ic_circle").resizeImageWith(newSize: CGSize(width: 20, height: 20)).tint(with: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)), for: .normal)
        btn.setImage(#imageLiteral(resourceName: "ic_check_128").resizeImageWith(newSize: CGSize(width: 20, height: 20)), for: .selected)
        
        btn.setTitleColor(#colorLiteral(red: 0.6470588235, green: 0.6470588235, blue: 0.6470588235, alpha: 1), for: .normal)
        btn.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .selected)
        
        btn.backgroundColor = UIColor.clear
        
        btn.addTarget(self, action: #selector(touchButton(_:)), for: .touchUpInside)
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        view.alpha = 0
        config()
        btnPublic.isSelected = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 1
            self.view.transform = .identity
            self.createInput()
        },completion:{isDone in
            
        })
    }
    
    deinit {
        print("InputCodeCOntroller dealloc")
        vwClose.removeGestureRecognizer(tapGesture)
    }
    
    // MARK: - closures
    var onGotoStream:((Stream)->Void)?
    
    // MARK: - properties
    var listTextField:[UITextField] = []
    var tapGesture:UITapGestureRecognizer!
    
    // MARK: - outlet
    @IBOutlet weak var vwContainer: UIView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnPublic: UIButton!
    @IBOutlet weak var btnPrivate: UIButton!
    @IBOutlet weak var stackInputs: UIStackView!
    @IBOutlet weak var vwClose: UIView!
    @IBOutlet weak var vwLoading: UIView!
    @IBOutlet weak var btnOK: UIButton!
}

extension InputCodeController:UITextFieldDelegate, UITextFieldDisabledCopyPasteDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).characters.count == 0 && range.length == 1 && range.location == 0 {return true} // user delete
        
        if string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).characters.count == 0 {
            return false
        }
        
        var shouldAllow = true
        var timerInterval = 0.1
        if let text = textField.text {
            if text.characters.count == 1 {
                shouldAllow = false
                timerInterval = 0
            }
        }
        
        let next = textField.tag + 1
        if next > listTextField.count - 1 {
            
            // request api get stream with code
            Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: false, block: {[weak self] timer in
                guard let _self = self else {return}
//                _self.view.endEditing(true)
                print("SHOULD REQUEST API GET STREAM FROM CODE")
//                _self.findStream()
            })
        } else {
            Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: false, block: {[weak self] timer in
                guard let _self = self else {return}
                print("SHOULD NEXT TEXTFIELD")
                _self.listTextField[next].becomeFirstResponder()
            })
        }

        return shouldAllow
    }
    
    func textFieldDidDelete(textField:UITextField) {
        let previous = textField.tag - 1
        if previous < 0 {return}
        self.listTextField[previous].becomeFirstResponder()
    }
}

// MARK: - UITextfield disable copy/paste
protocol UITextFieldDisabledCopyPasteDelegate {
    func textFieldDidDelete(textField:UITextField)
}
class UITextFieldDisabledCopyPaste: UITextField {
    
    var myDelegate: UITextFieldDisabledCopyPasteDelegate?
    
    override func deleteBackward() {
        super.deleteBackward()
        myDelegate?.textFieldDidDelete(textField: self)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // disable copy/paste on uitextfield
        UIMenuController.shared.isMenuVisible = false
        return false
    }
}
