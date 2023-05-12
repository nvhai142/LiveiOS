//
//  FollowedUsersListView.swift
//  SanTube
//
//  Created by Dai Pham on 3/8/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

fileprivate var KeepTap:String = "KeepTap[_]"

class FollowedUsersListView: UIView {

    // MARK: - api
    func load(data:[User]) {
        releaseView()
        listItems = data
        for (_,item) in data.enumerated() {
            let imageView = UIImageViewRound(frame: bounds)
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.loadImageUsingCacheWithURLString(item.avatar)
            imageView.layer.borderColor = UIColor(hex:"0xFCCE2F").cgColor
            imageView.layer.borderWidth = 1.0
            stackImages.addArrangedSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            let width = imageView.widthAnchor.constraint(equalToConstant: 45)
            width.priority = 750
            imageView.addConstraint(width)
            let height = imageView.heightAnchor.constraint(equalToConstant: 45)
            height.priority = 1000
            imageView.addConstraint(height)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
            imageView.addGestureRecognizer(tap)
            imageView.isUserInteractionEnabled = true
            listTapGestures.append(tap)
        }
    }
    
    func startLoading(isStart:Bool) {
        if isStart {
            loadFakeData()
            Loader.addLoaderToViews(stackImages.arrangedSubviews)
        } else {
            Loader.removeLoaderFromViews(stackImages.arrangedSubviews)
        }
    }
    
    func releaseView() {
        for (i,v) in stackImages.arrangedSubviews.enumerated() {
            if listTapGestures.count == 0 {break}
            v.removeGestureRecognizer(listTapGestures[i])
        }
        _ = stackImages.arrangedSubviews.map{$0.removeFromSuperview()}
        listItems.removeAll()
        listTapGestures.removeAll()
    }
    
    // MARK: - event
    func tap(_ gesture:UITapGestureRecognizer) {
        if listItems.count == 0 || listTapGestures.count == 0 {return}
        for (i,_) in stackImages.arrangedSubviews.enumerated() {
            let tap = listTapGestures[i]
            if  tap.isEqual(gesture){
                self.onSelectedItem?(listItems[i])
            }
        }
    }
    
    // MARK: - private
    private func config() {
        // add scrollview
        scrollView = UIScrollView(frame: bounds)
        scrollView.isPagingEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 10).isActive = true
        bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0).isActive = true
        
        // add stackview
        stackImages = UIStackView(frame: bounds)
        stackImages.axis = .horizontal
        stackImages.spacing = 10
        scrollView.addSubview(stackImages)
        stackImages.translatesAutoresizingMaskIntoConstraints = false
        stackImages.topAnchor.constraint(equalTo: stackImages.superview!.topAnchor, constant: 10).isActive = true
        stackImages.leadingAnchor.constraint(equalTo: stackImages.superview!.leadingAnchor, constant: 0).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: stackImages.bottomAnchor, constant: 0).isActive = true
        scrollView.heightAnchor.constraint(equalTo: stackImages.heightAnchor, multiplier: 1, constant: 15).isActive = true
        let trSI = stackImages.trailingAnchor.constraint(equalTo: stackImages.superview!.trailingAnchor)
        trSI.priority = 250
        scrollView.addConstraint(trSI)
    }

    private func loadFakeData() {
        releaseView()
        for _ in 0..<7 {
            let imageView = UIImageViewRound(frame: bounds)
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.image = #imageLiteral(resourceName: "placeholder")
            stackImages.addArrangedSubview(imageView)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            let width = imageView.widthAnchor.constraint(equalToConstant: 45)
            width.priority = 1000
            imageView.addConstraint(width)
            let height = imageView.heightAnchor.constraint(equalToConstant: 45)
            height.priority = 1000
            imageView.addConstraint(height)
        }
    }
    
    // MARK: - init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        config()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        config()
    }
    
    // MARK: - closures
    var onSelectedItem:((User)->Void)?
    
    // MARK: - properties
    var listItems:[User] = []
    var listTapGestures:[UITapGestureRecognizer] = []
    
    // MARK: - outlet
    var scrollView:UIScrollView!
    var stackImages:UIStackView!

}
