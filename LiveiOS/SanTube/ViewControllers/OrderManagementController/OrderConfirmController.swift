//
//  OrderConfirmController.swift
//  SanTube
//
//  Created by Dai Pham on 1/8/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

fileprivate let TAG_BUTTON_PROCESS = 9089
fileprivate let TAG_BUTTON_REJECT = 9090
fileprivate let TAG_BUTTON_FINISH = 9091
fileprivate let TAG_BUTTON_CONFIRM = 9092

enum OrderType {
    case confirm
    case edit
    case view
}

class OrderConfirmController: BaseController {

    // MARK: - event
    func actionButton(_ sender:UIButton) {
        
        sender.startAnimation(activityIndicatorStyle: .white)
        
        if sender.tag == TAG_BUTTON_CONFIRM {
            
            sender.startAnimation(activityIndicatorStyle: .gray)
            
            guard let user = Account.current, let order = order else {return}
            
            var totalPrice:CGFloat = 0
            _ = order.products.filter{$0.orderQuantity > 0}.map({totalPrice += CGFloat($0.price) * CGFloat($0.orderQuantity)})
            
            var userS = userShipping
            if userS == nil {
                userS = order.userShipping
            }
            
            if userS == nil {
                _ = validate()
            }
            if !validate() {
                return
            }
            
            Server.shared.createOrder(id: order.id,
                                      streamId: order.streamId,
                                      buyerId: user.id,
                                      sellerId: order.sellerId,
                                      totalPrice: totalPrice,
                                      products: order.products.filter{$0.orderQuantity > 0}.flatMap{$0.toOrderItemConfirm()},
                                      userShipping: userS!.toDict(), {[weak self] (data, err) in
                                        guard let _self = self else {return}
                                        sender.stopAnimation()
                if err == nil {
                    NotificationCenter.default.post(name: NSNotification.Name("App::emitOrderSuccess"), object: nil)
                    UIView.animate(withDuration: 0.3, animations: {
                        _self.navigationController!.view.alpha = 0
                        _self.navigationController!.view.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    },completion:{isDone in
                        let vc = OrderMessageController(nibName: "OrderMessageController", bundle: Bundle.main)
                        vc.message = "order_request_success".localized()
                        _self.navigationController?.pushViewController(vc, animated: false)
                        _self.navigationController!.view.frame = CGRect(origin:CGPoint.zero, size: UIScreen.main.bounds.size)
                        _self.navigationController!.view.alpha = 1
                        _self.navigationController!.view.transform = .identity
                    })
                } else {
                    let actionSheetController: UIAlertController = UIAlertController(title: "error".localized().uppercased(), message: "order_request_failed".localized().capitalizingFirstLetter(), preferredStyle: .alert)
                    let cancelAction: UIAlertAction = UIAlertAction(title: "ok".localized(), style: .cancel) { action -> Void in
                        //Just dismiss the action sheet
                    }
                    actionSheetController.addAction(cancelAction)
                    _self.present(actionSheetController, animated: true, completion: nil)
                }
            })
        } else if   sender.tag == TAG_BUTTON_FINISH ||
                    sender.tag == TAG_BUTTON_REJECT ||
                    sender.tag == TAG_BUTTON_PROCESS {
            
            guard let order = self.order else {return}
            var status:String?
            if sender.tag == TAG_BUTTON_FINISH {
                status = AppConfig.status.order.finish()
            } else if sender.tag == TAG_BUTTON_REJECT {
                status = AppConfig.status.order.rejected()
            } else if sender.tag == TAG_BUTTON_PROCESS {
                status = AppConfig.status.order.progress()
            }
            
            guard let sta = status else {return}
            
            Server.shared.changeStatusOrder(orderIds: [order.id],
                                            status: sta, {[weak self] (order, err) in
                                                guard let _self = self else {return}
                                                sender.stopAnimation()
                                                if err != nil {
                                                    let actionSheetController: UIAlertController = UIAlertController(title: "error".localized().uppercased(), message: "order_request_failed".localized(), preferredStyle: .alert)
                                                    let cancelAction: UIAlertAction = UIAlertAction(title: "ok".localized().uppercased(), style: .cancel) { action -> Void in
                                                        //Just dismiss the action sheet
                                                    }
                                                    actionSheetController.addAction(cancelAction)
                                                    _self.present(actionSheetController, animated: true, completion: nil)
                                                } else {
                                                    
                                                    // set new state for view
                                                    if let ord = order {
                                                        _self.order = ord
                                                        _self.configView()
                                                        _self.onUpdateStateOrder?(ord)
                                                    }
                                                    
                                                    let actionSheetController: UIAlertController = UIAlertController(title: "success".localized().capitalizingFirstLetter(), message: "order_change_status_success".localized(), preferredStyle: .alert)
                                                    let cancelAction: UIAlertAction = UIAlertAction(title: "continue".localized().capitalizingFirstLetter(), style: .cancel) { action -> Void in
                                                        //Just dismiss the action sheet
                                                    }
                                                    let backAction: UIAlertAction = UIAlertAction(title: "close".localized().capitalizingFirstLetter(), style: .default) {[weak _self] action -> Void in
                                                        //Just dismiss the action sheet
                                                        guard let __self = _self else {return}
                                                        __self.onShouldClose?()
                                                    }
                                                    actionSheetController.addAction(cancelAction)
                                                    actionSheetController.addAction(backAction)
                                                    _self.present(actionSheetController, animated: true, completion: nil)
                                                }
            })
            
            
        }
    }
    
    // MARK: - private
    fileprivate func validate() -> Bool{
        
        textViewName.showPlaceHolder(placeholder: textViewName.text.characters.count != 0 ? nil : "enter_your_name".localized().capitalizingFirstLetter())
        textViewAddress.showPlaceHolder(placeholder: textViewAddress.text.characters.count != 0 ? nil : "enter_your_address".localized().capitalizingFirstLetter())
        textViewPhone.showPlaceHolder(placeholder: textViewPhone.text.characters.count != 0 ? nil : "enter_your_phone".localized().capitalizingFirstLetter())
        
        if let userS = userShipping {
            _ = stackControl.arrangedSubviews.map{if let btn = $0 as? UIButton {if btn.tag == TAG_BUTTON_CONFIRM {btn.isEnabled = userS.isValid()}}}
            
            // check user shipping is modify data, then is create new usershipping
            if let _ = tempUserShipping {
                if tempUserShipping!.shippingName.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) != userS.shippingName.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) ||
                    tempUserShipping!.shippingPhone.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) != userS.shippingPhone.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) ||
                    tempUserShipping!.shippingAddress.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) != userS.shippingAddress.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines){
                    
                    userShipping?.id = ""
                    order?.userShipping = userShipping
                }
            }
            
            return userS.isValid()
        } else {
            order?.userShipping = userShipping
        }
        
        _ = stackControl.arrangedSubviews.map{if let btn = $0 as? UIButton {if btn.tag == TAG_BUTTON_CONFIRM {btn.isEnabled = false}}}
            
        return false
    }
    
    private func loadLastShipping() {
        guard let user = Account.current else { return }
        Server.shared.getShippings(from: user.id) {[weak self] (shippings, err) in
            guard let _self = self, let shippings = shippings else {return}
            if shippings.count == 0 {return}
            _self.loadUserShipping(shipping: shippings.first!)
        }
    }
    
    private func loadOrderItems() {
        guard let order = order else { return }
        for i in order.products.filter({$0.orderQuantity > 0}) {
            let v = OrderItemView(frame:CGRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 100)))
            stackProducts.addArrangedSubview(v)
            var ctype:OrderItemViewType = .view
            if type == .confirm {
                ctype = .shop
            } else if type == .edit {
                ctype = .edit
            } else if type == .view {
                ctype = .viewHistory
            }
            
            v.loadProduct(product: i, ctype)
            v.onUpdateOrderQuantity = {[weak self] product in
                guard let _self = self, let product = product, let order = _self.order else {return}
                var proTemps:[Product] = []
                for item in order.products {
                    if item.id == product.id {
                        var pro = item
                        pro.orderQuantity = product.orderQuantity
                        proTemps.append(pro)
                    } else {
                        proTemps.append(item)
                    }
                }
                print(proTemps.flatMap{$0.orderQuantity})
                _self.order!.products = proTemps
            }
            v.translatesAutoresizingMaskIntoConstraints = false
            let realspace:CGFloat = 20
            let width = (UIScreen.main.bounds.size.width - realspace)/3 - 5/3
            v.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }
    
    private func configView() {
        
        title = "confirm".localized().capitalized
        
        addButton()
        
        scrollViewProduct.layer.masksToBounds = true
        scrollViewProduct.layer.cornerRadius = 5
        
        lblNote.textColor = #colorLiteral(red: 0.368627451, green: 0.368627451, blue: 0.368627451, alpha: 1)
        lblNote.font = UIFont.systemFont(ofSize: fontSize15)
        
        textViewName.delegate = self
        textViewAddress.delegate = self
        textViewPhone.delegate = self
        
        textViewName.textColor = #colorLiteral(red: 0.368627451, green: 0.368627451, blue: 0.368627451, alpha: 1)
        textViewAddress.textColor = #colorLiteral(red: 0.368627451, green: 0.368627451, blue: 0.368627451, alpha: 1)
        textViewPhone.textColor = #colorLiteral(red: 0.368627451, green: 0.368627451, blue: 0.368627451, alpha: 1)
        
        textViewName.font = UIFont.systemFont(ofSize: fontSize15)
        textViewPhone.font = UIFont.systemFont(ofSize: fontSize15)
        textViewAddress.font = UIFont.systemFont(ofSize: fontSize15)
        
        if type == .confirm {
            lblTitleProduct.text = "order_items".localized()
            switchToEditInformation(true)
        } else {
            
            vwNoteConfirm.isHidden = true
            
            if let order = order {
                lblTitleProduct.text = order.products.count == 1 ? "want_to_buy_1_product".localized() :  "want_to_buy_products".localized().replacingOccurrences(of: "_[]_", with: "\(order.products.count)")
            }
        }
        
        if type == .view {
            vwButton.isHidden = true
        }
        
        guard let user = Account.current else { return }
        guard let _ = userShipping else {
            self.userShipping = UserShipping()
            self.userShipping!.userId = user.id
            self.userShipping!.shippingName = user.name
            self.userShipping!.shippingPhone = user.phone
            reloadTextView()
            return
        }
        
        reloadTextView()
    }
    
    private func loadUserShipping(shipping:UserShipping) {
        guard let userS = userShipping else {userShipping = shipping; reloadTextView(); return}
        if userS.id.characters.count > 0 {
            return
        }
        userShipping = shipping
        tempUserShipping = shipping
        order?.userShipping = userShipping
       reloadTextView()
    }
    
    private func reloadTextView() {
        textViewName.text = userShipping?.shippingName ?? ""
        textViewPhone.text = userShipping?.shippingPhone ?? ""
        textViewAddress.text = userShipping?.shippingAddress ?? ""
        _ = validate()
    }
    
    private func addButton() {
        _ = stackControl.arrangedSubviews.map{$0.removeFromSuperview()}
        var listButtons = [["tag":TAG_BUTTON_CONFIRM,"text":"confirm_and_send_request".localized()]]
        if self.type == .edit {
            listButtons = [
                ["tag":TAG_BUTTON_REJECT,"text":"reject".localized().capitalized],["tag":TAG_BUTTON_PROCESS,"text":"process".localized().capitalized],
            ["tag":TAG_BUTTON_FINISH,"text":"finish".localized().capitalized]]
            
            if order != nil {
                if order!.status != AppConfig.status.order.create_new() {
                    for (i,item) in listButtons.reversed().enumerated() {
                        
                        let index = listButtons.count - i - 1
                        let tag = item["tag"] as! Int
                        
                        if order!.status == AppConfig.status.order.progress() {
                            if tag == TAG_BUTTON_PROCESS {
                                listButtons.remove(at: index)
                                break
                            }
                        } else if order!.status == AppConfig.status.order.finish() {
                            if tag == TAG_BUTTON_FINISH {
                                listButtons.remove(at: index)
                                break
                            }
                        } else if order!.status == AppConfig.status.order.rejected() {
                            if tag == TAG_BUTTON_REJECT {
                                listButtons.remove(at: index)
                                break
                            }
                        }
                    }
                }
            }
        }
        
        for item in listButtons {
            let button = UIButton(type: .custom)
            button.setTitle((item["text"] as! String), for: .normal)
            button.tag = item["tag"] as! Int
            setEvent(button: button)
            stackControl.addArrangedSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            let height = button.heightAnchor.constraint(equalToConstant: 40)
            height.priority = 750
            button.addConstraint(height)
        }
        
        lblNote.text = "note_confirm_order".localized()
        
        lblTitleProduct.font = UIFont.boldSystemFont(ofSize: fontSize17)
        lblTitleProduct.textColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
        
        
    }
    
    func switchToEditInformation(_ isEdit:Bool) {
        
        textViewName.isEditable = isEdit
        textViewPhone.isEditable = isEdit
        textViewAddress.isEditable = isEdit
        
        // validate data
        _ = validate()
    }
    
    private func setEvent(button:UIButton) {
        button.addTarget(self, action: #selector(actionButton), for: .touchUpInside)
        button.layer.cornerRadius = 5
        button.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10)
        button.layer.masksToBounds = true

        if button.tag == TAG_BUTTON_CONFIRM {
            button.layer.borderWidth = 1.5
            button.layer.borderColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
            button.setTitleColor(#colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1), for: .normal)
            button.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .highlighted)
            button.setBackgroundImage(#imageLiteral(resourceName: "Pixel"), for: .normal)
            button.setBackgroundImage(#imageLiteral(resourceName: "Pixel").tint(with:#colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)), for: .highlighted)
            button.setTitle("user_shipping_invalid".localized(), for: .disabled)
        } else if button.tag == TAG_BUTTON_REJECT {
            button.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: UIControlState())
            button.setBackgroundImage(#imageLiteral(resourceName: "Pixel").tint(with:#colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)), for: UIControlState())
        } else if button.tag == TAG_BUTTON_PROCESS {
            button.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: UIControlState())
            button.setBackgroundImage(#imageLiteral(resourceName: "Pixel").tint(with:#colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)), for: UIControlState())
        } else if button.tag == TAG_BUTTON_FINISH {
            button.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: UIControlState())
            button.setBackgroundImage(#imageLiteral(resourceName: "Pixel").tint(with:#colorLiteral(red: 0.05098039216, green: 0.6039215686, blue: 0.007843137255, alpha: 1)), for: UIControlState())
        }
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configView()
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard(_:)))
        scrollView.addGestureRecognizer(tapGesture!)
        
        loadOrderItems()
        
        if type == .confirm {
            loadLastShipping()
        }
        _ = validate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // listern behavious keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // check if this view is root, set background color and button back
        guard let nv = navigationController else { return }
        if nv.viewControllers.count == 1 {
            navigationController?.navigationBar.barTintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            navigationController?.navigationBar.shadowImage = #imageLiteral(resourceName: "TransparentPixel")
            navigationController?.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "Pixel"), for: .default)
        }
        
        btnBack = UIButton(type: .custom)
        btnBack.frame = CGRect(x: 0, y: 0, width: 40*70/100, height: 40)
        btnBack.contentMode = .scaleAspectFill
        btnBack.clipsToBounds = true
        btnBack.semanticContentAttribute = .forceLeftToRight
        btnBack.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        btnBack.setImage(UIImage(named:"arrow_left_white_48")?.tint(with: #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)), for: UIControlState())
        btnBack.addTarget(self, action: #selector(self.menuPress(sender:)), for: .touchUpInside)
        let itemBack = UIBarButtonItem(customView: btnBack)
        self.navigationItem.leftBarButtonItems = [itemBack]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        switchToEditInformation(false)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        if tapGesture != nil {
            scrollView.removeGestureRecognizer(tapGesture!)
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
    
    // MARK: - outlet
    @IBOutlet weak var lblTitleProduct: UILabel!
    @IBOutlet weak var stackProducts: UIStackView!
    @IBOutlet weak var icoUser: UIImageView!
    @IBOutlet weak var icoPhone: UIImageView!
    @IBOutlet weak var icoAddress: UIImageView!
    @IBOutlet weak var stackControl: UIStackView!
    @IBOutlet weak var lblNote: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var vwNoteConfirm: UIView!
    @IBOutlet weak var scrollViewProduct: UIScrollView!
    @IBOutlet weak var textViewAddress: UITextView!
    @IBOutlet weak var textViewPhone: UITextView!
    @IBOutlet weak var textViewName: UITextView!
    @IBOutlet weak var vwButton: UIView!
    
    // MARK: - properties
    var type:OrderType = .confirm
    var order:Order? {
        didSet {
            guard let order = order else { return }
            userShipping = order.userShipping
            tempUserShipping = order.userShipping
        }
    }
    
    var tapGesture:UITapGestureRecognizer?
    var userShipping:UserShipping?
    var tempUserShipping:UserShipping? // keep original to check user shipping is modify
    
    // MARK: - closures
    var onShouldClose:(()->Void)?
    var onUpdateStateOrder:((Order)->Void)?
}

extension OrderConfirmController:UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if userShipping == nil {userShipping = UserShipping(); userShipping?.userId = Account.current?.id}
        userShipping?.shippingName = textViewName.text ?? ""
        userShipping?.shippingPhone = textViewPhone.text ?? ""
        userShipping?.shippingAddress = textViewAddress.text ?? ""
        
        _ = validate()
    }
}
