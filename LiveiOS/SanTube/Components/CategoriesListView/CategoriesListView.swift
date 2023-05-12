//
//  CategoriesListView.swift
//  BUUP
//
//  Created by Dai Pham on 11/13/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class CategoriesListView: UIView {

    // MARK: - outlet
    @IBOutlet weak var scrollViewOne: UIScrollView!
    @IBOutlet weak var scrollViewTwo: UIScrollView!
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var stackRowOne: UIStackView!
    @IBOutlet weak var stackRowTwo: UIStackView!
    @IBOutlet weak var lblCate: UILabel!
    @IBOutlet weak var vwTitle: UIView!
    
    // MARK: - constraint
    @IBOutlet weak var constraintHeightTitle: NSLayoutConstraint!
    
    // MARK: - properties
    var listCategories:[Category] = []
    
    // MARK: - closure
    var onSelectCategory:((Category)->Void)?
    var onBack:(()->Void)?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configText()
        configView()
    }
    
    // MARK: - interface
    func load(_ cates:[Category]) {
        self.listCategories = cates
        loadData()
    }
    
    func hideList(isHide:Bool,_ scrollView:UIScrollView) {
        
        if scrollViewOne.isHidden != isHide && scrollViewTwo.isHidden != isHide{
            self.setNeedsLayout()
            UIView.animate(withDuration: 0.25, animations: {
                self.scrollViewOne.isHidden = isHide
                self.scrollViewTwo.isHidden = isHide
                self.constraintHeightTitle.constant = isHide ? 30 : 40
                self.vwTitle.backgroundColor = isHide ? UIColor.black : UIColor.white
                self.lblCate.textColor = !isHide ? UIColor.black : UIColor.white
                self.vwTitle.alpha = isHide ? 0.3 : 1
                self.backgroundColor = isHide ? UIColor.clear : UIColor.white
                self.setNeedsLayout()
            })
        }
    }
    
    // MARK: - button event
    @IBAction func touchButton(_ sender: Any) {
        self.onBack?()
    }
    
    // MARK: - interface
    func setSelect(index:Int) {
        if index < 0 || index > self.listCategories.count-1 || self.listCategories.count == 0 {return}
        let cate = self.listCategories[index]
        var i = 0
        _ = stackRowOne.arrangedSubviews.map {
            ($0 as! CategoryView).isfocus(i == index)
            i += 1
        }
        
        _ = stackRowTwo.arrangedSubviews.map {
            ($0 as! CategoryView).isfocus(i == index)
            i += 1
        }
        
        self.selectCategory(cate: cate)
    }
    
    // MARK: - private
    func loadData() {
        _ = stackRowOne.arrangedSubviews.map{$0.removeFromSuperview()}
        _ = stackRowTwo.arrangedSubviews.map{$0.removeFromSuperview()}
        let maxItem:CGFloat = 4
        let maxWidth = (UIScreen.main.bounds.size.width / maxItem)
        for (i,item) in self.listCategories.enumerated() {
            let view = Bundle.main.loadNibNamed("CategoryView", owner: self, options: [:])?.first as! CategoryView
            view.load(item)
            view.tag = i
            if i < 4 {
                stackRowOne.addArrangedSubview(view)
            } else {
                stackRowTwo.addArrangedSubview(view)
            }
            view.translatesAutoresizingMaskIntoConstraints = false
            let width = view.widthAnchor.constraint(equalToConstant: maxWidth)
            width.priority = 751
            view.addConstraint(width)
//            let height = view.heightAnchor.constraint(equalToConstant: 55)
//            height.priority = 750
//            view.addConstraint(height)
            
            // action from subview
            view.onSelectCategory = {[weak self] cate,index in
                guard let _self = self else {return}
                _self.setSelect(index: index)
            }
        }
    }
    
    func selectCategory(cate:Category) {
        self.lblCate.text = cate.name
        self.onSelectCategory?(cate)
    }
    
    func configView() {
        lblCate.font = UIFont.boldSystemFont(ofSize: fontSize18)
        lblCate.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    func configText() {
        
    }
    
    func configTitle(_ label:UILabel) {
        label.font = UIFont.boldSystemFont(ofSize: fontSize24)
        label.textColor = #colorLiteral(red: 0.631372549, green: 0.631372549, blue: 0.631372549, alpha: 1)
    }
}
