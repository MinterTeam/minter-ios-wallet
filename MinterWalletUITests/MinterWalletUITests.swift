//
//  MinterWalletUITests.swift
//  MinterWalletUITests
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import XCTest

class MinterWalletUITests: XCTestCase {
	
	var app: XCUIApplication!
	
	func loginAdvancedMode() {
		
		self.app.buttons["ADVANCED MODE"].tap()
		self.app.textViews.firstMatch.tap()
		self.app.textViews.firstMatch.typeText("puzzle feed enlist rack cliff divert exist bind swamp kiwi casino pull")
		self.app.buttons["Done"].tap()
		self.app.buttons["ACTIVATE"].tap()
	}
	
	func loginAdvancedModeNewAccount() {
		self.app.buttons["ADVANCED MODE"].tap()
		self.app.buttons["GENERATE ADDRESS"].tap()
		self.app.switches.firstMatch.tap()
		self.app.buttons["LAUNCH THE WALLET"].tap()
	}
	
	func logout() {
		if self.app.tabBars.buttons["Settings"].exists {
			self.app.tabBars.buttons["Settings"].tap()
			
			self.app.buttons["LOG OUT"].tap()
		}
	}
	
	func closeModal() {
		
		let close = self.app.buttons["CLOSE"]
		
		if close.exists {
			close.tap()
		}
		
	}
	
	func isBalanceAvailable() {
		let label = app.staticTexts["Total Balance"]
		
		expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
		waitForExpectations(timeout: 15, handler: nil)
	}
        
	override func setUp() {
		super.setUp()
	
		continueAfterFailure = false
		
		app = XCUIApplication()
		app.launchArguments = ["UITesting"] 
		app.launch()
		
		logout()
	}
    
	override func tearDown() {
		logout()
		
		super.tearDown()
	}

	func testLoginAdvancedMode() {
		loginAdvancedMode()
		
		let label = self.app.tables.otherElements["My Coins"]
		XCUIApplication().tables.firstMatch.swipeUp()
		
		expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
		waitForExpectations(timeout: 15, handler: nil)
	}
	
	func testSendCoinAdvancedMode() {
		loginAdvancedMode()
		
		isBalanceAvailable()
		
		if self.app.tabBars.buttons["Send"].exists {
			self.app.tabBars.buttons["Send"].tap()

			let textView = self.app.textViews.firstMatch

			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: textView, handler: nil)
			waitForExpectations(timeout: 20, handler: nil)

			textView.tap()
			textView.typeText("@ody344")

			self.app.textFields.element(boundBy: 1).tap()
			self.app.textFields.element(boundBy: 1).typeText("0.000001")
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: self.app.buttons["SEND"]) {
				self.app.tables.buttons["SEND"].tap()
				return true
			}
			waitForExpectations(timeout: 20, handler: nil)

			let button = self.app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).buttons["SEND"]

			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: button, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			button.tap()
			
			let label = app.staticTexts["Coins are received by"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			closeModal()
		}
	}
	
	func testCantSendCoinAdvancedMode() {
		loginAdvancedMode()
		
		if self.app.tabBars.buttons["Send"].exists {
			self.app.tabBars.buttons["Send"].tap()
			
			let textView = self.app.textViews.firstMatch
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: textView, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			textView.tap()
			textView.typeText("@ody344")
			
			self.app.textFields.element(boundBy: 1).tap()
			self.app.textFields.element(boundBy: 1).typeText("99999999999.9")
			
			self.app.tables.buttons["SEND"].tap()
			
			let button = self.app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).buttons["SEND"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: button, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			button.tap()
			
			let label = app.staticTexts["An Error Occurred"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			closeModal()

		}
		
	}
	
	//MARK: -
	
	func testSendCoinAdvancedModeAddress() {
		loginAdvancedMode()
		
		if self.app.tabBars.buttons["Send"].exists {
			self.app.tabBars.buttons["Send"].tap()
			
			let textView = self.app.textViews.firstMatch
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: textView, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			textView.tap()
			textView.typeText("Mxeeda61bbe9929bf883af6b22f5796e4b92563ba4")
			
			self.app.tables.buttons["USE MAX"].tap()
			
			self.app.tables.buttons["SEND"].tap()
			
			let button = self.app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).buttons["SEND"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: button, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			button.tap()
			
			let label = app.staticTexts["Coins are received by"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			closeModal()
		}
	}
	
	func testCantSendCoinAdvancedModeAddress() {
		loginAdvancedMode()
		
		if self.app.tabBars.buttons["Send"].exists {
			self.app.tabBars.buttons["Send"].tap()
			
			let textView = self.app.textViews.firstMatch
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: textView, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			textView.tap()
			textView.typeText("Mx228e5a68b847d169da439ec15f727f08233a7ca6")
			
			self.app.textFields.element(boundBy: 1).tap()
			self.app.textFields.element(boundBy: 1).typeText("99999999999.9")
			
			self.app.tables.buttons["SEND"].tap()
			
			let button = self.app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).buttons["SEND"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: button, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			button.tap()
			
			let label = app.staticTexts["An Error Occurred"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			closeModal()
			
		}
	}
	
	//Balance
	
	func testCheckBalance() {
		loginAdvancedMode()
		
		XCTAssertTrue(app.staticTexts["Total Balance"].exists)
	}
	
	//Login
	
	func testLogin() {
		logout()
		
		let login = "testme"
		let pwd = "123456"
		
		let app = XCUIApplication()
		app.buttons["SIGN IN"].tap()
		
		let tablesQuery2 = app.tables
		let password = tablesQuery2.cells.containing(.staticText, identifier:"YOUR PASSWORD").children(matching: .secureTextField).element
		password.tap()
		password.typeText(pwd)
		
		let tablesQuery = tablesQuery2
		let username = tablesQuery/*@START_MENU_TOKEN@*/.textFields.containing(.staticText, identifier:"@").element/*[[".cells.textFields.containing(.staticText, identifier:\"@\").element",".textFields.containing(.staticText, identifier:\"@\").element"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		username.tap()
		username.typeText(login)
		
		tablesQuery/*@START_MENU_TOKEN@*/.buttons["CONTINUE"]/*[[".cells.buttons[\"CONTINUE\"]",".buttons[\"CONTINUE\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		
		let label = app.staticTexts["Total Balance"]
		
		expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
		waitForExpectations(timeout: 15, handler: nil)
	}
	
	func testLoginWithIncorrectCredentials() {
		logout()
		
		let login = "testmedsad"
		let pwd = "123456dasd"
		
		let app = XCUIApplication()
		app.buttons["SIGN IN"].tap()
		
		let tablesQuery2 = app.tables
		let password = tablesQuery2.cells.containing(.staticText, identifier:"YOUR PASSWORD").children(matching: .secureTextField).element
		password.tap()
		password.typeText(pwd)
		
		let tablesQuery = tablesQuery2
		let username = tablesQuery/*@START_MENU_TOKEN@*/.textFields.containing(.staticText, identifier:"@").element/*[[".cells.textFields.containing(.staticText, identifier:\"@\").element",".textFields.containing(.staticText, identifier:\"@\").element"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
		username.tap()
		username.typeText(login)
		
		tablesQuery/*@START_MENU_TOKEN@*/.buttons["CONTINUE"]/*[[".cells.buttons[\"CONTINUE\"]",".buttons[\"CONTINUE\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		
		let label = app.staticTexts["The user credentials were incorrect."]
		
		expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
		waitForExpectations(timeout: 15, handler: nil)
	}

	func testLoginAdvancedModeNewAccount() {
		loginAdvancedModeNewAccount()

		isBalanceAvailable()
	}

	func testConvertCoin() {
		loginAdvancedMode()
		
		let app = XCUIApplication()
		let tablesQuery = app.tables
		self.app.tables.firstMatch.swipeUp()
		self.app.tables.firstMatch.swipeUp()
		
		tablesQuery/*@START_MENU_TOKEN@*/.buttons["CONVERT"]/*[[".cells.buttons[\"CONVERT\"]",".buttons[\"CONVERT\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
		
		let elementsQuery = app.scrollViews.otherElements
		let scrollViewsQuery = elementsQuery.scrollViews
		scrollViewsQuery.children(matching: .textField).element(boundBy: 0).tap()
		app.pickerWheels.firstMatch.swipeUp()
		
		app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).tap()

		let amountEl = app.scrollViews.otherElements.scrollViews.children(matching: .textField).element(boundBy: 1)
		amountEl.tap()
		amountEl.typeText("1")
	
		let elementsQuery1 = app.scrollViews.otherElements

		let textField = elementsQuery1.scrollViews.children(matching: .textField).element(boundBy: 2)
		textField.tap()
		textField.typeText("USD")
		
		textField.swipeDown()
		textField.swipeUp()
		
		app.buttons["EXCHANGE"].tap()
		
		let sucLabel = self.app.staticTexts["Coins have been successfully spent"]
		
		expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: sucLabel, handler: nil)
		waitForExpectations(timeout: 15, handler: nil)
	}
	
	func testConvertCoinGet() {
		loginAdvancedMode()
			
		let app = XCUIApplication()
		let tablesQuery = app.tables
		self.app.tables.firstMatch.swipeUp()
		self.app.tables.firstMatch.swipeUp()
		
		tablesQuery/*@START_MENU_TOKEN@*/.buttons["CONVERT"]/*[[".cells.buttons[\"CONVERT\"]",".buttons[\"CONVERT\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

		XCUIApplication().scrollViews.otherElements/*@START_MENU_TOKEN@*/.scrollViews.containing(.staticText, identifier:"COIN YOU HAVE").element/*[[".scrollViews.containing(.button, identifier:\"EXCHANGE\").element",".scrollViews.containing(.staticText, identifier:\"The final amount depends on the exchange rate at the moment of transaction.\").element",".scrollViews.containing(.staticText, identifier:\"COIN YOU WANT\").element",".scrollViews.containing(.image, identifier:\"convertIcon\").element",".scrollViews.containing(.button, identifier:\"USE MAX\").element",".scrollViews.containing(.staticText, identifier:\"AMOUNT\").element",".scrollViews.containing(.staticText, identifier:\"COIN YOU HAVE\").element"],[[[-1,6],[-1,5],[-1,4],[-1,3],[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.swipeLeft()
		
		let amountEl = app.scrollViews.otherElements.scrollViews.children(matching: .textField).element(boundBy: 1)
		amountEl.tap()
		amountEl.typeText("1")
		
			let elem = XCUIApplication().scrollViews.otherElements.scrollViews.children(matching: .textField).element(boundBy: 0)
		elem.tap()
		elem.typeText("USD")
		
		elem.swipeDown()
		elem.swipeUp()
		
		app.buttons["EXCHANGE"].tap()
		
		let sucLabel = self.app.staticTexts["Coins have been successfully bought"]
		
		expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: sucLabel, handler: nil)
		waitForExpectations(timeout: 15, handler: nil)
	}

}
