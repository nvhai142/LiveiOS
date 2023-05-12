//
//  Sockets.swift
//  SanTube
//
//  Created by Dai Pham on 12/26/17.
//  Copyright © 2017 Sunrise Software Solutions. All rights reserved.
//

import UIKit
import SocketIO
import StarscreamSocketIO

class Sockets: NSObject {
    
    // MARK: - proeprties
    var socket:WebSocket!
    var url:String!
    var timerPing:Timer!
    
    // MARK: - override
    init(url:String) {
        super.init()
        self.url = url
        connect(url: url)
    }
    
    // MARK: - interface
    func disconnect() {
        socket.disconnect()
    }
    
    // MARK: - private
    private func connect(url:String) {
        socket = WebSocket(url: URL(string: url)!, protocols: ["ws"])
//        socket.httpMethod = .post
        socket.advancedDelegate = self
        socket.onConnect = {
            print("websocket is connected")
//            self.socket.write(ping: Data())
//            self.timerPing = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { (timer) in
//                self.socket.write(ping: Data())
//            })
//            self.socket.write(data: try! JSONSerialization.data(withJSONObject: ["msg":"Hi server"], options: JSONSerialization.WritingOptions.prettyPrinted))
        }
        //websocketDidDisconnect
        
        socket.onDisconnect = { (error: NSError?) in
            print("websocket is disconnected: \(error?.localizedDescription)")
        }
        //websocketDidReceiveMessage
        socket.onText = {[weak self] (text: String) in
            guard self != nil else {return}
            print("got some text: \(text)")
        }
        //websocketDidReceiveData
        socket.onData = { (data: Data) in
            print("got some data: \(data.count)")
        }
        socket.connect()
    }
}

extension Sockets:WebSocketAdvancedDelegate {
    func websocketDidConnect(socket: WebSocket) {
        print("socket connected")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("socket disconnected")
    }
    
    func websocketHttpUpgrade(socket: WebSocket, request: CFHTTPMessage) {
        print("reuquest update")
    }
    
    func websocketHttpUpgrade(socket: WebSocket, response: CFHTTPMessage) {
        print("response update")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String, response: WebSocket.WSResponse) {
        print("got some text: \(text)")
        print("First frame for this message arrived on \(response.firstFrame)")
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data, response: WebSocket.WSResponse) {
        print("got some data it long: \(data.count)")
        print("A total of \(response.frameCount) frames were used to send this data")
    }
}
