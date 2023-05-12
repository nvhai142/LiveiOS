//
//  Extensions.swift
//  BUUP
//
//  Created by Dai Pham on 11/7/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit
import AVKit

// MARK: - STRING
extension String {
    
    func getListSub(patterns:[String]) -> [String] {
        var matchResults:[String] = []
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive) {
                let uls = regex.matches(in: self, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, self.characters.count))
                
                for match in uls {
                    matchResults.append((self as NSString).substring(with: match.range))
                }
            }
        }
        return matchResults
    }
    
    func trim(pattern:[String]) -> String {
        var temp:String = self
        for p in pattern {
            temp = temp.replacingOccurrences(of: p, with: "", options: .regularExpression)
        }
        return temp
    }
    
    func removeScript() -> String {
        return self.trim(pattern: ["</(.*)>", "<(.*)/>"])
    }
    
    func isValidEmail() -> Bool {
        var returnValue = true
        let emailRegEx = "(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}" +
            "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
            "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-" +
            "z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5" +
            "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
            "9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
        "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        do {
            let regex = try NSRegularExpression(pattern: emailRegEx)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            
            if results.count == 0
            {
                returnValue = false
            }
            
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            returnValue = false
        }
        
        return  returnValue
    }
    
    func isValidPassword() -> Bool {
        var returnValue = true
        if(self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count < 6 || self.getListSub(patterns: ["</(.*)>", "<(.*)/>"]).count > 0){
            returnValue = false
        }
        if (self as NSString).substring(to: 0) == " " {
            returnValue = false
        }
        return returnValue
    }
        
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let other = String(characters.dropFirst())
        return first + other
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    func convertToJSON() -> JSON{
        if let data = self.data(using: String.Encoding.utf8) {
            
            do {
                if let dictonary: JSON = try JSONSerialization.jsonObject(with: data, options: []) as? JSON {
                    return dictonary
                }
            } catch let error as NSError {
                print(error)
                return [:]
            }
        }
        return [:]
    }
    
    func toDate2() -> Date{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter.date(from: self) ?? Date.init(timeIntervalSinceNow: 0)
    }
    
    func toDate3() -> Date{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter.date(from: self) ?? Date.init(timeIntervalSinceNow: 0)
    }
    
    func localToUTC(format:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.calendar = NSCalendar.current
        dateFormatter.timeZone = TimeZone.current
        
        let dt = dateFormatter.date(from: self)
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = format
        
        return dateFormatter.string(from: dt!)
    }
    
    func UTCToLocal(format:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let dt = dateFormatter.date(from: self)
        
        let dateFormatter1 = DateFormatter()
        dateFormatter1.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter1.dateFormat = format
        dateFormatter1.timeZone = TimeZone.current
        return dateFormatter1.string(from: dt!)
    }
    
    
    /// Create QRCode Image
    ///
    /// - Parameter size: size QR Image
    /// - Returns: optional image
    func createQRCodeImage(_ size:CGSize = CGSize(width: 115, height: 115)) -> UIImage? {
        
        if self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).characters.count == 0 {
            return nil
        }
        
        let defaultSize:CGFloat = 23
        var sz = size
        if sz.width < defaultSize {
            sz.width = defaultSize
        }
        
        if sz.height < defaultSize {
            sz.height = defaultSize
        }
        
        let data = self.data(using:String.Encoding.isoLatin1, allowLossyConversion: false)
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter!.setValue(data, forKey: "inputMessage")
        filter!.setValue("Q", forKey: "inputCorrectionLevel")
        
        let transform = CGAffineTransform(scaleX: sz.width/defaultSize, y: sz.width/defaultSize)
        
        if let output = filter!.outputImage?.applying(transform) {
            return UIImage(ciImage: output)
        }
        return UIImage(ciImage:filter!.outputImage!)
    }
    
    func stringByAddHtml(_ font:UIFont? = nil,
                         _ completion:@escaping ((NSAttributedString?)->Void)) {
        DispatchQueue.global().async {
            
            if let data = "<html><head><style type='text/css'>body {font-size:\(fontSize16); color:#ffffff; font-family:'\(UIFont.systemFont(ofSize: fontSize16).familyName)'} a {color:#e6c400;text-decoration: none;}</style></head><body>\(self)</body></html>".data(using: String.Encoding.utf8, allowLossyConversion: true) {
                if let result =  try? NSAttributedString(data: data,
                                                         options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType],
                                                         documentAttributes: nil) {
                    DispatchQueue.main.async {
                        completion(result)
                    }
                    return
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}

// MARK: - IMAGEVIEW
private var KeepTap:String = "KeepTap"
private var KeepTapEvent:String = "KeepTapEvent"
private var BLURMASK:String = "BLURMASK"
let imageCache = NSCache<NSString, UIImage>()
extension UIImageView {
    func loadImageUsingCacheWithURLString(_ URLString: String, size:CGSize? = nil, placeHolder: UIImage? = nil,_ loadCached:Bool = true,_ onComplete:((UIImage?)->Void)? = nil){
        
        self.startAnimating()
        
        self.image = placeHolder
        
        if let cachedImage = imageCache.object(forKey: NSString(string: URLString)) {
            if loadCached {
                self.image = cachedImage
                self.stopAnimating()
                onComplete?(self.image)
                return
            }
        }
        
        if let url = URL(string: URLString) {
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                
                //print("RESPONSE FROM API: \(response)")
                if error != nil {
                    if let er = error {
                        print("ERROR LOADING IMAGES FROM URL: \(er)")
                    }
                    DispatchQueue.main.async {
                        self.stopAnimating()
                    }
                    return
                }
                    if let data = data {
                        if let downloadedImage = UIImage(data: data) {
                            
                            if let s = size {
                                let imgScale = downloadedImage.resizeImageWith(newSize: s)
                                if let imageData = UIImageJPEGRepresentation(imgScale, 0.7) {
                                    if let img = UIImage(data: imageData) {
                                        imageCache.setObject(img, forKey: NSString(string: URLString))
                                        DispatchQueue.main.async {
                                            self.image = img
                                            onComplete?(self.image)
                                        }
                                    }
                                }
                            } else {
                                imageCache.setObject(downloadedImage, forKey: NSString(string: URLString))
                                DispatchQueue.main.async {
                                    self.image = downloadedImage
                                    onComplete?(self.image)
                                }
                            }
                        }
                    }
                DispatchQueue.main.async {
                    self.stopAnimating()
                }
            }).resume()
        } else {
            self.stopAnimating()
            onComplete?(self.image)
        }
    }
    
    // use for mark favourite categories
    func addMask(color:UIColor,_ alpha:CGFloat = 1,_ removeIconCheck:Bool = false) {
        let mask = UIView(frame: self.bounds)
        if !removeIconCheck {
            let imv = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            imv.image = UIImage(named: "ic_check_circle_128")?.tint(with: UIColor.white)
            mask.addSubview(imv)
            imv.translatesAutoresizingMaskIntoConstraints = false
            imv.topAnchor.constraint(equalTo: imv.superview!.topAnchor, constant: 5).isActive = true
            imv.rightAnchor.constraint(equalTo: imv.superview!.rightAnchor, constant: -5).isActive = true
            imv.widthAnchor.constraint(equalToConstant: 30).isActive = true
            imv.heightAnchor.constraint(equalToConstant: 30).isActive = true
        }
        self.addSubview(mask)
        mask.tag = 9989
        mask.backgroundColor = color.withAlphaComponent(alpha)
        mask.translatesAutoresizingMaskIntoConstraints = false
        mask.topAnchor.constraint(equalTo: mask.superview!.topAnchor, constant: 0).isActive = true
        mask.trailingAnchor.constraint(equalTo: mask.superview!.trailingAnchor, constant: 0).isActive = true
        mask.bottomAnchor.constraint(equalTo: mask.superview!.bottomAnchor, constant: 0).isActive = true
        mask.leadingAnchor.constraint(equalTo: mask.superview!.leadingAnchor, constant: 0).isActive = true
    }
    
    func removeMask() {
        _ = self.subviews.reversed().map{if $0.tag == 9989 {$0.removeFromSuperview()}}
    }
    
    func blur(position:[String]? = ["bottom"]) {
        removeBlur()
        let blur = CAGradientLayer()
        var rect = self.bounds
        rect.size.height = rect.size.height * 30/100
        rect.origin.y  = self.bounds.size.height - rect.size.height
        blur.frame = rect
        let transWhiteColor = UIColor.black.withAlphaComponent(0).cgColor
        let endColor = UIColor.black.withAlphaComponent(0.5).cgColor
        blur.colors = [transWhiteColor,endColor]
        layer.insertSublayer(blur, at: 0)
        objc_setAssociatedObject(self, &BLURMASK, blur, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func removeBlur() {
        if let layer = objc_getAssociatedObject(self, &BLURMASK) as? CAGradientLayer {
            layer.removeFromSuperlayer()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if let layer = objc_getAssociatedObject(self, &BLURMASK) as? CAGradientLayer {
            var rect = self.bounds
            rect.size.height = rect.size.height * 30/100
            rect.origin.y  = self.bounds.size.height - rect.size.height
            layer.frame = rect
        }
    }
}

class UIImageViewRound: UIImageView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = frame.size.width/2
        layer.masksToBounds = true
    }
}

// MARK: - IMAGE
public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    func resizeImageWith(newSize: CGSize) -> UIImage {
        
        let horizontalRatio = newSize.width / size.width
        let verticalRatio = newSize.height / size.height
        
        let ratio = max(horizontalRatio, verticalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func maskRoundedImage(radius: CGFloat) -> UIImage {
        let width = min(self.size.width,self.size.height)
        let imageView: UIImageView = UIImageView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: width)))
        imageView.contentMode = .scaleAspectFill
        imageView.image = self
        let layer = imageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = self.size.width/2
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size,false, UIScreen.main.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return roundedImage!
    }
    
    func tint(with color: UIColor) -> UIImage {
        var image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.set()
        
        image.draw(in: CGRect(origin: .zero, size: size))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    static func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint? = nil) -> UIImage {
        let textColor = UIColor.red
        let textFont = UIFont.boldSystemFont(ofSize: 12)
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ] as [String : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        var p = CGPoint.zero
        if let pp = point {
            p = pp
        }
        let rect = CGRect(origin: p, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func isEqualToImage(image: UIImage) -> Bool {
        guard let data1 = UIImagePNGRepresentation(self),
            let data2 = UIImagePNGRepresentation(image) else {return false}
        let dt1 = data1 as NSData
        let dt2 = data2 as NSData
        return dt1.isEqual(dt2)
    }
        
}

// MARK: - UICOLOR
extension UIColor {
    convenience init(hex: String,_ alpha:CGFloat? = 1) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: alpha!
        )
    }
}

// MARK: - DATE
extension Date {
    func convertDateFormat(from: String, to: String, dateString: String?) -> String? {
        let fromDateFormatter = DateFormatter()
        fromDateFormatter.dateFormat = from
        var formattedDateString: String? = nil
        if dateString != nil {
            let formattedDate = fromDateFormatter.date(from: dateString!)
            if formattedDate != nil {
                let toDateFormatter = DateFormatter()
                toDateFormatter.dateFormat = to
                formattedDateString = toDateFormatter.string(from: formattedDate!)
            }
        }
        return formattedDateString
    }
    
    func toString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    func addedBy(minutes:Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
}

// MARK: - BUTTON
var ButtonBag = "ButtonBag"
var ButtonColorObjc = "ButtonColorobjc"
var ButtonBorderWidthObjc = "ButtonBorderWithobjc"
var ButtonBackgroundColorObjc = "ButtonBackgroundColorobjc"
extension UIButton {
    
    func startAnimation(activityIndicatorStyle:UIActivityIndicatorViewStyle,_ isHideContent:Bool = false) {
        
        self.setTitleColor(UIColor.clear, for: .disabled)
        
        stopAnimation()
        
        self.isEnabled = false
        
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorStyle)
        self.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        indicator.startAnimating()
        
        if isHideContent {
            objc_setAssociatedObject(self, &ButtonColorObjc, self.titleColor(for: self.state), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &ButtonBorderWidthObjc, self.layer.borderWidth, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &ButtonBackgroundColorObjc, self.backgroundColor, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.setTitleColor(UIColor.clear, for: UIControlState())
        }
    }
    
    func stopAnimation() {
        _ = self.subviews.map({
            if $0.isKind(of:UIActivityIndicatorView.self) {
                $0.removeFromSuperview()
            }
        })
        if let x = objc_getAssociatedObject(self, &ButtonColorObjc) as? UIColor {
            self.setTitleColor(x, for: self.state)
        }
        if let x = objc_getAssociatedObject(self, &ButtonBorderWidthObjc) as? CGFloat {
            self.layer.borderWidth = x
        }
        if let x = objc_getAssociatedObject(self, &ButtonBackgroundColorObjc) as? UIColor {
            self.backgroundColor = x
        }
        objc_setAssociatedObject(self, &ButtonColorObjc, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &ButtonBorderWidthObjc, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &ButtonBackgroundColorObjc, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.isEnabled = true
    }
}

// MARK: - LABEL
class UILabelPadding: UILabel {
//    override func drawText(in rect: CGRect) {
//        let insets = UIEdgeInsets.init(top: 0, left: 5, bottom: 0, right: 5)
//        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
//    }
}

class UILabelRound: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        layer.cornerRadius = frame.size.height/2
    }
}

private var RECTLINKS:String = "RECTLINKS"
private var TAPLINKS:String = "TAPLINKS"
private var EVENTLINKS:String = "EVENTLINKS"
extension UILabel {
    
    var tap:UITapGestureRecognizer {
        if let  singleTap = objc_getAssociatedObject(self,&TAPLINKS) as? UITapGestureRecognizer  { return singleTap}
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.tapLinks(_:)))
//        singleTap.numberOfTapsRequired = 1 // you can change this value
        return singleTap
    }
    
    func handleLinks(_ label:UILabel? = nil,
                     _ action:((String?)->Void)) {
        guard let attribut = attributedText else {return}
        var rectlinks:JSON = [:]
        attribut.enumerateAttribute(NSLinkAttributeName,
                                    in: NSMakeRange(0, attribut.length),
                                    options: .longestEffectiveRangeNotRequired) { (value, range, stop) in
                                        rectlinks[NSStringFromCGRect(boundingRect(range: range))] = value
        }
        
        if rectlinks.count > 0 {
            objc_setAssociatedObject(self, &RECTLINKS, rectlinks, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            #if DEBUG
                print(rectlinks)
            #endif
            let tap1 = tap
            addGestureRecognizer(tap1)
            isUserInteractionEnabled = true
            objc_setAssociatedObject(self, &TAPLINKS, tap1, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &EVENTLINKS, action, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } else {
            removeHandleLinks()
        }
    }
    
    func tapLinks(_ tap:UITapGestureRecognizer) {
        guard let action = objc_getAssociatedObject(self, &EVENTLINKS) as? (String?)->Void,
            let tap = objc_getAssociatedObject(self, &TAPLINKS) as? UITapGestureRecognizer,
            let rectlinks =  objc_getAssociatedObject(self,&RECTLINKS) as? JSON else {return}
        let touchPoint = tap.location(in: self)
        for key in rectlinks.keys {
            if CGRectFromString(key).contains(touchPoint) {
                if let url = rectlinks[key] as? URL {
                    action(url.absoluteString)
                } else if let str = rectlinks[key] as? NSString {
                    action(str as String)
                }
                break
            }
        }
    }
    
    func removeHandleLinks() {
        removeEvent()
        objc_setAssociatedObject(self, &RECTLINKS, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &TAPLINKS, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &EVENTLINKS, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func boundingRect(range:NSRange)->CGRect {
        guard let attribut = attributedText else {return CGRect.zero}
        let textStorage = NSTextStorage(attributedString: attribut)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: self.bounds.size)
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        
        var glyphRange =  NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
}


// MARK: - UIVIEW
private var CLOSEBUTTON:String = "CloseBUTTON"
private var CHECKBAG:String = "CHECKBAG"
extension UIView {
    
    var singleTap:UITapGestureRecognizer {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.tapDetected(_:)))
//        singleTap.numberOfTapsRequired = 1 // you can change this value
        return singleTap
    }
    
    func addEvent(_ event:(()->Void)) {
        if objc_getAssociatedObject(self, &KeepTap) != nil {return}
        
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(singleTap)
        objc_setAssociatedObject(self, &KeepTap, singleTap, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &KeepTapEvent, event, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func removeEvent() {
        if let tap = objc_getAssociatedObject(self, &KeepTap) as? UITapGestureRecognizer {
            self.removeGestureRecognizer(tap)
            objc_setAssociatedObject(self, &KeepTap, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        if let _ = objc_getAssociatedObject(self, &KeepTapEvent) as? (()->Void) {
            objc_setAssociatedObject(self, &KeepTapEvent, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    //Action
    func tapDetected(_ sender:UITapGestureRecognizer) {
        if let event = objc_getAssociatedObject(self, &KeepTapEvent) as? (()->Void) {
            event()
        }
    }
    
    func startLoading(activityIndicatorStyle:UIActivityIndicatorViewStyle,_ hiddenSubview:Bool = false) {
        if hiddenSubview {
            _ = self.subviews.map({
                $0.isHidden = true
            })
        }
        stopLoading()
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorStyle)
        self.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        indicator.startAnimating()
    }
    
    func stopLoading() {
        _ = self.subviews.map({
            if $0.isKind(of:UIActivityIndicatorView.self) {
                $0.removeFromSuperview()
            }
        })
    }
    
    func showNoData(_ message:String = "no_data_stream".localized()) {
        removeNoData()
        let mask = UIView(frame: self.bounds)
        mask.backgroundColor = UIColor.clear
        let imv = UILabel(frame: mask.frame)
        imv.text = message
        imv.textAlignment = .center
        imv.numberOfLines = 0
        mask.tag = 9989
        
        self.addSubview(mask)
        mask.translatesAutoresizingMaskIntoConstraints = false
        mask.centerXAnchor.constraint(equalTo: mask.superview!.centerXAnchor, constant: 0).isActive = true
        mask.centerYAnchor.constraint(equalTo: mask.superview!.centerYAnchor, constant: 0).isActive = true
        mask.widthAnchor.constraint(equalTo: mask.superview!.widthAnchor, constant: 0).isActive = true
        mask.heightAnchor.constraint(equalTo: mask.superview!.heightAnchor, constant: 0).isActive = true
        
        mask.addSubview(imv)
        imv.translatesAutoresizingMaskIntoConstraints = false
        imv.topAnchor.constraint(equalTo: imv.superview!.topAnchor, constant: 0).isActive = true
        imv.rightAnchor.constraint(equalTo: imv.superview!.rightAnchor, constant: 0).isActive = true
        imv.bottomAnchor.constraint(equalTo: imv.superview!.bottomAnchor, constant: 0).isActive = true
        imv.leftAnchor.constraint(equalTo: imv.superview!.leftAnchor, constant: 0).isActive = true
    }
    
    func removeNoData() {
        _ = self.subviews.reversed().map{if $0.tag == 9989 {$0.removeFromSuperview()}}
    }
    
    func addCloseButton(_ size:CGSize? = nil,_ event:(()->Void)) {
        
        if let image = objc_getAssociatedObject(self, &CLOSEBUTTON) as? UIImageView {
            image.removeEvent()
            image.removeFromSuperview()
        }
        
        let imgClose = UIImageView(frame: self.bounds)
        self.addSubview(imgClose)
        objc_setAssociatedObject(self, &CLOSEBUTTON, imgClose, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        imgClose.translatesAutoresizingMaskIntoConstraints = false
        var width = CGFloat(30)
        var height = CGFloat(30)
        if let si = size {
            width = si.width
            height = si.height
        }
        imgClose.widthAnchor.constraint(equalToConstant: width).isActive = true
        imgClose.heightAnchor.constraint(equalToConstant: height).isActive = true
        imgClose.topAnchor.constraint(equalTo: imgClose.superview!.topAnchor, constant: 2).isActive = true
        imgClose.leadingAnchor.constraint(equalTo: imgClose.superview!.leadingAnchor, constant: 2).isActive = true
        imgClose.image = #imageLiteral(resourceName: "ic_close_black_76").tint(with: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        imgClose.addEvent(event)
    }
    
    func getWindowTop(to containerView: UIView? = nil) -> CGPoint {
        let targetRect = self.convert(self.bounds , to: containerView)
        return targetRect.origin
    }
    
    /// set Bag for view
    ///
    /// - Parameters:
    ///   - bag: number to display: 0 is hidden bag
    ///   - position: 0 => center | 1 => left | 2 => right
    func setBag(_ bag:Int,_ position:Int = 0,_ size:CGSize = CGSize(width: 15, height: 15)) {
        if let label = objc_getAssociatedObject(self, &ButtonBag) as? UILabelRound{
            if bag == 0 {
                label.removeFromSuperview()
                objc_setAssociatedObject(self, &ButtonBag, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return
            } else {
                label.text = "\(bag)"
            }
        } else {
            if bag == 0 {return}
            let label = UILabelRound(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            label.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            label.textAlignment = .center
            label.backgroundColor = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
            label.font = UIFont.systemFont(ofSize: fontSize13)
            label.text = "\(bag)"
            self.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            if position == 0 {
                label.centerXAnchor.constraint(equalTo: label.superview!.centerXAnchor, constant: (size.width/2)*30/100).isActive = true
                label.topAnchor.constraint(equalTo: label.superview!.topAnchor, constant: 0).isActive = true
            } else if position == 1 {
                label.leadingAnchor.constraint(equalTo: label.superview!.leadingAnchor, constant: -(size.width/2)).isActive = true
                label.topAnchor.constraint(equalTo: label.superview!.topAnchor, constant: 0).isActive = true
            } else if position == 2 {
                label.trailingAnchor.constraint(equalTo: label.superview!.trailingAnchor, constant:5).isActive = true
                label.topAnchor.constraint(equalTo: label.superview!.topAnchor, constant: 0).isActive = true
            }
            
            
            let width = label.widthAnchor.constraint(greaterThanOrEqualToConstant: 15)
            width.priority = 751
            label.addConstraint(width)
            label.heightAnchor.constraint(equalToConstant: 15).isActive = true
            label.layoutIfNeeded()
            label.setNeedsDisplay()
            objc_setAssociatedObject(self, &ButtonBag, label, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func setChecked(_ isCheck:Bool,_ position:Int = 0,_ size:CGSize = CGSize(width: 15, height: 15)) {
        if let label = objc_getAssociatedObject(self, &CHECKBAG) as? UIImageViewRound{
            if !isCheck {
                label.removeFromSuperview()
                objc_setAssociatedObject(self, &CHECKBAG, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return
            }
        } else {
            if !isCheck {return}
            let label = UIImageViewRound(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            label.contentMode = .scaleAspectFit
            label.backgroundColor = UIColor.clear
            label.image = #imageLiteral(resourceName: "ic_check_128")
            self.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            if position == 0 {
                label.centerXAnchor.constraint(equalTo: label.superview!.centerXAnchor, constant: (size.width/2)*30/100).isActive = true
                label.topAnchor.constraint(equalTo: label.superview!.topAnchor, constant: 0).isActive = true
            } else if position == 1 {
                label.leadingAnchor.constraint(equalTo: label.superview!.leadingAnchor, constant: -(size.width/2)).isActive = true
                label.topAnchor.constraint(equalTo: label.superview!.topAnchor, constant: 0).isActive = true
            } else if position == 2 {
                label.trailingAnchor.constraint(equalTo: label.superview!.trailingAnchor, constant:5).isActive = true
                label.topAnchor.constraint(equalTo: label.superview!.topAnchor, constant: 0).isActive = true
            }
            
            
            let width = label.widthAnchor.constraint(greaterThanOrEqualToConstant: size.width)
            width.priority = 751
            label.addConstraint(width)
            label.heightAnchor.constraint(equalToConstant: size.height).isActive = true
            label.layoutIfNeeded()
            label.setNeedsDisplay()
            objc_setAssociatedObject(self, &CHECKBAG, label, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func dropShadow(offsetX: CGFloat, offsetY: CGFloat, color: UIColor, opacity: Float, radius: CGFloat, scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: offsetX, height: offsetY)
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}

// MARK: - TEXTVIEW
private var TEXTVIEWPLACEHOLDER:String = "TextViewPlaceholder"
extension UITextView {
    func showPlaceHolder(placeholder:String? = nil) {
        if let label = objc_getAssociatedObject(self, &TEXTVIEWPLACEHOLDER) as? UILabel{
            if placeholder == nil {
                label.removeFromSuperview()
                objc_setAssociatedObject(self, &TEXTVIEWPLACEHOLDER, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return
            } else {
                label.text = placeholder
            }
        } else {
            guard let placeholder = placeholder else {return}
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
            label.textColor = #colorLiteral(red: 0.7803921569, green: 0.7803921569, blue: 0.8039215686, alpha: 1)
            label.textAlignment = .left
            label.font = UIFont.systemFont(ofSize: fontSize16)
            label.text = placeholder
            self.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.leadingAnchor.constraint(equalTo: label.superview!.leadingAnchor, constant:5).isActive = true
            label.trailingAnchor.constraint(equalTo: label.superview!.trailingAnchor, constant:10).isActive = true
            label.topAnchor.constraint(equalTo: label.superview!.topAnchor, constant: 5).isActive = true
            label.heightAnchor.constraint(equalToConstant: 21).isActive = true
            objc_setAssociatedObject(self, &TEXTVIEWPLACEHOLDER, label, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - Timer
final class TimerInvocation: NSObject {
    
    var callback: () -> ()
    
    init(callback: @escaping () -> ()) {
        self.callback = callback
    }
    
    func invoke(timer:Timer) {
        callback()
    }
}

extension Timer {
    
    static func scheduleTimer(timeInterval: TimeInterval, repeats: Bool, invocation: TimerInvocation) {
        
        Timer.scheduledTimer(
            timeInterval: timeInterval,
            target: invocation,
            selector: #selector(TimerInvocation.invoke(timer:)),
            userInfo: nil,
            repeats: repeats)
    }
}

// MARK: - TABLEVIEW
private var PullRefreshEvent:String = "PullRefreshEvent"
private var RefreshControl:String = "PullRefreshEvent"
extension UITableView {
    
    func pullResfresh(_ event:(()->Void)) {
        
        if objc_getAssociatedObject(self, &RefreshControl) == nil {
            let refreshControl = UIRefreshControl()
            objc_setAssociatedObject(self, &RefreshControl, refreshControl, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            refreshControl.attributedTitle = nil//NSAttributedString(string: "pull_to_refresh".localized())
            refreshControl.addTarget(self, action: #selector(self.refresh(sender:)), for: UIControlEvents.valueChanged)
            self.addSubview(refreshControl)
        }
        
        objc_setAssociatedObject(self, &PullRefreshEvent, event, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func endPullResfresh() {
        if let refreshControl = objc_getAssociatedObject(self, &RefreshControl) as? UIRefreshControl {
            if refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
        }
    }
    
    func refresh(sender:AnyObject) {
        // override it
        if let event = objc_getAssociatedObject(self, &PullRefreshEvent) as? (()->Void) {
            event()
        }
    }
}

// MARK: - COLLECTVIEW
extension UICollectionView {
    func pullResfresh(_ event:(()->Void)) {
        objc_setAssociatedObject(self, &PullRefreshEvent, event, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func endPullResfresh() {
        if let refreshControl = objc_getAssociatedObject(self, &RefreshControl) as? UIRefreshControl {
            if refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
        }
    }
    
    func isUsingPullRefresh() -> Bool {
        if let refreshControl = objc_getAssociatedObject(self, &RefreshControl) as? UIRefreshControl {
            return refreshControl.isRefreshing
        }
        return false
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        let refreshControl = UIRefreshControl()
        objc_setAssociatedObject(self, &RefreshControl, refreshControl, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        refreshControl.attributedTitle = nil//NSAttributedString(string: "pull_to_refresh".localized())
        refreshControl.addTarget(self, action: #selector(self.refresh(sender:)), for: UIControlEvents.valueChanged)
        self.addSubview(refreshControl)
    }
    
    func refresh(sender:AnyObject) {
        // override it
        if let event = objc_getAssociatedObject(self, &PullRefreshEvent) as? (()->Void) {
            event()
        }
    }
}

// MARK: - ARRAY
extension Array {
    /// Returns an array containing this sequence shuffled
    var shuffled: Array {
        var elements = self
        return elements.shuffle()
    }
    /// Shuffles this sequence in place
    @discardableResult
    mutating func shuffle() -> Array {
        let count = self.count
        indices.lazy.dropLast().forEach {
            guard case let index = Int(arc4random_uniform(UInt32(count - $0))) + $0, index != $0 else { return }
            self.swapAt($0, index)
        }
        return self
    }
    var chooseOne: Element { return self[Int(arc4random_uniform(UInt32(count)))] }
    func choose(_ n: Int) -> Array { return Array(shuffled.prefix(n)) }
    
    func reArrange(fromIndex: Int, toIndex: Int) -> Array{
        var arr = self
        let element = arr.remove(at: fromIndex)
        arr.insert(element, at: toIndex)
        
        return arr
    }
}

// MARK: - UINAVIGATIONCONTROLLER
extension UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.providesPresentationContextTransitionStyle = true
        self.definesPresentationContext = true
        self.modalPresentationStyle=UIModalPresentationStyle.overCurrentContext
    }
}

// MARK: - UITABBARCONTROLLER
extension UITabBar {
    
//    open override func layoutSubviews() {
//        super.layoutSubviews()
//        removeTopLine()
//        addTopLine(color: UIColor(hex:"0xe6c400"))
//    }
//    
//    func addTopLine(color:UIColor,_ alpha:CGFloat? = 1) {
//
//        self.backgroundColor = UIColor(hex:"0xededed")
//        
//        let mask = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.bounds.maxX, height: 1)))
//        mask.tag = 99899
//        self.addSubview(mask)
//        mask.backgroundColor = color.withAlphaComponent(alpha!)
//    }
//    
//    func removeTopLine() {
//        _ = self.subviews.reversed().map{if $0.tag == 99899 || $0.tag == 998100 {$0.removeFromSuperview()}}
//    }
}

// MARK: - NOTIFICATION.NAME
extension Notification.Name {
    static let kAVPlayerViewControllerDismissingNotification = Notification.Name.init("AVPLAYER:dismissing")
}

// MARK: - AVPLAYERVIEWCONTROLLER
extension AVPlayerViewController {
    // override 'viewWillDisappear'
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // now, check that this ViewController is dismissing
        if self.isBeingDismissed == false {
            return
        }
        
        // and then , post a simple notification and observe & handle it, where & when you need to.....
        NotificationCenter.default.post(name: .kAVPlayerViewControllerDismissingNotification, object: nil)
    }
}

// MARK: - INT
extension Int64 {
    func toNumberStringView(_ isSuffix:Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        var result1:String?
        var suffix = " \("views".localized())"
        if self == 1 {
            suffix = " \("view".localized())"
        }
        
        result1 = formatter.string(from: NSNumber(value: self))
        
        if self > 999 && self < 10000 {
            result1 = formatter.string(from: NSNumber(value: self/1000))
        } else if self > 9999 && self < 1000000 {
            result1 = formatter.string(from: NSNumber(value: self/1000000))?.appending("K")
        } else if self > 999999 && self < 1000000000 {
            result1 = formatter.string(from: NSNumber(value: self/1000000000))?.appending("M")
        } else if self > 999999999 {
            result1 = formatter.string(from: NSNumber(value: self/1000000000000))?.appending("B")
        }
        
        if let result =  result1 {
            if !isSuffix {
                return result
            }
            return result + suffix
        } else {
            return "\(self)"
        }
    }
}

extension CGFloat {
    func toPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(self)))?.replacingOccurrences(of: ",", with: ".") ?? "\(self)"
        
    }
}

// MARK: - UIWindow
private var WindowController:String = "WindowController"
extension UIWindow {
    func setController(vc:UIViewController? = nil) {
        objc_setAssociatedObject(self, &WindowController, vc, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    func quickViewcontroller()->QuickViewController {
        if let controller = objc_getAssociatedObject(self, &WindowController) as? QuickViewController {
            return controller
        } else {
          let controller =  QuickViewController(nibName: "QuickViewController", bundle: Bundle.main)
            setController(vc: controller)
            return controller
        }
    }
}

// MARK: - UIVIEW KEY ANIMATIOn
extension UIViewKeyframeAnimationOptions {
    
    static var curveEaseIn: UIViewKeyframeAnimationOptions {
        get {
            return UIViewKeyframeAnimationOptions(animationOptions: .curveEaseIn)
        }
    }
    
    static var curveEaseOut: UIViewKeyframeAnimationOptions {
        get {
            return UIViewKeyframeAnimationOptions(animationOptions: .curveEaseOut)
        }
    }
    
    static var curveEaseInOut: UIViewKeyframeAnimationOptions {
        get {
            return UIViewKeyframeAnimationOptions(animationOptions: .curveEaseInOut)
        }
    }
    
    static var curveLinear: UIViewKeyframeAnimationOptions {
        get {
            return UIViewKeyframeAnimationOptions(animationOptions: .curveLinear)
        }
    }
    
    init(animationOptions: UIViewAnimationOptions) {
        rawValue = animationOptions.rawValue
    }
    
}

// MARK: - AVPlayerLayer
extension CGAffineTransform {
    static let ninetyDegreeRotation = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
}

extension AVPlayerLayer {
    
    var fullScreenAnimationDuration: TimeInterval {
        return 0.15
    }
    
    func minimizeToFrame(_ frame: CGRect) {
        UIView.animate(withDuration: fullScreenAnimationDuration) {
            self.setAffineTransform(.identity)
            self.frame = frame
        }
    }
    
    func goFullscreen() {
        UIView.animate(withDuration: fullScreenAnimationDuration) {
            self.setAffineTransform(.ninetyDegreeRotation)
            self.frame = UIScreen.main.bounds
        }
    }
}

