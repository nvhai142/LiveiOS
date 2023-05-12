//
//  ProfileController.swift
//  BUUP
//
//  Created by Hai NguyenV on 10/31/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class ProfileController: UIViewController {

    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbGender: UILabel!
    @IBOutlet weak var btnLogout: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let acc = Account.current else {self.dismiss(animated: true, completion: nil); return }
        // Do any additional setup after loading the view.
        lbName.text = acc.name
        lbGender.text = acc.gender
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.loadImageUsingCacheWithURLString(acc.avatar, size: avatar.frame.size, placeHolder: nil)
        
        title = "profile".localized().uppercased()
        addDefaultMenu()
        configView()
    }
    
    deinit {
        print("ProfileController deinit")
    }
    
    // MARK: - event
    @IBAction func logOut(_ sender: Any) {
        AppConfig.navigation.logOut()
    }
    
    // MARK: - private
    func configView() {
        btnLogout.layer.cornerRadius = 7
        btnLogout.setTitle("logout".localized().uppercased(), for: UIControlState())
        btnLogout.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize20)
    }
    
    func addDefaultMenu () {
        
        // add right menu
        let btnClose = UIButton(type: .custom)
        btnClose.tag = 100
        btnClose.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        btnClose.contentMode = .scaleAspectFill
        btnClose.clipsToBounds = true
        btnClose.addTarget(self, action: #selector(self.menuPress(sender:)), for: .touchUpInside)
        btnClose.setTitle("close".localized().capitalized, for: UIControlState())
        btnClose.setTitleColor(UIColor(hex:"0x6599FF"), for: UIControlState())
        let itemClose = UIBarButtonItem(customView: btnClose)
        self.navigationItem.rightBarButtonItem = itemClose
        
        
        // add left menu
        let lblTitleApp = UILabel(frame: CGRect(x:0, y:0, width:100, height:30))
        lblTitleApp.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
        lblTitleApp.font = UIFont.boldSystemFont(ofSize: fontSize20)
        lblTitleApp.textColor = UIColor(hex:"0x6599FF")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView:lblTitleApp)
    }
    
    @objc func menuPress(sender:UIButton) {
        
        if( sender.tag == 100) {
            self.dismiss(animated: true, completion: nil)
        } else {
            
        }
    }
}
