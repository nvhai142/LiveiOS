//
//  TabBarController.swift
//  BUUP
//
//  Created by Hai NguyenV on 10/31/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let outData = UserDefaults.standard.data(forKey: "UserProfile")
        let dict = NSKeyedUnarchiver.unarchiveObject(with: outData!) as! NSDictionary
        
        let button = UIButton.init(type: .custom)
        //set image for button
       // button.setImage(UIImage(named: "fb.png"), for: UIControlState.normal)
        //add function for button
        button.addTarget(self, action: #selector(TabBarController.fbButtonPressed) , for: UIControlEvents.touchUpInside)
        //set frame
        button.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
        button.layer.cornerRadius = 23
        button.layer.masksToBounds = true
        
        let imageURL = "https://graph.facebook.com/\( dict["id"] as! String)/picture?type=large&return_ssl_resources=1"
        //Download image from imageURL
        if let url = URL(string: imageURL) {
            getDataFromUrl(url: url) { data, response, error in
                guard let data = data, error == nil else { return }
                print(response?.suggestedFilename ?? url.lastPathComponent)
                DispatchQueue.main.async() {
                     button.setImage(UIImage(data: data), for: UIControlState.normal)
                }
            }
        }
        
        let barButton = UIBarButtonItem(customView: button)
        //assign button to navigationbar
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    
    func fbButtonPressed() {
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileController") as? ProfileController {
            if let navigator = navigationController {
                navigator.pushViewController(viewController, animated: true)
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
