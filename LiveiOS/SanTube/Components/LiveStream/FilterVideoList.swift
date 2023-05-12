//
//  FilterVideoList.swift
//  SanTube
//
//  Created by Hai NguyenV on 12/28/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

protocol FilterViewDelegate: class {
    func onChooseFilter( _ filterLevel: Int?)
}
class FilterVideoList: UIView {


    @IBOutlet var contentView: UIView!
    @IBOutlet weak var scrollview: UIScrollView!
    weak var delegate: FilterViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    private func commonInit(){
        Bundle.main.loadNibNamed("FilterVideoList", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
    }
    @IBAction func actionFilterChoise(_ sender: UIButton) {
        delegate?.onChooseFilter(sender.tag)
    }
}
