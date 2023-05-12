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
class SelectCategoryController: BasePresentController {
    
    // MARK: - outlet
    @IBOutlet weak var collectView: UICollectionView!
    @IBOutlet weak var btnDone: UIButton!
    
    // MARK: - properties
    var listCategories:[Category] = []
    var listCateFavories:[Category] = []
    var requiredMinSelected:Int = 1
    
    var isMutilSelect:Bool = false
    var isShowConfirmedButton: Bool = true
    
    // MARK: - closure
    var onSelectItem:((Category)->Void)?
    var onSelectListItems:(([Category])->Void)?
    
    var onTouchButton:((UIButton)->Void)?
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configText()
        configView()
        
        self.validate()
    }
    
    // MARK: - event
    @IBAction func processDone(_ sender: UIButton) {
        self.onTouchButton?(sender)
    }
    
    // MARK: - interface
    func load(categories:[Category]) {
        view.stopLoading()
        
        self.listCategories.removeAll()
        self.listCategories.append(contentsOf: categories)
        self.collectView.reloadData()
        self.validate()
    }
    
    func setListSelected(list:[Category]) {
        listCateFavories = list
        collectView.reloadData()
        self.validate()
    }
    
    func setTitleButton(_ title:String? = nil) {
        if let text = title {
            btnDone.setTitle(text, for: UIControlState())
        }
    }
    
    // MARK: - private
    func configView() {
        collectView.register(UINib(nibName: "CategoriesCollectionViewCell", bundle: Bundle.main), forCellWithReuseIdentifier: "cell")
        
        btnDone.setTitleColor(UIColor.gray, for: UIControlState())
        btnDone.titleLabel?.font = UIFont.boldSystemFont(ofSize: fontSize17)
        
        if !isShowConfirmedButton {
            btnDone.isHidden = true
        }
    }
    
    func configText() {
        btnDone.setTitle("confirm".localized().uppercased(), for: UIControlState())
    }
    
    func validate() {
        btnDone.isEnabled = self.listCateFavories.count >= self.requiredMinSelected
        btnDone.layer.backgroundColor = btnDone.isEnabled ? #colorLiteral(red: 0.9960784314, green: 0.8549019608, blue: 0, alpha: 0.9176386444).cgColor : #colorLiteral(red: 0.9019607843, green: 0.768627451, blue: 0, alpha: 1).cgColor
    }
}

// MARK: - Extension Collectview delegate
extension SelectCategoryController:UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CategoriesCollectionViewCell
        let item = self.listCategories[indexPath.row]
        let isCheck = self.listCateFavories.filter{$0.id == item.id}.count > 0
        cell.load(cate: item, check: isCheck)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = self.listCategories[indexPath.row]
        
        if !isMutilSelect {
            self.listCateFavories.removeAll()
            self.collectView.reloadData()
        }
        
        var i = self.listCateFavories.count - 1
        var isCheck = false
        
        if isMutilSelect {
            _ = self.listCateFavories.reversed().map {
                if $0.id == item.id {
                    self.listCateFavories.remove(at: i)
                    isCheck = true
                }
                i -= 1
            }
        }
        
        if !isCheck {
            self.listCateFavories.append(item)
        }
        
        self.onSelectItem?(item)
        self.onSelectListItems?(self.listCateFavories)
        
        self.collectView.reloadItems(at: [indexPath])
        self.validate()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let realspace = space * (column - 1)
        
        let width = (collectionView.frame.size.width - realspace)/3 - 5/3
        return CGSize(width:width, height:width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(space)
    }
}

