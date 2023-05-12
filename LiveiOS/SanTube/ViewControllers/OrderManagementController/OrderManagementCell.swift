//
//  OrderManagementCell.swift
//  SanTube
//
//  Created by Dai Pham on 12/26/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

enum OrderHistoryType {
    case seller // display data seller
    case buyer // display data buyer
}

protocol OrderManagementCellDelegate {
    func orderCell(delete order:Order, isForceDelete:Bool)
    func orderCell(undo order:Order)
}

class OrderManagementCell: UITableViewCell {

    // MARK: - init
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        configView()
    }

    // MARK: - api
    func load(_ data:Order,_ isLoadBuyer:Bool = true) {
        self.order = data
        var user = data.seller
        if type == .buyer {
            user = data.buyer
        }
        
        lblName.text = user!.name
        
        let nameProducts:[String] = data.products.flatMap({ (product) -> String in
            return product.name
        })
        
        // reset
        lblDescription.text = "products".localized().capitalized
        for (index,item) in nameProducts.enumerated() {
            if index == 0 {
                lblDescription.text! += ":\n\(index + 1). " + item
            } else {
                lblDescription.text! += "\n\(index + 1). " + item
            }
        }
        
        lblStatus.text = data.status.localized().capitalizingFirstLetter()
        
        let stringDate = data.updated_at.UTCToLocal(format: "dd/MM/yyyy")
        if stringDate == Date().toString(dateFormat: "dd/MM/yyyy") {
            lblCreatedDate.text =  data.updated_at.UTCToLocal(format: "HH:mm") + "\n" + "today".localized().capitalized
        } else {
            lblCreatedDate.text =  data.updated_at.UTCToLocal(format: "HH:mm") + "\n" + stringDate
        }
        
        imvAvatar.loadImageUsingCacheWithURLString(user!.avatar)
        
        var color = UIColor.red
        if data.status == AppConfig.status.order.create_new() {
            color = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        } else if data.status == AppConfig.status.order.finish() {
            color = #colorLiteral(red: 0.05098039216, green: 0.6039215686, blue: 0.007843137255, alpha: 1)
        } else if data.status == AppConfig.status.order.rejected() {
            color = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
        } else if data.status == AppConfig.status.order.progress() {
            color = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
        }
        
        vwStatus.backgroundColor = color
        
        // set state delete for this order
        if let ord = Support.orderDeleted.getOrderDeleted() {
            if ord.id == data.id {
                widthAnchorVWDelete.constant = vwCover.superview!.frame.size.width
                btnDelete.isSelected = true
                btnForceDelete.isHidden = false
                self.vwCover.isHidden = true
                self.setNeedsLayout()
            }
        }
    }
    
    func shouldSelect() -> Bool {
        return !btnDelete.isSelected
    }
    
    // MARK: - event button
    @IBAction func actionDelete(_ sender: UIButton) {
        if sender.isEqual(btnDelete) {
            if sender.isSelected == true {
                widthAnchorVWDelete.constant = 0
                btnDelete.isSelected = false
                btnForceDelete.isHidden = true
                self.setNeedsLayout()
                UIView.animate(withDuration: 0.2, animations: {
                    self.layoutIfNeeded()
                    self.vwCover.isHidden = false
                })
                undoDeleteOrder()
            } else {
                widthAnchorVWDelete.constant = vwCover.superview!.frame.size.width
                btnDelete.isSelected = true
                btnForceDelete.isHidden = false
                self.setNeedsLayout()
                UIView.animate(withDuration: 0.2, animations: {
                    self.layoutIfNeeded()
                    self.vwCover.isHidden = true
                })
                involkeDeleteOrder(isForce: false)
            }
        }
    }
    @IBAction func forceDelete(_ sender: UIButton) {
        involkeDeleteOrder(isForce: true)
    }
    
    // MARK: - handle gesture
    var beginDragXPoint:CGFloat = 0
    func handleGesture(pan:UIPanGestureRecognizer) {
        if vwCover.isHidden || type == .seller {return}
        let translation = pan.translation(in: self)
        switch pan.state {
        case .began:
            beginDragXPoint = translation.x
            break
        case .ended:
//            btnDelete.setTitle("delete".localized().capitalized, for: .highlighted)
            beginDragXPoint = translation.x
            let halfWidth = vwCover.superview!.frame.size.width/2
            if widthAnchorVWDelete.constant > 80 && widthAnchorVWDelete.constant <= halfWidth {
                widthAnchorVWDelete.constant = 80
                btnDelete.isSelected = false
            } else if widthAnchorVWDelete.constant > halfWidth {
                vwCover.isHidden = true
                widthAnchorVWDelete.constant = halfWidth*2
                btnDelete.isSelected = true
                btnForceDelete.isHidden = false
                btnDelete.setTitle("undo".localized().capitalized, for: .highlighted)
                involkeDeleteOrder(isForce: false)
            } else {
                widthAnchorVWDelete.constant = 0
            }
            
            btnForceDelete.isHidden = !btnDelete.isSelected
            
            self.setNeedsLayout()
            UIView.animate(withDuration: 0.2, animations: {
                self.layoutIfNeeded()
            })
            break
        case .changed:
            vwCover.isHidden = false
            btnForceDelete.isHidden = true
            widthAnchorVWDelete.constant -= translation.x - beginDragXPoint
            if widthAnchorVWDelete.constant < 0 {
                widthAnchorVWDelete.constant = 0
            }
            self.setNeedsLayout()
            beginDragXPoint = translation.x
            break
        case .possible:
            break
        case .cancelled:
            print("calcled")
        case .failed:
            print("failed")
        }
    }
    
    // MARK: - private
    private func involkeDeleteOrder(isForce:Bool) {
        guard let order = order else { return }
        delegate?.orderCell(delete: order, isForceDelete: isForce)
    }
    
    private func undoDeleteOrder() {
        guard let order = order else { return }
        delegate?.orderCell(undo: order)
    }
    
    private func configView() {
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture))
        panGesture.delegate = self
        vwCover.addGestureRecognizer(panGesture)
        
        lblName.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        lblName.font = UIFont.boldSystemFont(ofSize: fontSize16)
        
        lblDescription.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        lblDescription.font = UIFont.systemFont(ofSize: fontSize16)
        
        lblStatus.font = UIFont.boldSystemFont(ofSize: fontSize16)
        lblStatus.textAlignment = .center
        lblStatus.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        lblCreatedDate.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        lblCreatedDate.font = UIFont.systemFont(ofSize: fontSize16)
        lblCreatedDate.textAlignment = .center
        
        vwCover.layer.cornerRadius = 5
        vwStatus.layer.cornerRadius = 5
        vwStatus.clipsToBounds = true
        vwDelete.layer.cornerRadius = 5
        
        vwDelete.backgroundColor = UIColor.red
        
        btnDelete.setTitle("delete".localized().capitalized, for: .normal)
        btnDelete.setTitle("undo".localized().capitalized, for: .selected)
        btnDelete.setTitleColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: UIControlState())
        
        btnDelete.setImage(#imageLiteral(resourceName: "ic_undo").tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)), for: .selected)
        btnDelete.setImage(nil, for: .normal)
        btnDelete.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        
        btnForceDelete.isHidden = true
    }
    
    // MARK: - override
    override func prepareForReuse() {
        imvAvatar.image = nil
        lblStatus.textAlignment = .center
        btnForceDelete.isHidden = true
        widthAnchorVWDelete.constant = 0
        btnDelete.isSelected = false
        btnForceDelete.isHidden = true
        vwCover.isHidden = false
    }
    
    // prevent conflict between two pan gesture
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - properties
    var order:Order?
    var type:OrderHistoryType = .seller
    var panGesture:UIPanGestureRecognizer!
    var delegate:OrderManagementCellDelegate?
    
    // MARK: - outlet
    @IBOutlet weak var vwCover: UIView!
    @IBOutlet weak var imvAvatar: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var vwStatus: UIView!
    @IBOutlet weak var lblCreatedDate: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var vwDelete: UIView!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var widthAnchorVWDelete: NSLayoutConstraint!
    @IBOutlet weak var btnForceDelete: UIButton!
    
}
