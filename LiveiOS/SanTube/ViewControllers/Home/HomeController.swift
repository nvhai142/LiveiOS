//
//  HomeController.swift
//  SanTube
//
//  Created by Dai Pham on 3/1/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class HomeController: BaseController {

    // MARK: - api
    
    // MARK: - private
    private func config() {
        
        addMenuBar()
        addContents()
    }
    
    private func addMenuBar() {
        menuBar = Bundle.main.loadNibNamed("ExtendedNavBarView", owner: self, options: nil)?.first as! ExtendedNavBarView
        stackContainer.insertArrangedSubview(menuBar, at: 0)
        menuBar.translatesAutoresizingMaskIntoConstraints = false
        menuBar.heightAnchor.constraint(equalToConstant: navigationController!.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.size.height).isActive = true
        menuBar.controller = self
        // handle closures
        menuBar.onSelectIndex = {[weak self] index in
            guard let _self = self else {return}
            _self.scrollView.scrollRectToVisible(CGRect(origin: CGPoint(x: CGFloat(index) * _self.scrollView.frame.size.width, y: 0), size: _self.scrollView.frame.size), animated: true)
        }
    }
    
    private func addContents() {
        featuredController = FeaturedController(nibName: "FeaturedController", bundle: nil)
        allCateogoriesController = CategoriesController(nibName: "CategoriesController", bundle: nil)
        
        addChildViewController(featuredController)
        addChildViewController(allCateogoriesController)
        
        stackContents.addArrangedSubview(featuredController.view)
        featuredController.view.translatesAutoresizingMaskIntoConstraints = false
        featuredController.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        
        stackContents.addArrangedSubview(allCateogoriesController.view)
        allCateogoriesController.view.translatesAutoresizingMaskIntoConstraints = false
        allCateogoriesController.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        
        scrollView.contentOffset = CGPoint.zero
    }
    
    // MARK: - init
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        scrollView.delegate = self
        config()
    }
    
    // MARK: - closures
    
    // MARK: - properties
    var menuBar:ExtendedNavBarView!
    var featuredController:FeaturedController!
    var allCateogoriesController:CategoriesController!
    var currentOffset:CGFloat = 0
    
    // MARK: - outlet
    @IBOutlet weak var stackContainer: UIStackView!
    @IBOutlet weak var stackContents: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
}

extension HomeController:UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if menuBar == nil {return}
        menuBar.scrollDidView(scrollView)
        let percent = scrollView.contentOffset.x*100/scrollView.frame.size.width
        
        let minAlpha:CGFloat = 0
        let maxAlpha:CGFloat = 1
        
        if scrollView.contentOffset.x != currentOffset {
            scrollView.bringSubview(toFront: allCateogoriesController.view)

            allCateogoriesController.view.alpha = minAlpha + percent*(maxAlpha - minAlpha)/100
            featuredController.view.alpha = minAlpha + (100-percent)*(maxAlpha - minAlpha)/100
            
        }
        
        currentOffset = scrollView.contentOffset.x
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 {
            menuBar.selectIndex(1)
        } else {
            menuBar.selectIndex(0)
        }
    }
}
