//
//  BasePresentController.swift
//  SanTube
//
//  Created by Dai Pham on 11/16/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class BasePresentController: UIViewController {

    // MARK: - closures
    var onDissmiss:(()->Void)?
    
    // MARK: - init
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.providesPresentationContextTransitionStyle = true
        self.definesPresentationContext = true
        self.modalPresentationStyle=UIModalPresentationStyle.overCurrentContext
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    deinit {
        #if DEBUG
            print("\(self.description) dealloc")
        #endif
    }
}
