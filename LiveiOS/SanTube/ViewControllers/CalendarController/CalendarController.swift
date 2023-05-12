//
//  CalendarController.swift
//  SanTube
//
//  Created by Dai Pham on 11/29/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class CalendarController: BaseController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        addDefaultMenu()
    }

    deinit {
        print("calendarController deinit")
    }

}
