//
//  Server.swift
//  BUUP
//
//  Created by Dai Pham on 11/7/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import Alamofire
import FacebookLogin
import FBSDKLoginKit


typealias JSON = Dictionary<String, Any>

enum Result<T, U> where U: Error {
    case success(T)
    case failure(U?)
}

enum EmptyResult<U> where U: Error {
    case success
    case failure(U?)
}


final class Server: NSObject {
    
    
    /// Enum store code errors from api
    ///
    /// - unAuthorized: api token wrong or invalid
    /// - notFound: api not found
    /// - cantParseData: data return wrong format
    /// - emailUsed: email register has exist
    /// - invalid: something happen wrong with server
    /// - missingField: missing params
    /// - unkownUser: user not exist
    /// - invalidService: Service maintaince
    enum GetDataFailureReason: Int, Error {
        case unAuthorized = 401
        case notFound = 404
        case cantParseData = 501
        case paramUsed = 503 // email has used
        case invalid = 0
        case missingField = 1002 // missing params
        case unkownData = 1001  // user not exist
        case invalidService = 1003
        
    }
    
    typealias GetListResult = Result<[JSON], GetDataFailureReason>
    typealias GetListCompletion = (_ result: GetListResult) -> Void
    
    typealias GetSingleResult = Result<JSON, GetDataFailureReason>
    typealias GetSingleCompletion = (_ result: GetSingleResult) -> Void
    
    static let shared = Server()
    
    private override init() {
        super.init()
    }
    
    // MARK: - private
    // refactor
    
    /// handle response data from api
    ///
    /// - Parameters:
    ///   - response: response received from alamofire
    ///   - completion: return Any?, GetDataFailureReason?, orderParams will stored in this third param
    fileprivate func handleResponseData(response:DataResponse<String>,_ completion:((Any?,GetDataFailureReason?,Any?)->Void)? = nil) {
        switch response.result {
        case .success:
            
            guard let jsonArray = response.result.value?.convertToJSON() else {
                if let reason = GetDataFailureReason(rawValue: 404) {
                    completion?(nil,reason,nil)
                }
                return
            }
            
            var error:Int = 0
            if let err = jsonArray["status"] as? Int {
                error = err
            } else if let err = jsonArray["status"] as? String {
                error = Int(err)!
            }
            
            var otherParams:JSON = [:]
            for key in jsonArray.keys {
                if key != "data" && key != "status" {
                    otherParams[key] = jsonArray[key]
                }
            }
            
            if error == 200 {
                completion?(jsonArray["data"],nil,otherParams)
            } else if error == 401 {
                self.apiTokenExpired()
                return
            } else {
                if let reason = GetDataFailureReason(rawValue: error) {
                    completion?(nil,reason,otherParams)
                }
            }
            
            
        case .failure(_):
            if let reason = GetDataFailureReason(rawValue: 404) {
                completion?(nil,reason,nil)
            }
        }
    }
    
    fileprivate func getMessage(error:GetDataFailureReason) -> String{
        var msg = "service_unavailable".localized().capitalizingFirstLetter()
        switch error  {
        case .unAuthorized:
            msg = "api_token_expired".localized().capitalizingFirstLetter()
        case .notFound:
            msg = "service_unavailable".localized().capitalizingFirstLetter()
        case .cantParseData:
            msg = "wrong_params_cant_send_to_server".localized().capitalizingFirstLetter()
        case .paramUsed:
            msg = "information_that_you_already_exists".localized().capitalizingFirstLetter()
        case .invalid:
            msg = "information_that_you_invalid".localized().capitalizingFirstLetter()
        case .missingField:
            msg = "information_that_you_invalid".localized().capitalizingFirstLetter()
        case .unkownData:
            msg = "information_that_you_invalid".localized().capitalizingFirstLetter()
        case .invalidService:
            msg = "service_unavailable".localized().capitalizingFirstLetter()
        }
        return msg
    }
    
    fileprivate func handleSingleData(response:DataResponse<String>,_ completion:GetSingleCompletion? = nil) {
        switch response.result {
        case .success:
            
            guard let jsonArray = response.result.value?.convertToJSON() else {
                if let reason = GetDataFailureReason(rawValue: 404) {
                    completion?(.failure(reason))
                }
                return
            }
            
            var error = 0;
            if let err = jsonArray["status"] as? Int {
                error = err
            } else if let err = jsonArray["status"] as? String {
                error = Int(err)!
            }
            
            if error == 0 {
                if let msg =  jsonArray["email"] as? [String] {
                    if let msg = msg.first {
                        if msg.contains("email has already been taken") {
                            if let reason = GetDataFailureReason(rawValue: 503) {
                                completion?(.failure(reason))
                                return
                            }
                        }
                    }
                }
            }
            
            if error == 200 {
                completion?(.success(jsonArray))
            } else if error == 401 {
                self.apiTokenExpired()
                return
            } else {
                if let reason = GetDataFailureReason(rawValue: 404) {
                    completion?(.failure(reason))
                }
            }
            
            
        case .failure(_):
            if let reason = GetDataFailureReason(rawValue: 404) {
                completion?(.failure(reason))
            }
        }
    }
    
    fileprivate func handleListData(response:DataResponse<String>,_ completion:GetListCompletion? = nil) {
        switch response.result {
        case .success:
            
            guard let jsonArray = response.result.value?.convertToJSON() else {
                if let reason = GetDataFailureReason(rawValue: 404) {
                    completion?(.failure(reason))
                }
                return
            }
            
            var error = 0;
            if let err = jsonArray["status"] as? Int {
                error = err
            } else if let err = jsonArray["status"] as? String {
                error = Int(err)!
            }
            
            if error == 200 {
                if let data = jsonArray["data"] as? [JSON] {
                    completion?(.success(data))
                } else if let data = jsonArray["data"] as? JSON {
                    completion?(.success([data]))
                }
            } else if error == 401 {
                self.apiTokenExpired()
                return
            } else {
                if let reason = GetDataFailureReason(rawValue: 404) {
                    completion?(.failure(reason))
                }
            }
            
        case .failure(_):
            if let reason = GetDataFailureReason(rawValue: 404) {
                completion?(.failure(reason))
            }
        }
    }
    
    // MARK: - APITOKEN EXPIRED
    func apiTokenExpired() {
        AppConfig.navigation.logOut()
        
        let alert = UIAlertController(title: "Error!",
                                      message: "api_token_expired".localized(),
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: "OK",
                                         style: .cancel, handler: { _ in
                                            Server.shared.loginGuest { [weak self] err in
                                                guard let _self = self else {return}
                                                if let err = err {
                                                    var msg = ""
                                                    switch err {
                                                    case .unkownData:
                                                        msg = "user_not_exist".localized().capitalizingFirstLetter()
                                                    case .invalidService:
                                                        msg = "service_unavailable".localized()
                                                    default:
                                                        msg = "Unkown error!"
                                                    }
                                                    Support.notice(title:"notice".localized().capitalizingFirstLetter(),message: msg,vc: Support.topVC!, ["ok".localized().uppercased()], nil)
                                                } else {
                                                    DispatchQueue.main.async {
                                                        let vc = LaunchController(nibName: "LaunchController", bundle: Bundle.main)
                                                        AppConfig.navigation.changeRootControllerTo(viewcontroller: vc)
                                                    }
                                                }
                                            }
        })
        
        alert.addAction(cancelAction)
        Support.topVC!.present(alert, animated: true, completion: nil)
        
    }
}
// MARK: - AUTHENTIC
extension Server {
    
    func loginGuest(_ completion:@escaping ((GetDataFailureReason?)->Void)) {
        
        let headers =  ["Accept":"application/json"]
        
        Alamofire.request(api_login_guest, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                switch response.result {
                case .success:
                    
                    guard let jsonArray = response.result.value?.convertToJSON() else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion(reason)
                        }
                        return
                    }
                    
                    var error = 0;
                    if let err = jsonArray["status"] as? Int {
                        error = err
                    } else if let err = jsonArray["status"] as? String {
                        error = Int(err)!
                    }
                    
                    if error == 200 {
                        if let data = jsonArray["data"] as? JSON {
                            AccountManager.saveUserWith(dictionary: data, CoreDataStack.sharedInstance.persistentContainer.viewContext, true) { isSuccess in
                                print("SAVE USER \(isSuccess)")
                                completion(nil)
                            }
                        }

                    } else if error == 401 {
                        self.apiTokenExpired()
                        return
                    } else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion(reason)
                        }
                    }
                    
                case .failure(_):
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion(reason)
                    }
                }
        }
    }
    
    func loginFB(_ vc:UIViewController? = nil,
                 _ onComplete: @escaping GetSingleCompletion) {
        let loginManager = LoginManager()
        loginManager.logOut()
        FBSDKAccessToken.setCurrent(nil)
        FBSDKProfile.setCurrent(nil)
        loginManager.defaultAudience = .everyone
        loginManager.logIn(readPermissions: [.publicProfile,.email,.userBirthday], viewController: vc) { (loginResult) in
            switch loginResult {
            case .failed(let error):
                DispatchQueue.main.async {
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        onComplete(.failure(reason))
                    }
                }
                print(error)
            case .cancelled:
                DispatchQueue.main.async {
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        onComplete(.failure(reason))
                    }
                }
                print("User cancelled login.")
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                // self.getFBUserData()
                print("User login success.\(accessToken) \(declinedPermissions) \(grantedPermissions)")
                let url = URL(string: api_login_fb)!
                
                var urlRequest = URLRequest(
                    url: url,
                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                    timeoutInterval: 10.0 * 1000)
                urlRequest.httpMethod = "POST"
                urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
                //                urlRequest.addValue("Bearer \(accessToken.authenticationToken)", forHTTPHeaderField: "Authorization")
                urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: ["accessToken":"\(accessToken.authenticationToken)"], options: JSONSerialization.WritingOptions.prettyPrinted)
                let task = URLSession.shared.dataTask(with: urlRequest)
                { (data, response, error) -> Void in
                    guard error == nil else {
                        print("FETCH DATA LOGIN FAILED: \(String(describing: error))")
                        return
                    }
                    guard let dt = data else {
                        DispatchQueue.main.async {
                            if let reason = GetDataFailureReason(rawValue: 404) {
                                onComplete(.failure(reason))
                            }
                            
                        }
                        return
                    }
                    guard let json = try? JSONSerialization.jsonObject(with: dt) as? JSON else {
                        print("PARSE DATA LOGIN FAILED")
                        DispatchQueue.main.async {
                            if let reason = GetDataFailureReason(rawValue: 404) {
                                onComplete(.failure(reason))
                            }
                        }
                        return
                    }
                    if let error = json!["status"] as? Int{
                        if error == 200 {
                            if let objectJson = json {
                                if let js = objectJson["data"] as? String {
                                    if let data = js.data(using: String.Encoding.utf8) {
                                        do {
                                            if let pro:JSON = try JSONSerialization.jsonObject(with: data, options: []) as? JSON {
                                                
                                                DispatchQueue.main.async {
                                                    onComplete(.success(pro))
                                                }
                                                return
                                            }
                                        } catch {
                                            DispatchQueue.main.async {
                                                if let reason = GetDataFailureReason(rawValue: 404) {
                                                    onComplete(.failure(reason))
                                                }
                                            }
                                        }
                                    }
                                }
                                if let js = objectJson["data"] as? JSON {
                                    DispatchQueue.main.async {
                                        onComplete(.success(js))
                                    }
                                    return
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            if let reason = GetDataFailureReason(rawValue: 404) {
                                onComplete(.failure(reason))
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            if let reason = GetDataFailureReason(rawValue: 404) {
                                onComplete(.failure(reason))
                            }
                        }
                    }
                }
                
                task.resume()
            }
        }
    }
    
    func login(email:String? = nil,
               password:String? = nil,
               _ onComplete: @escaping GetSingleCompletion) {
        
        guard let e = email, let p = password else {
            if let reason = GetDataFailureReason(rawValue: 404) {
                onComplete(.failure(reason))
            }
            return
        }
        
        let parameters = ["email":e,"password":p]
        
        Alamofire.request(api_login, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: ["Accept":"application/json","Content-Type":"application/x-www-form-urlencoded"])
            .responseString { response in
                switch response.result {
                case .success:
                    
                    guard let jsonArray = response.result.value?.convertToJSON() else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            onComplete(.failure(reason))
                        }
                        return
                    }
                    if let error = jsonArray["status"] as? Int{
                        if error == 200 {
                            let objectJson = jsonArray
                            if let js = objectJson["data"] as? String {
                                if let data = js.data(using: String.Encoding.utf8) {
                                    do {
                                        if let pro:JSON = try JSONSerialization.jsonObject(with: data, options: []) as? JSON {
                                            DispatchQueue.main.async {
                                                onComplete(.success(pro))
                                            }
                                            return
                                        }
                                    } catch {
                                        DispatchQueue.main.async {
                                            if let reason = GetDataFailureReason(rawValue: 404) {
                                                onComplete(.failure(reason))
                                            }
                                        }
                                    }
                                }
                            }
                            if let js = objectJson["data"] as? JSON {
                                DispatchQueue.main.async {
                                    onComplete(.success(js))
                                }
                                return
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            onComplete(.failure(reason))
                        }
                    }
                case .failure(_):
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        onComplete(.failure(reason))
                    }
                }
        }
    }
    
    func register(email:String,
                  password:String,
                  password_confirmation:String,
                  _ name:String? = nil,
                  _ completion:((JSON?,Any?)->Void)? = nil) {
        
        var parameters: Parameters = [:]
        
        parameters["email"] = email
        parameters["password"] = password
        parameters["password_confirmation"] = password_confirmation
        
        if let name = name {
            parameters["name"] = name
        }
        
        var request = URLRequest(url: try! api_register.asURL())
        
        //some header examples
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("httpBody request parse fail \(parameters)")
            if let reason = GetDataFailureReason(rawValue: 404) {
                completion?(nil, reason)
            }
        }
        
        Alamofire.request(request).responseString { response in
            self.handleSingleData(response: response, { result in
                switch response.result {
                case .success:
                    
                    guard let jsonArray = response.result.value?.convertToJSON() else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(nil, reason)
                        }
                        return
                    }
                    
                    var error = 0;
                    if let err = jsonArray["status"] as? Int {
                        error = err
                    } else if let err = jsonArray["status"] as? String {
                        error = Int(err)!
                    }
                    
                    if error == 0 {
                        if let msg =  jsonArray["email"] as? [String] {
                            if let msg = msg.first {
                                if msg.contains("email has already been taken") {
                                    completion?(nil,msg)
                                    return
                                }
                            }
                        }
                    }
                    
                    if let error = jsonArray["status"] as? Int{
                        if error == 200 {
                            if let json = jsonArray["data"] as? JSON {
                                completion?(json, nil)
                                return
                            }
                        }
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(nil, reason)
                        }
                    } else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(nil, reason)
                        }
                    }
                    
                case .failure(let reason):
                    if let reason = reason as? GetDataFailureReason {
                        if reason == .paramUsed {
                            completion?(nil, reason)
                            return
                        }
                    }
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(nil, reason)
                    }
                    
                    
                }
            })
        }
    }
    
    func forgotPassword(email:String,
                        _ completion:((JSON?,GetDataFailureReason?)->Void)? = nil) {
        
        var parameters: Parameters = [:]
        
        parameters["email"] = email

        var request = URLRequest(url: try! api_forgot_password.asURL())
        
        //some header examples
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("httpBody request parse fail \(parameters)")
            if let reason = GetDataFailureReason(rawValue: 404) {
                completion?(nil, reason)
            }
        }
        
        Alamofire.request(request).responseString { response in
            self.handleSingleData(response: response, { result in
                switch response.result {
                case .success:
                    
                    guard let jsonArray = response.result.value?.convertToJSON() else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(nil, reason)
                        }
                        return
                    }
                    
                    var error = 0;
                    if let err = jsonArray["status"] as? Int {
                        error = err
                    } else if let err = jsonArray["status"] as? String {
                        error = Int(err)!
                    }
                    
                    
                    if error == 200 {
                        completion?(jsonArray, nil)
                        return
                    }
                    if let reason = GetDataFailureReason(rawValue: error) {
                        completion?(nil, reason)
                    }
                    
                case .failure(_):
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(nil, reason)
                    }
                }
            })
        }
    }
    
    func change_password(current_password:String,
                         new_password:String,
                         _ completion:((Any?)->Void)? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(reason)
            }
            return
        }
        
        var parameters: Parameters = [:]
        
        parameters["current_password"] = current_password
        parameters["new_password"] = new_password
        
        var request = URLRequest(url: try! api_change_password.asURL())
        
        //some header examples
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(user.api_token)",
            forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("httpBody request parse fail \(parameters)")
            if let reason = GetDataFailureReason(rawValue: 404) {
                completion?(reason)
            }
        }
        
        Alamofire.request(request).responseString { response in
            self.handleSingleData(response: response, { result in
                switch response.result {
                case .success:
                    guard let jsonArray = response.result.value?.convertToJSON() else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(reason)
                        }
                        return
                    }
                    if let error = jsonArray["status"] as? Int{
                        if error == 200 {
                            completion?(nil)
                            return
                        }
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(reason)
                        }
                    } else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(reason)
                        }
                    }
                    
                case .failure(_):
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(reason)
                    }
                }
            })
        }
    }
    
    func logout(_ completion: GetSingleCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        Alamofire.request(api_logout, method: .post, parameters: nil, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                switch response.result {
                case .success:
                    
                    guard let jsonArray = response.result.value?.convertToJSON() else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(.failure(reason))
                        }
                        return
                    }
                    if let error = jsonArray["status"] as? Int{
                        if error == 200 {
                            if let data = jsonArray["data"] as? JSON {
                                completion?(.success(data))
                            } else {
                                if let reason = GetDataFailureReason(rawValue: 404) {
                                    completion?(.failure(reason))
                                }
                            }
                        } else if error == 401 {
                            self.apiTokenExpired()
                            return
                        } else {
                            if let reason = GetDataFailureReason(rawValue: 404) {
                                completion?(.failure(reason))
                            }
                        }
                    } else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(.failure(reason))
                        }
                    }
                    
                case .failure(_):
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(.failure(reason))
                    }
                }
        }
    }
}

// MARK: - GET CONFIG
extension Server {
    func getConfig(_ completion: GetSingleCompletion? = nil) {
    
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        
        print("RUN API GET CONFIG")
        
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        Alamofire.request(api_get_config, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                switch response.result {
                case .success:
                    
                    guard let jsonArray = response.result.value?.convertToJSON() else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(.failure(reason))
                        }
                        return
                    }
                    if let error = jsonArray["status"] as? Int{
                        if error == 200 {
                            ConfigManager.saveUserWith(dictionary: jsonArray, CoreDataStack.sharedInstance.persistentContainer.viewContext)
                            completion?(.success(jsonArray))
                        } else if error == 401 {
                            self.apiTokenExpired()
                            return
                        } else {
                            if let reason = GetDataFailureReason(rawValue: 404) {
                                completion?(.failure(reason))
                            }
                        }
                    } else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(.failure(reason))
                        }
                    }
                    
                case .failure(_):
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(.failure(reason))
                    }
                }
        }
    }
    
    func getConfigStatus(_ completion: ((JSON?,Any?)->Void)? = nil) {
        print("RUN API GET CONFIG STATUS")
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(nil,reason)
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        Alamofire.request(api_allstatus, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                switch response.result {
                case .success:
                    guard let jsonArray = response.result.value?.convertToJSON() else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(nil,reason)
                        }
                        return
                    }
                    
                    completion?(jsonArray,nil)
                    
                case .failure(_):
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(nil,reason)
                    }
                }
        }
    }
}

// MARK: - CATEGORIES
extension Server {
    // get all categories
    func getCategories(_ user_id:String? = nil,
                       loadCache:Bool = false,
                       _ completion: GetListCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        if loadCache {
            if let cache = AppConfig.cached.getCacheCategories {
                if cache.count > 0 {
                    completion?(.success(cache))
                    return
                }
            }
        }
        
        var parameters: Parameters?
        
        if let id = user_id {
            parameters = ["userId":id]
        }
        
        Alamofire.request(api_categories, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleListData(response: response, completion)
        }
    }
    
    // post categories
    func markFavoriteCategories(_ categoryIds:[String]? = nil,
                                _ user_id:String? = nil,
                                _ completion: GetSingleCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        guard let ids = categoryIds, let id = user_id else {
            if let reason = GetDataFailureReason(rawValue: 404) {
                completion?(.failure(reason))
            }
            return
        }
        
        var parameters: Parameters = ["userId":id]
        parameters["catIds"] = ids
        
        Alamofire.request(api_categories, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleSingleData(response: response, completion)
        }
    }
}

// MARK: - STREAMS
extension Server {
    // get all streams
    func getStreams(user_id:[String]? = nil,
                    category_ids:[String]? = nil,
                    isFeatured:Bool? = nil,
                    page:Int? = nil,
                    pageSize:Int? = nil,
                    sortBy:String? = nil,
                    _ completion: GetListCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters: Parameters = [:]
        
        if let userStringID = user_id {
            var userIds = ""
            _ = userStringID.map({
                if userIds.characters.count == 0 {
                    userIds.append("\($0)")
                } else {
                    userIds.append("&userId[]=\($0)")
                }
            })
            parameters["userId[]"] = userIds
        }
        
        if let userStringID = category_ids {
            var queryCatIds = ""
            _ = userStringID.map({
                if queryCatIds.characters.count == 0 {
                    queryCatIds.append("\($0)")
                } else {
                    queryCatIds.append("&catIds[]=\($0)")
                }
            })
            parameters["catIds[]"] = queryCatIds
        }
        
        if let id = isFeatured {
            parameters["isFeatured"] = Int(NSNumber(value:id))
        }
        
        if let id = page {
            parameters["page"] = id
        }
        
        if let id = pageSize {
            parameters["pageSize"] = id
        }
        
        if let id = sortBy {
            parameters["sortBy"] = id
        }
        
        var strParamerters = ""
        for (k,v) in parameters {
            if strParamerters.characters.count == 0 {
                strParamerters.append("?\(k)=\(v)")
            } else {
                strParamerters.append("&\(k)=\(v)")
            }
        }
        let query = api_streams.appending(strParamerters)
        print(query)
        Alamofire.request(query, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleListData(response: response, completion)
        }
    }
    
    func getStream(streamId:String,
                   userId:String? = nil,
                   _ completion:((Stream?,Any?)->Void)? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(nil,reason)
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters:Parameters = [:]
        if let id = userId {
            parameters["userId"] = id
        }
        
        Alamofire.request("\(api_streams)/\(streamId)", method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleSingleData(response: response, { result in
                    switch result  {
                    case .success(let data):
                        if let _ = data["status"] {
                            if let js = data["data"] as? JSON {
                                completion?(Stream.parse(from: js),nil)
                            }
                        } else {
                            completion?(Stream.parse(from: data),nil)
                        }
                    case .failure(let error):
                        completion?(nil,error)
                        break
                    }
                })
        }
    }
    
    func getStreamsSuggestion(user_id:String? = nil,
                              category_ids:[String]? = nil,
                              page:Int? = nil,
                              pageSize:Int? = nil,
                              sortBy:String? = nil,
                              _ completion: GetListCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters: Parameters = [:]
        
        if let id = user_id {
            parameters["userId"] = id
        }
        
        if let cates = category_ids {
            var queryCatIds = ""
            _ = cates.map({
                if queryCatIds.characters.count == 0 {
                    queryCatIds.append("\($0)")
                } else {
                    queryCatIds.append("&catIds[]=\($0)")
                }
            })
            parameters["catIds[]"] = queryCatIds
        }
        
        if let id = page {
            parameters["page"] = id
        }
        
        if let id = pageSize {
            parameters["pageSize"] = id
        }
        
        if let id = sortBy {
            parameters["sortBy"] = id
        }
        
        var strParamerters = ""
        for (k,v) in parameters {
            if strParamerters.characters.count == 0 {
                strParamerters.append("?\(k)=\(v)")
            } else {
                strParamerters.append("&\(k)=\(v)")
            }
        }
        let query = api_stream_suggestions.appending(strParamerters)
        print(query)
        Alamofire.request(query, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleListData(response: response, completion)
        }
    }
    
    // create stream
    typealias CreateStreamResult = Result<Stream, GetDataFailureReason>
    typealias CreateStreamCompletion = (_ result: CreateStreamResult) -> Void
    func createStream(user_id:String? = nil,
                      category_ids:[String]? = nil,
                      product_ids:[String]? = nil,
                      name:String? = nil,
                      thumb:String? = nil,
                      type:String? = "public",
                      _ completion: CreateStreamCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        
        var parameters: Parameters = [:]
        
        if let id = user_id {
            parameters["userId"] = id
        }
        
        if let id = category_ids {
            parameters["catIds"] = id
        }
        
        if let id = product_ids {
            parameters["productIds"] = id
        }
        
        if let id = name {
            parameters["name"] = id
        }
        if let id = thumb {
            parameters["thumbnailUrl"] = id
        }
        
        parameters["type"] = "public"
        if let type = type {
            parameters["type"] = type
        }
        
        var request = URLRequest(url: try! api_streams.asURL())
        
        //some header examples
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(user.api_token)",
            forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
        
        Alamofire.request(request).responseString { response in
            switch response.result {
            case .success:
                
                guard let jsonArray = response.result.value?.convertToJSON() else {
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(.failure(reason))
                    }
                    return
                }
                if let error = jsonArray["status"] as? Int{
                    if error == 200 {
                        if let data = jsonArray["stream"] as? JSON {
                            completion?(.success(Stream.parse(from: data)))
                        } else {
                            if let reason = GetDataFailureReason(rawValue: 404) {
                                completion?(.failure(reason))
                            }
                        }
                    } else if error == 401 {
                        self.apiTokenExpired()
                        return
                    } else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(.failure(reason))
                        }
                    }
                } else {
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(.failure(reason))
                    }
                }
                
            case .failure(_):
                if let reason = GetDataFailureReason(rawValue: 404) {
                    completion?(.failure(reason))
                }
            }
        }
    }
    
    // view Stream
    func viewStream(user_id:String? = nil,
                    stream_id:String? = nil,
                    _ completion: GetSingleCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters: Parameters = [:]
        
        if let id = user_id {
            parameters["userId"] = id
        }
        
        if let id = stream_id {
            parameters["streamId"] = id
        }
        
        Alamofire.request(api_view, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleSingleData(response: response, completion)
        }
    }
    
    // Find stream
    func findStream(code:String,
                    type:String? = "public",
                    _ completion: ((Stream?,String?)->Void)? = nil) {
        
        guard let user = Account.current else {
            completion?(nil,"service_unavailable".localized().capitalizingFirstLetter())
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters: Parameters = [:]
        
        parameters["codeType"] = "public"
        if let id = type {
            parameters["codeType"] = id
        }
        
        parameters["code"] = code
        
        Alamofire.request(api_find_streams, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleResponseData(response: response, { (data, error, orther) in
                    if let data = data as? JSON{
                        completion?(Stream.parse(from: data),nil)
                        return
                    } else {
                        completion?(nil,"code_invalid".localized().capitalizingFirstLetter())
                    }
                })
        }
    }
    
    // like | unlike stream
    func likeStream(user_id:String? = nil,
                    stream_id:String? = nil,
                    isLike:Bool? = true,
                    _ completion: GetSingleCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters:Parameters = [:]
        
        var method:HTTPMethod = .post
        
        if let like = isLike {
            if !like {
                method = .delete
            }
        }
        
        if let id = user_id {
            parameters ["userId"] = id
        }
        
        if let id = stream_id {
            parameters["streamId"] = id
        }
        
        Alamofire.request(api_like, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleSingleData(response: response, completion)
        }
    }
    // share stream link to facebook
    func shareFBStream(stream_id:String? = nil,accessToken:String? = nil, _ completion: GetSingleCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters:Parameters = [:]
        
        let method:HTTPMethod = .post
        
        if let id = accessToken {
            parameters ["accessToken"] = id
        }
        
        if let id = stream_id {
            parameters["streamId"] = id
        }
        
        Alamofire.request(api_share_fb, method: method, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleSingleData(response: response, completion)
        }
    }
}

// MARK: - upload Thumb Stream
extension Server {
    func uploadThumbStream(imageData:Data,_ completion: GetSingleCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(imageData, withName: "thumbImage", fileName: "thumbImage.jpg", mimeType: "image/jpeg")
        }, to:api_upload_thumbnail_stream, headers:["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"])
        { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (Progress) in
                    print("Upload Progress: \(Progress.fractionCompleted)")
                })
                
                upload.responseString { response in
                    self.handleSingleData(response: response, completion)
                }
                
            case .failure(let encodingError):
                //self.delegate?.showFailAlert()
                print(encodingError)
            }
            
        }
    }
}

// MARK: - update profile
extension Server {
    func updateUserProfile(coverData: Data?, avatarData: Data?, profile: [String: Any],_ completion: GetSingleCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            // cover image
            if coverData != nil {
                multipartFormData.append(coverData!, withName: "coverImage", fileName: "coverImage.jpg", mimeType: "image/jpeg")
            }
            // avatar image
            if avatarData != nil {
                multipartFormData.append(avatarData!, withName: "avatar", fileName: "avatar.jpg", mimeType: "image/jpeg")
            }
            
            // profile
            for (key, value) in profile {
                multipartFormData.append(String(describing: value).data(using: .utf8)!, withName: key)
            }
            
        }, to:api_user_profile + "\(user.id)", headers:["Authorization": "Bearer \(user.api_token)", "Accept": "application/json"])
        { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (Progress) in
                    print("Upload Progress: \(Progress.fractionCompleted)")
                })
                
                upload.responseString { response in
                    switch response.result {
                    case .success:
                        completion?(.success(JSON()))
                        
                    case .failure(_):
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(.failure(reason))
                        }
                    }
                }
                
            case .failure(let encodingError):
                //self.delegate?.showFailAlert()
                print(encodingError)
            }
        }
    }
    
    
    func getCurrentUserProfile(_ completion: GetSingleCompletion? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(.failure(reason))
            }
            return
        }
        
        let headers =  ["Authorization": "Bearer \(user.api_token)", "Accept": "application/json"]
        
        Alamofire.request(api_user_profile + "\(user.id)", method: .get, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleSingleData(response: response, completion)
        }
    }
}

// MARK: - API Products
extension Server {
    func getProducts(userId:String? = nil, streamId:String? = nil,_ completion:(([Product]?,Any?)->Void)? = nil) {
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(nil,reason)
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters: Parameters = [:]
        
        if let id = userId {
            parameters["userId"] = id
        }
        
        if let id = streamId {
            parameters["streamId"] = id
        }
        
        Alamofire.request(api_product, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleListData(response: response, { result in
                    switch result  {
                    case .success(let data):
                        completion?(data.flatMap{Product.parse(from: $0)},nil)
                    case .failure(let error):
                        completion?(nil,error)
                        break
                    }
                })
        }
    }
    
    func createProducts(userId:String? = nil, streamId:String? = nil, products:[JSON]? = nil,_ completion:(([Product]?,Any?)->Void)? = nil) {
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(nil,reason)
            }
            return
        }
        
        var parameters: Parameters = [:]
        
        if let id = userId {
            parameters["userId"] = id
        }
        
        if let id = streamId {
            parameters["streamId"] = id
        }
        
        if let id = products {
            parameters["products"] = id
        }
        
        var request = URLRequest(url: try! api_product.asURL())
        
        //some header examples
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(user.api_token)",
            forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
        
        Alamofire.request(request).responseString { response in
            self.handleListData(response: response, { result in
                switch response.result {
                case .success:
                    
                    guard let jsonArray = response.result.value?.convertToJSON() else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(nil, reason)
                        }
                        return
                    }
                    if let error = jsonArray["status"] as? Int{
                        if error == 200 {
                            if let data = jsonArray["data"] as? [JSON] {
                                completion?(data.flatMap{Product.parse(from: $0)}, nil)
                            } else {
                                if let reason = GetDataFailureReason(rawValue: 404) {
                                    completion?(nil, reason)
                                }
                            }
                        } else if error == 401 {
                            self.apiTokenExpired()
                            return
                        } else {
                            if let reason = GetDataFailureReason(rawValue: 404) {
                                completion?(nil, reason)
                            }
                        }
                    } else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(nil, reason)
                        }
                    }
                    
                case .failure(_):
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(nil, reason)
                    }
                }
            })
        }
    }
    
    func deleteProducts(productIds: [String]? = nil, completion:((Any?) -> Void)? = nil) {
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(reason)
            }
            
            return
        }
        
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters: Parameters = [:]
        
        if let ids = productIds {
            parameters["productIds"] = ids
        }
        
        Alamofire.request(api_product, method: .delete, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                switch response.result {
                case .success:
                    completion?(nil)
                    
                case .failure(_):
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(reason)
                    }
                }
        }
    }
}

// MARK: - API Orders
extension Server {
    func getOrders(streamId:String? = nil,
                   buyerId:String? = nil,
                   sellerId:String? = nil,
                   status:Int? = nil,
                   sortField:[JSON]? = [["created_at":"ASC"]],
                   fromDate:String,
                   toDate:String,
                   page:Int,
                   pageSize:Int? = 20,
                   _ completion:(([Order]?,Any?)->Void)? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(nil,reason)
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters: Parameters = [:]
        
        if let id = buyerId {
            parameters["buyerId"] = id
        }
        
        if let id = streamId {
            parameters["streamId"] = id
        }
        
        if let id = status {
            parameters["status"] = id
        }
        
        if let id = sellerId {
            parameters["sellerId"] = id
        }
        
        parameters["status"] = status
        parameters["fromDate"] = fromDate
        parameters["toDate"] = toDate
        parameters["page"] = page
        if let pSize = pageSize {
            parameters["pageSize"] = pSize
        }
        
        if let sort = sortField {
            for param in sort {
                if let key = param.keys.first, let value = param.values.first as? String {
                    parameters["sortField[\(key)]"] = value
                }
            }
        }
        
        Alamofire.request(api_orders, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleListData(response: response, { result in
                    switch result  {
                    case .success(let data):
                        completion?(data.flatMap{Order.parse(from: $0)},nil)
                    case .failure(let error):
                        completion?(nil,error)
                        break
                    }
                })
        }
    }
    
    func getOrder(orderId:String,
                  _ completion:((Order?,Any?)->Void)? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(nil,reason)
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        Alamofire.request("\(api_orders)/\(orderId)", method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleSingleData(response: response, { result in
                    switch result  {
                    case .success(let data):
                        if let _ = data["status"] {
                            if let js = data["data"] as? JSON {
                                completion?(Order.parse(from: js),nil)
                            }
                        } else {
                            completion?(Order.parse(from: data),nil)
                        }
                    case .failure(let error):
                        completion?(nil,error)
                        break
                    }
                })
        }
    }
    
    func createOrder(id:String? = nil,
                     streamId:String,
                     buyerId:String,
                     sellerId:String,
                     totalPrice:CGFloat,
                     products:[JSON],
                     userShipping:JSON,
                     _ completion:((JSON?,Any?)->Void)? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(nil,reason)
            }
            return
        }
        
        var parameters: Parameters = [:]
        
        if let id = id {
            parameters["id"] = id
        }
        
        parameters["streamId"] = streamId
        parameters["buyerId"] = buyerId
        parameters["sellerId"] = sellerId
        parameters["totalPrice"] = totalPrice
        parameters["products"] = products
        parameters["userShipping"] = userShipping
        parameters["status"] = AppConfig.status.order.create_new() // create new
        
        var request = URLRequest(url: try! api_orders.asURL())
        
        //some header examples
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(user.api_token)",
            forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("httpBody request parse fail \(parameters)")
            if let reason = GetDataFailureReason(rawValue: 404) {
                completion?(nil, reason)
            }
        }
        
        Alamofire.request(request).responseString { response in
            self.handleSingleData(response: response, { result in
                switch response.result {
                case .success:
                    
                    guard let jsonArray = response.result.value?.convertToJSON() else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(nil, reason)
                        }
                        return
                    }
                    if let error = jsonArray["status"] as? Int{
                        if error == 200 {
                            completion?(jsonArray, nil)
                        } else if error == 401 {
                            self.apiTokenExpired()
                            return
                        } else {
                            if let reason = GetDataFailureReason(rawValue: 404) {
                                completion?(nil, reason)
                            }
                        }
                    } else {
                        if let reason = GetDataFailureReason(rawValue: 404) {
                            completion?(nil, reason)
                        }
                    }
                    
                case .failure(_):
                    if let reason = GetDataFailureReason(rawValue: 404) {
                        completion?(nil, reason)
                    }
                }
            })
        }
    }
    
    func changeStatusOrder(orderIds:[String],
                           status:String,
                           _ completion:((Order?,Any?)->Void)? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(nil,reason)
            }
            return
        }
        
        var parameters: Parameters = [:]
        
        parameters["orderIds"] = orderIds
        parameters["status"] = status
        
        var request = URLRequest(url: try! api_change_status_orders.asURL())
        
        //some header examples
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(user.api_token)",
            forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("httpBody request parse fail \(parameters)")
            if let reason = GetDataFailureReason(rawValue: 404) {
                completion?(nil, reason)
            }
        }
        
        Alamofire.request(request).responseString { response in
            self.handleSingleData(response: response, {result in
                switch result  {
                case .success(_):
                    if orderIds.count > 1 {
                        completion?(nil,nil)
                    } else if orderIds.count == 1 {
                        self.getOrder(orderId: orderIds.first!, completion)
                    }
                case .failure(let error):
                    completion?(nil,error)
                    break
                }
            })
        }
    }
}

// MARK: - API USER SHIPPING
extension Server {
    func getShippings(from userId:String,
                      _ completion:(([UserShipping]?,Any?)->Void)? = nil) {
        
        guard let user = Account.current else {
            if let reason = GetDataFailureReason(rawValue: 400) {
                completion?(nil,reason)
            }
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters: Parameters = [:]
        
        parameters["userId"] = userId
        
        Alamofire.request(api_usershipping, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleListData(response: response, { result in
                    switch result  {
                    case .success(let data):
                        completion?(data.flatMap{UserShipping.parse(from: $0)},nil)
                    case .failure(let error):
                        completion?(nil,error)
                        break
                    }
                })
        }
    }
}

// MARK: - Follows
extension Server {
    
    /// api mark current user follow another user
    ///
    /// - Parameters:
    ///   - followerId: another user id
    ///   - followingId: current user id
    ///   - unFollow: false is follow else unfollow
    ///   - completion: return bool valuw and message error
    func actionFollow(followerId:String,
                           followingId:String,
                           unFollow:Bool? = false,
                           _ completion:((Bool?,String?)->Void)? = nil) {
        
        guard let user = Account.current else {
            completion?(nil,"service_unavailable".localized().capitalizingFirstLetter())
            return
        }
        
        var parameters: Parameters = [:]
        
        parameters["followerId"] = followerId
        parameters["followingId"] = followingId
        
        var request = URLRequest(url: try! api_follows.asURL())
        
        //some header examples
        
        request.httpMethod = "POST"
        
        if let isF = unFollow {
            request.httpMethod = !isF ? "POST" : "DELETE"
        }
        
        request.setValue("Bearer \(user.api_token)",
            forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("httpBody request parse fail \(parameters)")
            completion?(nil, "wrong_params_cant_send_to_server".localized().capitalizingFirstLetter())
        }
        
        Alamofire.request(request).responseString { response in
            self.handleResponseData(response: response, {result,error, otherParams in
                if let error = error {
                    completion?(nil,self.getMessage(error: error))
                } else {
                    completion?(true,nil)
                }
            })
        }
    }
    
    func getListFollows(userIds:[String],
                      isFollowing:Bool = true,
                      page:Int,
                      _ completion:(([User]?,String?,Bool?)->Void)? = nil) {
        
        guard let user = Account.current else {
            completion?(nil,"service_unavailable".localized().capitalizingFirstLetter(),false)
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters: Parameters = [:]
        
        var queryUserIds = ""
            _ = userIds.map({
                if queryUserIds.characters.count == 0 {
                    queryUserIds.append("\($0)")
                } else {
                    queryUserIds.append("&userId[]=\($0)")
                }
            })
        parameters["userId[]"] = queryUserIds
        
        parameters["followType"] = isFollowing ? "following" : "follower"
        
        Alamofire.request(api_follows, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleResponseData(response: response, {result,error,otherParams in
                    if let error = error {
                        completion?(nil,self.getMessage(error: error),nil)
                    } else {
                        if let data = result as? [JSON] {
                            
                            var morePage = false
                            if let params = otherParams as? JSON, let more = params["hasMorePages"] as? Bool {
                                morePage = more
                            }
                            completion?(data.flatMap{
                                if let jsUser = (isFollowing ? $0["user_follower"] : $0["user_following"]) as? JSON {
                                    return User.parse(from: jsUser)
                                } else {
                                    return nil
                                }
                            },nil,morePage)
                        } else {
                            completion?(nil,nil,nil)
                        }
                    }
                })
        }
    }
    
    func checkFollow(followerId:String,
                        followingId:String,
                        _ completion:((Bool?,String?)->Void)? = nil) {
        
        guard let user = Account.current else {
            completion?(nil,"service_unavailable".localized().capitalizingFirstLetter())
            return
        }
        let headers =  ["Authorization":"Bearer \(user.api_token)", "Accept":"application/json"]
        
        var parameters: Parameters = [:]
        
        parameters["followerId"] = followerId
        parameters["followingId"] = followingId
        
        Alamofire.request(api_check_follows, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                self.handleResponseData(response: response, {result,error,otherParams in
                    if let error = error {
                        completion?(nil,self.getMessage(error: error))
                    } else {
                        if let data = result as? Bool {
                            completion?(data,nil)
                        } else {
                            completion?(nil,nil)
                        }
                    }
                })
        }
    }
}

// MARK: - report
extension Server {
    func report(streamId:String,
                      userId:String,
                      content:String,
                      _ completion:((String?)->Void)? = nil) {
        
        guard let user = Account.current else {
            completion?("service_unavailable".localized().capitalizingFirstLetter())
            return
        }
        
        var parameters: Parameters = [:]
        
        parameters["streamId"] = streamId
        parameters["userId"] = userId
        parameters["note"] = content
        
        var request = URLRequest(url: try! api_report.asURL())
        
        //some header examples
        
        request.httpMethod = "POST"
        
        request.setValue("Bearer \(user.api_token)",
            forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("httpBody request parse fail \(parameters)")
            completion?("wrong_params_cant_send_to_server".localized().capitalizingFirstLetter())
        }
        
        Alamofire.request(request).responseString { response in
            self.handleResponseData(response: response, {result,error, otherParams in
                if let error = error {
                    completion?(self.getMessage(error: error))
                } else {
                    completion?(nil)
                }
            })
        }
    }
}
