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
		self.app.textViews.firstMatch.typeText("reveal panel silk afford access pride actress skill crawl alpha announce extra")
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
		let label = app.staticTexts["My Balance"]
		
		expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
		waitForExpectations(timeout: 15, handler: nil)
	}
        
	override func setUp() {
		super.setUp()
	
		continueAfterFailure = false
		
		app = XCUIApplication()
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
		
		if self.app.tabBars.buttons["Send"].exists {
			self.app.tabBars.buttons["Send"].tap()
			
			let textView = self.app.textViews.firstMatch
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: textView, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			textView.tap()
			textView.typeText("@ody344")
			
			self.app.textFields.element(boundBy: 1).tap()
			self.app.textFields.element(boundBy: 1).typeText("0.000001")
			
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
			textView.typeText("Mx228e5a68b847d169da439ec15f727f08233a7ca6")
			
			self.app.textFields.element(boundBy: 1).tap()
			self.app.textFields.element(boundBy: 1).typeText("0.0001")
			
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
		
		XCTAssertTrue(app.staticTexts["My Balance"].exists)
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
		
		let label = app.staticTexts["My Balance"]
		
		expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
		waitForExpectations(timeout: 15, handler: nil)
	}
	
	
	func testLoginAdvancedModeNewAccount() {
		loginAdvancedModeNewAccount()

		isBalanceAvailable()
	}
	
	func testLoginAdvancedModeNewAccountAskForFree() {
		
		loginAdvancedModeNewAccount()
		
		isBalanceAvailable()
		
		if self.app.tabBars.buttons["Settings"].exists {
			self.app.tabBars.buttons["Settings"].tap()
			
			self.app.buttons["GET 100 MNT"].tap()
			
			let label = app.staticTexts["MNT has been deposited to your account"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			
			if self.app.tabBars.buttons["Coins"].exists {
				self.app.tabBars.buttons["Coins"].tap()
				
				
				for i in 0...100 {
					let firstCell = app.staticTexts["My Coins"]
					let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
					let finish = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 16))
					start.press(forDuration: 0, thenDragTo: finish)
				}
				
				let balanceLabel = app.staticTexts["100.0000 MNT"]
				
				expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: balanceLabel, handler: nil)
				waitForExpectations(timeout: 250, handler: nil)
				
			}
			
			
			if self.app.tabBars.buttons["Send"].exists {
				self.app.tabBars.buttons["Send"].tap()
				
				let textView = self.app.textViews.firstMatch
				
				expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: textView, handler: nil)
				waitForExpectations(timeout: 15, handler: nil)
				
				textView.tap()
				textView.typeText("@admin")
				
				self.app.textFields.element(boundBy: 1).tap()
				self.app.textFields.element(boundBy: 1).typeText("99.9")
				
				self.app.tables.buttons["SEND"].tap()
				
				let button = self.app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).buttons["SEND"]
				
				expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: button, handler: nil)
				waitForExpectations(timeout: 15, handler: nil)
				
				button.tap()
				
				let label1 = app.staticTexts["Coins are received by"]
				
				expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label1, handler: nil)
				waitForExpectations(timeout: 15, handler: nil)
				
				closeModal()
				
			}
		}
	}
	
	func testConvertCoin() {
		loginAdvancedModeNewAccount()
		
		
		if self.app.tabBars.buttons["Settings"].exists {
			self.app.tabBars.buttons["Settings"].tap()
			
			self.app.buttons["GET 100 MNT"].tap()
			
			let label = self.app.staticTexts["MNT has been deposited to your account"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			
			if self.app.tabBars.buttons["Coins"].exists {
				self.app.tabBars.buttons["Coins"].tap()
				
				
				for i in 0...5 {
					let firstCell = self.app.staticTexts["My Coins"]
					let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
					let finish = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 26))
					start.press(forDuration: 0, thenDragTo: finish)
				}
				
				let balanceLabel = self.app.staticTexts["100.0000 MNT"]
				
				expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: balanceLabel, handler: nil)
				waitForExpectations(timeout: 30, handler: nil)
				
			}
		
			let app = XCUIApplication()
			let tablesQuery = app.tables
			self.app.tables.firstMatch.swipeUp()
			self.app.tables.firstMatch.swipeUp()
			
			tablesQuery/*@START_MENU_TOKEN@*/.buttons["CONVERT"]/*[[".cells.buttons[\"CONVERT\"]",".buttons[\"CONVERT\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
			
			let elementsQuery = app.scrollViews.otherElements
			let scrollViewsQuery = elementsQuery.scrollViews
			scrollViewsQuery.children(matching: .textField).element(boundBy: 0).tap()
			app.pickerWheels.firstMatch.swipeUp()

			XCUIApplication().children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).tap()
			
			app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).tap()

			let elementsQuery1 = app.scrollViews.otherElements
			elementsQuery1/*@START_MENU_TOKEN@*/.buttons["USE MAX"]/*[[".scrollViews.buttons[\"USE MAX\"]",".buttons[\"USE MAX\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

			let textField = elementsQuery1.scrollViews.children(matching: .textField).element(boundBy: 2)
			textField.tap()
			textField.typeText("VALIDATOR")
			
			textField.swipeDown()
			textField.swipeUp()
			
			app.buttons["EXCHANGE"].tap()
			
			let sucLabel = self.app.staticTexts["Coins have been successfully spent"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: sucLabel, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
		}
	}
	
	func testConvertCoinGet() {
		loginAdvancedModeNewAccount()
		
		if self.app.tabBars.buttons["Settings"].exists {
			self.app.tabBars.buttons["Settings"].tap()
			
			self.app.buttons["GET 100 MNT"].tap()
			
			let label = self.app.staticTexts["MNT has been deposited to your account"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: label, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
			
			
			if self.app.tabBars.buttons["Coins"].exists {
				self.app.tabBars.buttons["Coins"].tap()
				
				for i in 0...5 {
					let firstCell = self.app.staticTexts["My Coins"]
					let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
					let finish = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 26))
					start.press(forDuration: 0, thenDragTo: finish)
				}
				
				let balanceLabel = self.app.staticTexts["100.0000 MNT"]
				
				expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: balanceLabel, handler: nil)
				waitForExpectations(timeout: 30, handler: nil)
				
			}
			
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
			elem.typeText("VALIDATOR")
			
			elem.swipeDown()
			elem.swipeUp()
			
			app.buttons["EXCHANGE"].tap()
			
			let sucLabel = self.app.staticTexts["Coins have been successfully bought"]
			
			expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: sucLabel, handler: nil)
			waitForExpectations(timeout: 15, handler: nil)
		}
	}

}
