//
//  WelcomeController.swift
//  SanTube
//
//  Created by Dai Pham on 11/16/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

fileprivate let column = CGFloat(3)
fileprivate let space = CGFloat(10)

// MARK: - basic
class WelcomeController: BasePresentController {

    // MARK: - outlet
    @IBOutlet weak var vwTitle: UIView!
    @IBOutlet weak var stackTitle: UIStackView!
    @IBOutlet weak var lblWelcome: UILabel!
    @IBOutlet weak var lblWelcomeNote: UILabel!
    @IBOutlet weak var imvAvatar: UIImageViewRound!
    @IBOutlet weak var vwHeader: UIView!
    @IBOutlet weak var stackContainer: UIStackView!
    
    // MARK: - properties
    var listCategories:[Category] = []
    var listCateFavories:[Category] = []
    var categoryController:SelectCategoryController!
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()

        configView()
        configText()
        listernEvent()
        
        Server.shared.getCategories(UserManager.currentUser()?.id,loadCache:true) {[weak self] result in
            guard let _self = self else {return}
            switch result {
            case .success(let list):
                let listTemp = list.flatMap{Category.parse(from: $0)}.filter{$0.name != "Others"}
                _self.categoryController.load(categories:listTemp.sorted(by: { (item, item1) -> Bool in
                    return item.isMarked && !item1.isMarked
                }))
                _self.listCateFavories = listTemp.filter{$0.isMarked}
                if _self.listCateFavories.isEmpty {
                    _self.listCateFavories = listTemp.choose(3)
                }
                _self.categoryController.setListSelected(list: _self.listCateFavories)
            case .failure(let msg):
                print(msg as Any)
            }
            
        }
    }
    
    // MARK: - event
    func listernEvent() {
        // on touch button Done
        categoryController.onTouchButton = {[weak self] sender in
            guard let _self = self else {return}
            guard let user = Account.current else {
                AppConfig.navigation.gotoHomeAfterSigninSuccess()
                return
                
            }
            
            sender.startAnimation(activityIndicatorStyle: .white)
            
            let server = Server.shared.self
            let cached = AppConfig.cached.self
            let navigation = AppConfig.navigation.self
            
            server.markFavoriteCategories(_self.listCateFavories.flatMap{$0.id},user.id) {result in
                guard let _ = self else {return}
                // get categories
                server.getCategories(user.id) {result in
                    switch result {
                    case .success(let data ):
                        cached.setCacheCategories(data: data)
                    case .failure(_):
                        print("error")
                    }
                    sender.stopAnimation()
                    navigation.gotoHomeAfterSigninSuccess()
                }
                
            }
            
            UserDefaults.standard.set(true, forKey: "APP::HadShowelcome")
        }
        
        // on select list categories
        categoryController.onSelectListItems = {[weak self] list in
            guard let _self = self else {return}
            _self.listCateFavories = list
        }
        
    }
    
    // MARK: - private
    func configView() {
        
        categoryController = SelectCategoryController(nibName: "SelectCategoryController", bundle: Bundle.main)
        categoryController.isMutilSelect = true
        categoryController.requiredMinSelected = 3
        self.addChildViewController(categoryController)
        stackContainer.addArrangedSubview(categoryController.view)
        
        imvAvatar.layer.borderColor = UIColor(hex:"0xFEDA00").cgColor
        imvAvatar.backgroundColor = UIColor(hex:"0xFEDA00")
        imvAvatar.layer.borderWidth = 5
        
        lblWelcome.font = UIFont.boldSystemFont(ofSize: fontSize22)
        
        vwHeader.backgroundColor = #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1)
    }
    
    func configText() {
        lblWelcomeNote.text = "let's_improve_your_experience_tap_at_least_3_your_favorites".localized()
        
        categoryController.setTitleButton("confirm".localized().uppercased())
        
        guard let user = Account.current else {
            AppConfig.navigation.gotoHomeAfterSigninSuccess()
            return
            
        }
        
        imvAvatar.loadImageUsingCacheWithURLString(user.avatar, size: imvAvatar.frame.size, placeHolder: UIImage(named: APP_LOGO_PLACEHOLDER)?.tint(with: UIColor.black))
        lblWelcome.text = "\("welcome".localized().capitalized) \(user.name) !"
    }
}
