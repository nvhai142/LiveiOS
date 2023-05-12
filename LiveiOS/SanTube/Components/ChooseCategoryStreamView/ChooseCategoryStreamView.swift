//
//  ChooseCategoryStreamView.swift
//  SanTube
//
//  Created by Dai Pham on 12/1/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

// MARK: - List
class ChooseCategoryStreamView: UIView {

    // MARK: - outlet
    var scrollView: UIScrollView!
    var stackCategories: UIStackView!
    
    // MARK: - closure
    var onSelect:((Category)->Void)?
    
    // MARK: - properties
    var index:Int = 0
    var data:[Category]?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        
        scrollView = UIScrollView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 10, height: 10)))
        self.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: scrollView.superview!.topAnchor, constant: 0).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: scrollView.superview!.leadingAnchor, constant: 0).isActive = true
        scrollView.superview?.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 0).isActive = true
        scrollView.superview?.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0).isActive = true
       
        
        stackCategories = UIStackView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 10, height: 10)))
        stackCategories.axis = .horizontal
        stackCategories.spacing = 10
        scrollView.addSubview(stackCategories)
        stackCategories.translatesAutoresizingMaskIntoConstraints = false
        
        stackCategories.topAnchor.constraint(equalTo: stackCategories.superview!.topAnchor, constant: 0).isActive = true
        stackCategories.leadingAnchor.constraint(equalTo: stackCategories.superview!.leadingAnchor, constant: 0).isActive = true
        let trailStack = stackCategories.superview?.trailingAnchor.constraint(equalTo: stackCategories.trailingAnchor, constant: 0)
        trailStack!.priority = 1
        stackCategories.superview?.addConstraint(trailStack!)
        stackCategories.superview?.bottomAnchor.constraint(equalTo: stackCategories.bottomAnchor, constant: 0).isActive = true
        
        scrollView.heightAnchor.constraint(equalTo: stackCategories.heightAnchor, multiplier: 1).isActive = true
        let width = stackCategories.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1)
        width.priority = 250
        self.addConstraint(width)
        
        reload()
    }
    
    // MARK: - interface
    func reload() {
        Server.shared.getCategories(UserManager.currentUser()?.id,loadCache:true) {[weak self] result in
            guard let _self = self else {return}
            switch result {
            case .success(let list):
                let listTemp = list.flatMap{Category.parse(from: $0)}
                _self.generate(from: listTemp.sorted(by: { (item, item1) -> Bool in
                    return item.isMarked && !item1.isMarked
                }))
            case .failure(let msg):
                print(msg as Any)
                _self.generate(from: nil)
            }
            
        }
    }
    
    func removeEventForBlock() {
        _ = stackCategories.arrangedSubviews.map({ (view) in
            view.removeEvent()
        })
    }
    
    // MARK: - private
    func generate(from list:[Category]? = nil) {
        data = list
        _ = stackCategories.arrangedSubviews.reversed().map{$0.removeFromSuperview()}
        if let listcate = list {
            var i = 1
            for item in listcate {
                if let view = Bundle.main.loadNibNamed("ChooseCategoryStreamBlockView", owner: self, options: [:])?.first as? ChooseCategoryStreamBlockView{
                    view.tag = i
                    view.load(category: item)
                    stackCategories.addArrangedSubview(view)
                    view.onSelect = {[weak self] cate, index in
                        guard let _self = self else {return}
                        _self.hightLight(index: index-1)
                        _self.onSelect?(cate)
                    }
                    i += 1
                }
            }
        }
    }
    
    func hightLight(index: Int = 0) {
        if data == nil {return}
        if index < 0 || index > data!.count - 1 {return}
        var i = 0
        for view in stackCategories.arrangedSubviews {
            if let v = view as? ChooseCategoryStreamBlockView {
                v.selected(i == index)
            }
            i += 1
        }
        
    }
}

// MARK: - Block
class ChooseCategoryStreamBlockView:UIView {
    
    // MARK: - outlet
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var imvIcon: UIImageView!
    
    // MARK: - properties
    var cate:Category?
    var onSelect:((Category,Int)->Void)?
    
    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        configView()
        self.addEvent {[weak self] in
            guard let _self = self else {return}
            if let c = _self.cate {
                _self.onSelect?(c,_self.tag)
            }
        }
    }
    
    // MARK: - interface
    func load(category:Category) {
        self.cate = category
       lblName.text = category.name
        imvIcon.loadImageUsingCacheWithURLString(category.iconUrl,size: nil,placeHolder: nil,false) {[weak self] image in
            guard let _self = self else {return}
            _self.imvIcon.image = image?.tint(with: #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        }
    }
    
    func selected(_ isSelect:Bool = false) {
        self.imvIcon.image = self.imvIcon.image?.tint(with: isSelect ? #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
        lblName.textColor = isSelect ? #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    // MARK: - private
    func configView() {
        imvIcon.backgroundColor = UIColor.clear
        lblName.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
}
