//
//  LiveStreamController.swift
//  SanTube
//
//  Created by Hai NguyenV on 11/16/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import TLPhotoPicker
import Photos
import FacebookLogin
import FBSDKLoginKit
import SocketIO

class LiveStreamController:BaseController, LFLiveSessionDelegate,CreateStreamViewDelegate,TLPhotosPickerViewControllerDelegate,FilterViewDelegate, ListProductDelegate,ShopProductViewDelegate {
    
   
    
    var timerVideoLive:Timer!
    var listProduct:[Product] = []
    var streamID: String?
    var streamThumb: String?
    var streamObj: Stream!
    var category: Category!
    var selectedAssets = [TLPHAsset]()
    var room: Room!
    var cDate: Date?
    var isPublicShop: Bool = true
    var isShowingShowcase:Bool = false
    
    let socket = SocketIOClient(socketURL: URL(string: socket_server)!, config: [.log(true), .forceWebsockets(true)])
    
    @IBOutlet weak var vShopView: ShopProductView!
    @IBOutlet weak var btnOpenShop: UIButton!
    @IBOutlet weak var stackIcon: UIStackView!
    @IBOutlet weak var choiceCategoryView: UIView!
    @IBOutlet weak var createView: CreateStreamView!
    @IBOutlet weak var btnTime: UIButton!
    @IBOutlet weak var btnLike: UIButton!
    @IBOutlet weak var btnViews: UIButton!
    @IBOutlet weak var filterListView: FilterVideoList!
    @IBOutlet weak var btnBackHome: UIButton!
    @IBOutlet weak var filterConstrant: NSLayoutConstraint!
    var categoryController:SelectCategoryController!
    // MARK: - outlet
    @IBOutlet weak var categoryStackView: UIStackView!
    @IBOutlet weak var btnStreamCode: UIButton!
    //    var containerView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 60))
    
    // MARK: - properties
    var onDissmissing:(()->Void)?
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.showChoiceCategory()
        self.listernEvent()
        
        Server.shared.getCategories(UserManager.currentUser()?.id,loadCache:true) {[weak self] result in
            guard let _self = self else {return}
            switch result {
            case .success(let list):
                let listTemp = list.flatMap{Category.parse(from: $0)}
                _self.categoryController.load(categories:listTemp.sorted(by: { (item, item1) -> Bool in
                    return item.isMarked && !item1.isMarked
                }))
            case .failure(let msg):
                print(msg as Any)
            }
            
        }
        _ = [btnLike,btnTime,btnViews,btnStreamCode].map{setupCommonButton(button: $0)}
        
        session.delegate = self
        session.preView = self.view
        session.beautyFace = false
        session.filterLevel = 5
        
        self.requestAccessForVideo()
        self.requestAccessForAudio()
        self.view.backgroundColor = UIColor.clear
        containerView.backgroundColor = UIColor.clear
        self.view.addSubview(containerView)
        
        containerView.addSubview(bottomView)
        containerView.addSubview(beautyButton)
        containerView.addSubview(startLiveButton)
        containerView.addSubview(shareButton)
        containerView.addSubview(cameraButton)
        bottomView.isHidden = true
        startLiveButton.isHidden = true
        shareButton.isHidden = true
        beautyButton.isHidden = true
        cameraButton.isHidden = true
        stackIcon.isHidden = true
        btnOpenShop.isHidden = true
        vShopView.isHidden = true
        vShopView.delegate = self
        
        filterListView.isHidden = true
        filterConstrant.constant = 56
        filterListView.delegate = self
        
        beautyButton.isSelected = !session.beautyFace
        beautyButton.addTarget(self, action: #selector(didTappedBeautyButton(_:)), for: .touchUpInside)
        startLiveButton.addTarget(self, action: #selector(didTappedStartLiveButton(_:)), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(didTappedShareButton(_:)), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(didTappeCameraaButton(_:)), for: .touchUpInside)
        createView.delegate = self;
        
        self.view.bringSubview(toFront: createView)
        self.view.bringSubview(toFront: choiceCategoryView)
        self.view.bringSubview(toFront: filterListView)
        
        // start show case when create stream view is start editting
        createView.shouldStartTutorial = {[weak self] in
            guard let _self = self else {return}
            if _self.isShowingShowcase || AppConfig.showCase.isShowTutorial(with: CREATE_STREAM_SCENE) {return}
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {[weak _self] timer in
                timer.invalidate()
                guard let __self = _self else {return}
                __self.checkNextTutorial()
            })
        }
    }
    private func setupCommonButton(button:UIButton) {
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 4
        if let image = button.image(for: UIControlState()) {
            button.setImage(image.withRenderingMode(.alwaysTemplate), for: UIControlState())
            button.imageView?.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
        button.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: UIControlState())
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize15)
        
        if !button.isEqual(btnTime) {
            button.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7122304137)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        socket.disconnect()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override var prefersStatusBarHidden: Bool {
		return true
	}
    
    func handlingSocket(){
        guard let user = Account.current else {
            return
        }
        
        room = Room(dict: [
            "user_id": user.id as AnyObject ,
            "stream_id": self.streamID as AnyObject,
            "api_token": user.api_token as AnyObject
            ])
        socket.connect()
        socket.on("connect") {[weak self] data, ack in
            guard let _selft = self else {
                return
            }
            _selft.socket.emit("create_stream", _selft.room.toDictCreate())
            _selft.socket.emit("create_product_pri", _selft.room.toDictCreate())
        }
        socket.on("num_of_views") {[weak self] data, ack in
            guard let _self = self else {
                return
            }
            let num = data[0] as? Int64
            _self.btnViews.setTitle(num?.toNumberStringView(false), for: .normal)
        }
        socket.on("num_of_likes") {[weak self] data, ack in
            guard let _self = self else {
                return
            }
            let num = data[0] as? Int64
            _self.btnLike.setTitle(num?.toNumberStringView(false), for: .normal)
        }
        socket.on("update_public_quantity") {[weak self] data, ack in
            guard let _self = self else {
                return
            }
            if let data = data[0] as? [JSON]{
                let listProducts = _self.listProduct
                var updatedProdcts:[Product] = []
                for item in data {
                    for pro in listProducts {
                        if let id = item["productId"] as? Int, let sale = item["noOfSell"] as? Int {
                            if Int(pro.id) == id {
                                var product = pro
                                product.noOfSell = sale
                                updatedProdcts.append(product)
                            }
                        } else if let id = item["productId"] as? String, let sale = item["noOfSell"] as? String {
                            if pro.id == id {
                                var product = pro
                                product.noOfSell = Int(sale)!
                                updatedProdcts.append(product)
                            }
                        } else if let id = item["productId"] as? Int, let sale = item["noOfSell"] as? String {
                            if Int(pro.id) == id {
                                var product = pro
                                product.noOfSell = Int(sale)!
                                updatedProdcts.append(product)
                            }
                        } else if let id = item["productId"] as? String, let sale = item["noOfSell"] as? Int {
                            if pro.id == id {
                                var product = pro
                                product.noOfSell = sale
                                updatedProdcts.append(product)
                            }
                        }
                    }
                }
                _self.listProduct = updatedProdcts
                _self.vShopView.listProducts = updatedProdcts
                _self.vShopView.reloadShopData()
            }
        }
        socket.on("update_private_quantity") {[weak self] data, ack in
            guard let _self = self else {
                return
            }
            if let data = data[0] as? [JSON]{
                let listProducts = _self.listProduct
                var updatedProdcts:[Product] = []
                for item in data {
                    for pro in listProducts {
                        if let id = item["productId"] as? Int, let sale = item["noOfSell"] as? Int {
                            if Int(pro.id) == id {
                                var product = pro
                                product.noOfSell = sale
                                updatedProdcts.append(product)
                            }
                        } else if let id = item["productId"] as? String, let sale = item["noOfSell"] as? String {
                            if pro.id == id {
                                var product = pro
                                product.noOfSell = Int(sale)!
                                updatedProdcts.append(product)
                            }
                        } else if let id = item["productId"] as? Int, let sale = item["noOfSell"] as? String {
                            if Int(pro.id) == id {
                                var product = pro
                                product.noOfSell = Int(sale)!
                                updatedProdcts.append(product)
                            }
                        } else if let id = item["productId"] as? String, let sale = item["noOfSell"] as? Int {
                            if pro.id == id {
                                var product = pro
                                product.noOfSell = sale
                                updatedProdcts.append(product)
                            }
                        }
                    }
                }
                _self.listProduct = updatedProdcts
                _self.vShopView.listProducts = updatedProdcts
                _self.vShopView.reloadShopData()
            }
        }
    }
    func startCountVideoTimes(){
        if timerVideoLive != nil {
            timerVideoLive.invalidate()
        }
        cDate = Date()
        
        timerVideoLive = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            let time = Date().timeIntervalSince(self.cDate!)
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            formatter.dateFormat = time > 60*60 ? "HH:mm:ss" : "mm:ss"
            
            self.btnTime.setTitle(formatter.string(from: Date(timeIntervalSince1970: (time))), for: UIControlState())
        }
    }
    func countDownToPostFB(){
        
        _ = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { (timer) in
            self.onShareFB()
        }
    }
    func onShareFB(){
        if FBSDKAccessToken.current() == nil {return}
        if FBSDKAccessToken.current().tokenString == nil {return}
        if FBSDKAccessToken.current().tokenString.characters.count == 0 {return}
        Server.shared.shareFBStream(stream_id: self.streamID, accessToken: FBSDKAccessToken.current().tokenString, { [weak self] result in
            guard let _self = self else {return}
            
            switch result {
            case .success(let data):
                _self.shareButton.isEnabled = false
                print(data)
            case .failure(.some(_)):
                print("upload failed")
            case .failure(.none):
                print("upload failed")
            }
            
        })
    }
    func showChoiceCategory(){
        categoryController = SelectCategoryController(nibName: "SelectCategoryController", bundle: Bundle.main)
        categoryController.isMutilSelect = false
        categoryController.isShowConfirmedButton = false
        categoryController.requiredMinSelected = 1
        self.addChildViewController(categoryController)
        categoryStackView.addArrangedSubview(categoryController.view)
        self.btnBackHome.setImage( UIImage(named: "icon_back_product")?.tint(with: UIColor(hex:"0x5b5b5b")).withRenderingMode(.alwaysOriginal), for: .normal)
        
    }
    func listernEvent() {
        // on touch button Done
        categoryController.onTouchButton = {[weak self] sender in
            guard let _self = self else {return}
            DispatchQueue.main.async {
                _self.choiceCategoryView.isHidden = true
                _self.createView.tfTitle.becomeFirstResponder()
                _self.createView.cardID = _self.category.id
                _self.createView.lbCatename.text = _self.category.name
            }
        }
        categoryController.onSelectItem = {[weak self] cate in
            guard let _self = self else {return}
            _self.category = cate
         //   DispatchQueue.main.async {
                _self.choiceCategoryView.isHidden = true
                _self.createView.tfTitle.becomeFirstResponder()
                _self.createView.cardID = _self.category.id
            _self.createView.lbCatename.text = _self.category.name
       //     }
        }
    }
    //MARK: AccessAuth
    
    func requestAccessForVideo() -> Void {
        containerView.isUserInteractionEnabled = false
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo);
        switch status  {
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted) in
                if(granted){
                    DispatchQueue.main.async {
                        self.session.running = true
                        self.containerView.isUserInteractionEnabled = true
                    }
                }else{
                    DispatchQueue.main.async {
                        self.onDissmissing?()
                        self.dismiss(animated: false, completion: nil)
                    }
                }
            })
            break;
        case AVAuthorizationStatus.authorized:
            session.running = true;
            containerView.isUserInteractionEnabled = true
            break;
        case AVAuthorizationStatus.denied:
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "", message: "Santube needs you grant access to the camera. Please allow Santube to access camera.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                    UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!)
                }))
                
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in
                    self.onDissmissing?()
                    self.dismiss(animated: false, completion: nil)
                    
                }))
                
                // show the alert
                self.present(alert, animated: true, completion: nil)
            }
            break
        case AVAuthorizationStatus.restricted:
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "", message: "Santube needs you grant access to the camera. Please allow Santube to access camera.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                    UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!)
                }))
                
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in
                    
                    self.onDissmissing?()
                    self.dismiss(animated: false, completion: nil)
                    
                }))
                
                // show the alert
                self.present(alert, animated: true, completion: nil)
            }
            break;
        }
    }
    
    func requestAccessForAudio() -> Void {
        let status = AVCaptureDevice.authorizationStatus(forMediaType:AVMediaTypeAudio)
        switch status  {
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeAudio, completionHandler: { (granted) in
                
            })
            break;
        case AVAuthorizationStatus.authorized:
            break;
        case AVAuthorizationStatus.denied:
            break
        case AVAuthorizationStatus.restricted:
            break;
        }
    }
    
    //MARK: - Callbacks
    
    func liveSession(_ session: LFLiveSession?, debugInfo: LFLiveDebug?) {
        print("debugInfo: \(String(describing: debugInfo?.currentBandwidth))")
    }
    
    func liveSession(_ session: LFLiveSession?, errorCode: LFLiveSocketErrorCode) {
        print("errorCode: \(errorCode.rawValue)")
    }
    
    func liveSession(_ session: LFLiveSession?, liveStateDidChange state: LFLiveState) {
        print("liveStateDidChange: \(state.rawValue)")
        switch state {
        case LFLiveState.ready:
            break;
        case LFLiveState.pending:
            break;
        case LFLiveState.start:
            startLiveButton.backgroundColor = .clear
            startLiveButton.setImage(UIImage(named: "stop_button"), for: .normal)
            handlingSocket()
            startCountVideoTimes()
            countDownToPostFB()
            break;
        case LFLiveState.error:
            break;
        case LFLiveState.stop:
            break;
        default:
            break;
        }
    }
    
    func onChooseCate(_ cateId: String?) {
        print("cate id \(String(describing: cateId))")
    }
    func onCreateStream(_ cateID: String?, titleStream: String?,_ type:Bool? = false) {
        createView.tfTitle.resignFirstResponder()
        guard let user = Account.current else {return}
        Server.shared.createStream(user_id: user.id, category_ids: [cateID!], product_ids: listProduct.flatMap{$0.id}, name: String(data: titleStream!.data(using: String.Encoding.nonLossyASCII, allowLossyConversion: false)!, encoding: String.Encoding.utf8), thumb: self.streamThumb, type:type! ? "public" : "public") {[weak self] result in
            guard let _self = self else {return}
            switch result  {
            case .success(let data):
                print(data)
                _self.stateLabel.text = data.name
                _self.streamObj =  data
                
                if _self.streamObj.santubeCode.characters.count > 0 {
                    _self.btnStreamCode.setImage(#imageLiteral(resourceName: "ic_earth").resizeImageWith(newSize: CGSize(width: 15, height: 15)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
                    _self.btnStreamCode.setTitle(_self.streamObj.santubeCode, for: UIControlState())
                }
                
                if _self.streamObj.password.characters.count > 0 {
                    _self.btnStreamCode.setImage(#imageLiteral(resourceName: "ic_private").resizeImageWith(newSize: CGSize(width: 15, height: 15)).tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: UIControlState())
                    _self.btnStreamCode.setTitle(_self.streamObj.password, for: UIControlState())
                }
                
                if _self.streamObj.santubeCode.characters.count == 0 && _self.streamObj.password.count == 0 {
                    _self.btnStreamCode.removeFromSuperview()
                }
                
                _self.startLiveStream(data.id)
            case .failure(_):
                print("No Steam Feature")
                break
            }
        }
    }
    func startLiveStream(_ streamid: String?){
        self.streamID = streamid
        startLiveButton.isSelected = true
        let stream = LFLiveStreamInfo()
        stream.url = "rtmp://santube.s3corp.vn:1935/santube/\(self.streamID!)"
        session.startLive(stream)
        createView.isHidden = true
        bottomView.isHidden = false
        startLiveButton.isHidden = false
        shareButton.isHidden = false
        beautyButton.isHidden = false
        cameraButton.isHidden = false
        stackIcon.isHidden = false
        if streamObj.products.count > 0{
            btnOpenShop.isHidden = false
            vShopView.listProducts = listProduct
            vShopView.setShopData(listProduct)
            self.view.bringSubview(toFront: btnOpenShop)
            self.view.bringSubview(toFront: vShopView)
        }
    }
    // open shop
    func onCreateProduct() {
        let vc = ListProductController(nibName: "ListProductController", bundle: Bundle.main)
        vc.streamID = self.streamID
        vc.delegate = self
        vc.listProduct =  listProduct
        let uinaviVC3 = UINavigationController.init(rootViewController: vc)
        
        self.present(uinaviVC3, animated: true, completion: nil)
    }
    func onOpenShop(_ products: [Product]) {
        listProduct = products
        if products.count > 0 {
            createView.lblOpenShop.text = products.count > 1 ? "\(products.count) products" : "\(products.count) product"
        }
    }
    func onRemoveShopView() {
        vShopView.isHidden = true
    }
    
    func onChangePublic() {
        isPublicShop = !isPublicShop
        if isPublicShop {
            self.socket.emit("create_product_pub", self.room.toDictCreate())
        }else {
            self.socket.emit("create_product_pri", self.room.toDictCreate())
        }
    }
    //MARK: - Events
    func onCameraChange(){
        let devicePositon = session.captureDevicePosition;
        session.captureDevicePosition = (devicePositon == AVCaptureDevicePosition.back) ? AVCaptureDevicePosition.front : AVCaptureDevicePosition.back;
    }
    func onUploadThumbClick(){
        self.createView.tfTitle.resignFirstResponder()
        let viewController = CustomPhotoPickerViewController()
        viewController.delegate = self
        viewController.didExceedMaximumNumberOfSelection = { [weak self] (picker) in
            
        }
        var configure = TLPhotosPickerConfigure()
        configure.numberOfColumn = 3
        configure.maxSelectedAssets = 1
        configure.allowedVideo = false
        viewController.configure = configure
        viewController.selectedAssets = self.selectedAssets
        
        self.present(viewController, animated: true, completion: nil)
    }
    
    //--------------------------
    
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        // use selected order, fullresolution image
        self.selectedAssets = withTLPHAssets
        getFirstSelectedImage()
    }
    
    func getFirstSelectedImage() {
        if let asset = self.selectedAssets.first {

            if let image = asset.fullResolutionImage {
                self.createView.tfTitle.becomeFirstResponder()
                self.createView.buttonCreate.isEnabled = false
                self.createView.btnUploadThumb.setImage(image, for: .normal)
                let imageView: UIImage = image.resizeImageWith(newSize: CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height*(image.size.height/image.size.width)))
                if let imageData = UIImageJPEGRepresentation(imageView, 0.5) as NSData? {
                    self.createView.btnUploadThumb.startAnimation(activityIndicatorStyle: .gray)
                    
                    Server.shared.uploadThumbStream(imageData: imageData as Data, { [weak self] result in
                        guard let _self = self else {return}
        
                        switch result {
                        case .success(let data):
                            _self.createView.buttonCreate.isEnabled = true
                            _self.createView.btnUploadThumb.stopAnimation()
                            _self.streamThumb = data["imageThumbUrl"] as? String
                        case .failure(.some(_)):
                            print("upload failed")
                        case .failure(.none):
                            print("upload failed")
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
    
    //----------
    func onFacebookClick(){
        
    }
    
    @IBAction func actionOpenShop(_ sender: Any) {
        vShopView.listProducts = listProduct
        vShopView.isHidden = false
    }
    
    func onBackClick(){
        self.choiceCategoryView.isHidden = false;
        self.createView.tfTitle.resignFirstResponder()
    }
    func didTappedStartLiveButton(_ button: UIButton) -> Void {
        startLiveButton.isSelected = !startLiveButton.isSelected;
        if (startLiveButton.isSelected) {
        } else {
            
            let alert = UIAlertController(title: "", message: "Are you sure you want to stop the live stream?", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.session.stopLive()
                self.socket.emit("close_stream", self.room.toDictCreate())
                self.socket.disconnect()
                self.startLiveButton.backgroundColor = UIColor.white
                DispatchQueue.main.async {
                    self.onDissmissing?()
                    if self.timerVideoLive != nil {
                        self.timerVideoLive.invalidate()
                    }
                    self.dismiss(animated: false, completion: nil)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { action in

            }))
            
            // show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func didBackAction(_ sender: UIButton) {
        self.onDissmissing?()
        self.dismiss(animated: false, completion: nil)
    }
    func didTappedBeautyButton(_ button: UIButton) -> Void {
        filterListView.isHidden = !filterListView.isHidden
    }
    func onChooseFilter(_ filterLevel: Int?) {
        session.filterLevel = filterLevel!
    }

    func didTappedShareButton(_ button: UIButton) -> Void  {
        
    }
    func didTappeCameraaButton(_ button: UIButton) -> Void  {
        let devicePositon = session.captureDevicePosition;
        session.captureDevicePosition = (devicePositon == AVCaptureDevicePosition.back) ? AVCaptureDevicePosition.front : AVCaptureDevicePosition.back;
    }
    //MARK: - Getters and Setters

    var session: LFLiveSession = {
        let audioConfiguration = LFLiveAudioConfiguration.defaultConfiguration(for: LFLiveAudioQuality.high)
        let videoConfiguration = LFLiveVideoConfiguration.defaultConfiguration(for: LFLiveVideoQuality.low1)
        let session = LFLiveSession(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration)
        return session!
    }()
    
    // video
    var containerView: UIView = {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        containerView.backgroundColor = UIColor.clear
//        containerView.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleHeight]
        return containerView
    }()
    var bottomView: UIView = {
        let bottomView = UIView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height - 56, width: UIScreen.main.bounds.width, height: 56))
        bottomView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        return bottomView
    }()
    // video title
    var stateLabel: UILabel = {
        let stateLabel = UILabel(frame: CGRect(x: 64, y: 20, width: UIScreen.main.bounds.width - (64*2), height: 44))
       // stateLabel.text = "00:00"
        stateLabel.textAlignment = NSTextAlignment.center
        stateLabel.textColor = UIColor(hex:"0xe6c400")
        stateLabel.backgroundColor = UIColor.clear
        stateLabel.font = UIFont.systemFont(ofSize: fontSize22)
        return stateLabel
    }()
    
    // close button
    var closeButton: UIButton = {
        let closeButton = UIButton(frame: CGRect(x: 10, y: 20, width: 44, height: 44))
        closeButton.setImage(UIImage(named: "icon_back_stream"), for: UIControlState())
        return closeButton
    }()
    
    // switch camera button
    var cameraButton: UIButton = {
        let cameraButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 54, y: 20, width: 44, height: 44))
        cameraButton.setImage(UIImage(named: "camra_preview"), for: UIControlState())
        cameraButton.setImage(UIImage(named: "camra_preview"), for: UIControlState())
        return cameraButton
    }()
    
    // filter buttion
    var beautyButton: UIButton = {
        let beautyButton = UIButton(frame: CGRect(x: 20, y: UIScreen.main.bounds.height - 50, width: 44, height: 44))
        beautyButton.setImage(UIImage(named: "camra_beauty"), for: UIControlState.selected)
        beautyButton.setImage(UIImage(named: "camra_beauty_close"), for: UIControlState())
        return beautyButton
    }()
    
    // filter buttion
    var shareButton: UIButton = {
        let shareButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 54, y: UIScreen.main.bounds.height - 50, width: 44, height: 44))
        shareButton.setImage(UIImage(named: "icon_share_fb"), for: UIControlState.selected)
        shareButton.setImage(UIImage(named: "icon_share_fb"), for: UIControlState())
        return shareButton
    }()
    
    // start button
    var startLiveButton: UIButton = {
        let startLiveButton = UIButton(frame: CGRect(x: (UIScreen.main.bounds.width - 50)/2, y: UIScreen.main.bounds.height - 50, width: 44, height: 44))
        startLiveButton.layer.cornerRadius = 22
        startLiveButton.backgroundColor = UIColor.white
        return startLiveButton
    }()
}

// MARK: - ShowCase
extension LiveStreamController: MaterialShowcaseDelegate {
    
    func checkNextTutorial() {
        isShowingShowcase = true
        if !AppConfig.showCase.isShowTutorial(with: CREATE_STREAM_SCENE) {
            startTutorial()
        }
    }
    
    // MARK: - init showcase
    func startTutorial(_ step:Int = 1) {
        // showcase
        configShowcase(MaterialShowcase(), step) { showcase, shouldShow in
            if shouldShow {
                showcase.delegate = self
                showcase.show(completion: nil)
            }
        }
    }
    
    func configShowcase(_ showcase:MaterialShowcase,_ step:Int = 1,_ shouldShow:((MaterialShowcase,Bool)->Void)) {
        if step == 1 {
            showcase.setTargetView(view: self.createView.btnCreateProduct, #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1))
            showcase.primaryText = ""
            showcase.identifier = SELL_PRODUCTS_BUTTON
            showcase.secondaryText = "click_here_go_to_list_sell_products".localized().capitalizingFirstLetter()
            shouldShow(showcase,true)
        } else if step == 2 {
            showcase.setTargetView(view: self.createView.btnUploadThumb, #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1))
            showcase.primaryText = ""
            showcase.identifier = THUMNAIL_STREAM_BUTTON
            showcase.secondaryText = "click_here_upload_thumbnail_stream".localized().capitalizingFirstLetter()
            shouldShow(showcase,true)
        } else if step == 3 {
            showcase.setTargetView(view: self.createView.btnFilter, #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1))
            showcase.primaryText = ""
            showcase.identifier = MINI_GAME_BUTTON
            showcase.secondaryText = "click_here_create_minigame".localized().capitalizingFirstLetter()
            shouldShow(showcase,true)
        } else {
            shouldShow(showcase,false)
            if step > 3 {
                AppConfig.showCase.setFinishShowcase(key: CREATE_STREAM_SCENE)
                checkNextTutorial()
            }
        }
    }
    
    // MARK: - showcase delegate
    func showCaseDidDismiss(showcase: MaterialShowcase) {
        if let step = showcase.identifier {
            if let s = Int(step) {
                let ss = s + 1
                startTutorial(ss)
            }
        }
        
    }
}
