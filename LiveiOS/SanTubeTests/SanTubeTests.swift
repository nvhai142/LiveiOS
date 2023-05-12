//
//  SanTubeTests.swift
//  SanTubeTests
//
//  Created by Dai Pham on 2/22/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import XCTest
@testable import SanTube
class SanTubeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRemoveScriptFromString() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let a = "<script>abc</script><img href='abc.com' />".removeScript()
        print(a)
        XCTAssert(!a.contains("</script>") && !a.contains("/>"))
    }
    
    func testRegisterWithApi() {
        let promise = expectation(description: "Start involke api/register")
        Server.shared.register(email: "phamdaiit@gmail.com",
                               password: "123456",
                               password_confirmation: "123456",
                               "test") { (json, err) in
            if err != nil {
                print(err.debugDescription)
            } else {
                promise.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssert(promise.assertForOverFulfill, "API DONT WPRKING")
    }
    
    func testGetListFollowWithApi() {
        let promise = expectation(description: "Start involke api/follows")
        Server.shared.getListFollows(userIds: ["516","3222"],
                                     isFollowing: true,
                                     page: 1) { (listUser, message, morPage) in
                                        if let list = listUser {
                                            print("\n======RESULT========\ndata:\t\t \(list)")
                                        } else {
                                            print("\n======RESULT========\nDATA:\t\t NULL")
                                        }
                                        print("ERROR:\t\t\t \(message ?? "No error")")
                                        print("MORE PAGE:\t\t \(morPage ?? false)\n====================\n")
                                        promise.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(promise.assertForOverFulfill, "API DONT WPRKING")
    }
    
    func testFollowWithApi() {
        let promise = expectation(description: "Start involke api/follows")
        Server.shared.actionFollow(followerId: "3222",
                                   followingId: "516",
                                   unFollow: false) { (done, msgErr) in
                                    print(done)
                                    print(msgErr)
                                    promise.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(promise.assertForOverFulfill, "API DONT WPRKING")
    }
    
    func testCheckFollowWithApi() {
        let promise = expectation(description: "Start involke api/follows")
        Server.shared.checkFollow(followerId: "322",
                                   followingId: "516") { (done, msgErr) in
                                    print(done)
                                    print(msgErr)
                                    promise.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        XCTAssert(promise.assertForOverFulfill, "API DONT WPRKING")
    }
    
    func testValidPassword() {
        
        XCTAssertFalse(" 12345".isValidPassword(), "expect: FALSE")
        XCTAssertFalse("@612     ".isValidPassword(), "expect: FALSE")
        
        XCTAssertTrue("612345".isValidPassword(), "expect: TRUE")
        XCTAssertTrue("612'345".isValidPassword(), "expect: TRUE")
        XCTAssertTrue("@612'345".isValidPassword(), "expect: TRUE")
    }
    
    func testValidEmail() {
        for (i,p) in ["NotAnEmail"
//                  "@NotAnEmail",
//                  "\"\"test\\blah\"\"@example.com",
//                  "\"test\\\rblah\"@example.com",
//                  "\"test\rblah\"@example.com",
//                  "''''test''blah''@example.com",
//                  "customer/department@example.com",
//                  "$A12345@example.com",
//                  "!def!xyz%abc@example.com",
//                  "_Yosemite.Sam@example.com",
//                  "~@example.com",
//                  ".wooly@example.com",
//                  "wo..oly@example.com",
//                  "pootietang.@example.com",
//                  ".@example.com",
//                  "''Austin@Powers''@example.com",
//                  "Ima.Fool@example.com",
//                  "\"\"Ima.Fool\"\"@example.com",
//                  "\"\"Ima Fool\"\"@example.com",
//                  "Ima Fool@example.com"
            ].enumerated() {
                    if i == 2 ||
                        i == 4 ||
                        i == 6 ||
                        i == 8 ||
                        i == 9 ||
                        i == 10 ||
                        i == 11 ||
                        i == 12 ||
                        i == 17 ||
                        i == 18 ||
                        i == 19 ||
                        i == 20 {
                        XCTAssert(p.isValidEmail(), "\(p) expect: TRUE but result: FALSE")
                    } else {
                        XCTAssert(!p.isValidEmail(), "\(p)expect: FALSE but result: TRUE")
                    }
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
