//
//  SanTubeUITests.swift
//  SanTubeUITests
//
//  Created by Dai Pham on 2/22/18.
//  Copyright © 2018 Sunrise Software Solutions. All rights reserved.
//

import XCTest

class SanTubeUITests: XCTestCase {
    
    var app:XCUIApplication!
    var elementsQuery:XCUIElementQuery!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = true
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        app.launch()
        elementsQuery = app.scrollViews.otherElements
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        elementsQuery = nil
        super.tearDown()
    }
    
    func testLoginWithEmail() {
        let btnSIFacebook = elementsQuery.buttons["Sign in with Facebook"]
        let btnSIEmail = elementsQuery.buttons["Sign in with Email"]
        let btnLoginWithFB = elementsQuery.buttons["Log in with Facebook"]
        let txtEmail = elementsQuery.textFields["Email"]
        let txtPassword = elementsQuery.secureTextFields["Password"]
        let btnLogin = elementsQuery.buttons["LOGIN"]
        let btnRegister = elementsQuery.buttons["New account"]
        let btnForgotPassword = elementsQuery.buttons["Forget your password"]
        
        let alert = app.alerts["Notice"]
        
        // touch button sign in with Email
        btnSIEmail.tap()
        
        
        // login with wrong email
        txtEmail.tap()
        txtEmail.typeText("dai")
        txtPassword.tap()
        txtPassword.typeText("123456")
        btnLogin.tap()
        
        XCTAssertTrue(alert.exists, "JUST SHOW ALERT")
        
        alert.buttons["OK"].tap()
        
        // login again with true data
        txtEmail.tap()
        txtEmail.typeText("@gmail.com")

        expectation(description: "Start fake request login in 3 seconds").fulfill()
    
        btnLogin.tap()
        
        XCTAssertFalse(alert.exists, "SHOULD NOT SHOW ALERT")
        
        XCTAssertFalse(btnLogin.isEnabled, "button login should disabled")
        XCTAssertFalse(btnRegister.isEnabled, "button register should disabled")
        XCTAssertFalse(btnForgotPassword.isEnabled, "button forget should disabled")
        XCTAssertFalse(btnLoginWithFB.isEnabled, "button forget should disabled")
        
        waitForExpectations(timeout: 3, handler: nil)
        
        XCTAssertTrue(btnLogin.isEnabled, "button login should enabled")
        XCTAssertTrue(btnRegister.isEnabled, "button register should enabled")
        XCTAssertTrue(btnForgotPassword.isEnabled, "button forget should enabled")
        XCTAssertTrue(btnLoginWithFB.isEnabled, "button forget should enabled")
    }
    
    func testLoginUI() {
        let btnFacebook = elementsQuery.buttons["Sign in with Facebook"]
        let btnEmail = elementsQuery.buttons["Sign in with Email"]
        btnFacebook.tap()
        if !btnFacebook.isEnabled {
            XCTAssertTrue(!btnEmail.exists, "BUTTON EMAIL SHOULD HIDDEN")
        }
        
    }
    
    func testRecord() {
        
        let elementsQuery = XCUIApplication().scrollViews.otherElements
        elementsQuery.buttons["Sign in with Email"].tap()
        
        let emailTextField = elementsQuery.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("gd")
        
        
        
        
    }
    
}
