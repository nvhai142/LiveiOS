//
//  Constant.swift
//  BUUP
//
//  Created by Dai Pham on 11/14/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import Foundation

///////////////////////////////////////////////////////

//// api s3corp
let domain = "http://santube.s3corp.vn:9999/api"
//// MARK: - Socket server
let socket_server = "http://santube.s3corp.vn:3000"


// api prod
//let domain = "http://api.santube.net/api"
// MARK: - Socket server
//let socket_server = "http://socket.santube.net:3000"

///////////////////////////////////////////////////////////////////////////
// MARK: - API
let api_login_fb = "\(domain)/fb_login"
let api_login = "\(domain)/login"
let api_login_guest = "\(domain)/get_token_guest"
let api_register = "\(domain)/register"
let api_change_password = "\(domain)/change_password"
let api_forgot_password = "\(domain)/forgot_password"
let api_logout = "\(domain)/logout"
let api_view = "\(api_streams)/view"
let api_find_streams = "\(domain)/find_streams"
let api_get_config = "\(domain)/stream_configuration"
let api_categories = "\(domain)/categories"
let api_streams = "\(domain)/streams"
let api_stream_suggestions = "\(domain)/streams_suggestion"
let api_like = "\(api_streams)/like"
let api_upload_thumbnail_stream = "\(domain)/uploadImage"
let api_user_profile = "\(domain)/users/"
let api_share_fb = "\(domain)/post_fb"
let api_product = "\(domain)/products"
let api_orders = "\(domain)/orders"
let api_change_status_orders = "\(api_orders)/changeStatus"
let api_allstatus = "\(domain)/allstatus"
let api_usershipping = "\(domain)/userShippings"
let api_follows = "\(domain)/follows"
let api_check_follows = "\(domain)/check_follows"
let api_report = "\(domain)/report"



// MARK: - STATUS STREAM
let SS_START = "10"
let SS_STOP = "20"
let SS_STREAMING = "30"
let SS_FAIL = "40"

// MARK: - STATUS ORDER
let SO_NEW = "10"
let SO_PROGRESS = "20"
let SO_REJECT = "30"
let SO_FINISH = "40"
let SO_DELETE = "50"

// MARK: - STATUS USER
let SU_ACTIVE = "10"
let SU_INACTIVE = "20"
let SU_BANNED = "50"

// MARK: - STATUS PRODUCT
let SP_NEW = "10"
let SP_DELETE = "50"

// MARK: - SHOWCASE
let LIST_SCENES = [HOME_SCENE,
                   VIEW_STREAM_SCENE,
                   CREATE_STREAM_SCENE]

// MARK: - scene tutorials
let HOME_SCENE = "App:Tutorial:FeaturedController"
let CREATE_STREAM_SCENE = "App:Tutorial:LiveStreamController"
let VIEW_STREAM_SCENE = "App:Tutorial:InformationStreamController"

// home controller
let TABBAR_BUTTON_LIVESTREAM = "1"
let CATEGORIES_BUTTON = "2"

// information controller
let ORDER_BUTTON_STREAM = "1"

// streamer view
let SELL_PRODUCTS_BUTTON = "1"
let THUMNAIL_STREAM_BUTTON = "2"
let MINI_GAME_BUTTON = "3"

// MARK: - IMAGE
let APP_LOGO:String = "ic_santube"
let APP_LOGO_PLACEHOLDER:String = "ic_santube_placeholder.png"

// MARK: - QUICKVIEW IDENTIFIER
let QUICK_VIEW_TAG:Int = 99999999

// MARK: - FONT
let font_scale:CGFloat = 0.8
var fontSize14:CGFloat{
    get {
        if UIScreen.main.bounds.size.width <= 320 {
            return 14 * font_scale
        }
        return 14
    }
}

var fontSize13:CGFloat{
    get {
        if UIScreen.main.bounds.size.width <= 320 {
            return 13 * font_scale
        }
        return 13
    }
}

var fontSize20:CGFloat{
    get {
        if UIScreen.main.bounds.size.width <= 320 {
            return 20 * font_scale
        }
        return 20
    }
}

var fontSize24:CGFloat{
    get {
        if UIScreen.main.bounds.size.width <= 320 {
            return 24 * font_scale
        }
        return 24
    }
}

var fontSize16:CGFloat{
    get {
        if UIScreen.main.bounds.size.width <= 320 {
            return 16 * font_scale
        }
        return 16
    }
}

var fontSize17:CGFloat{
    get {
        if UIScreen.main.bounds.size.width <= 320 {
            return 17 * font_scale
        }
        return 17
    }
}

var fontSize18:CGFloat{
    get {
        if UIScreen.main.bounds.size.width <= 320 {
            return 18 * font_scale
        }
        return 18
    }
}

var fontSize15:CGFloat{
    get {
        if UIScreen.main.bounds.size.width <= 320 {
            return 15 * font_scale
        }
        return 15
    }
}

var fontSize22:CGFloat{
    get {
        if UIScreen.main.bounds.size.width <= 320 {
            return 22 * font_scale
        }
        return 22
    }
}
