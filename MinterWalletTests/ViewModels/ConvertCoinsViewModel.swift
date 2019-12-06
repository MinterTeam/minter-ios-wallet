//
//  ConvertCoinsViewModel.swift
//  MinterWalletTests
//
//  Created by Alexey Sidorov on 20.11.2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import XCTest
@testable import MinterWallet
@testable import MinterCore
@testable import MinterMy

class ConvertCoinsViewModelTests: XCTestCase {

	override func setUp() {
		MinterCoreSDK.initialize(urlString: "", network: .testnet)

		let account = Account(id: 1,
													encryptedBy: .me,
													address: "Mx2cd39c2a1123181b46dbaaac00d28e81baab9811",
													isMain: true)
		Session.shared.accounts.accept([account])
	}

	override func tearDown() {}

	func testCoinNames() {
		let coin1 = MinterCore.Coin()
		coin1.symbol = "Coin1"
		coin1.reserveBalance = 1.0

		let coin2 = MinterCore.Coin()
		coin2.symbol = "Coin2"
		coin2.reserveBalance = 2.0

		let coin3 = MinterCore.Coin()
		coin3.symbol = "Coin3"
		coin3.reserveBalance = 3.0

		let coin4 = MinterCore.Coin()
		coin4.symbol = "Coin4"
		coin4.reserveBalance = 4.0

		let coin5 = MinterCore.Coin()
		coin5.symbol = "Coin"
		coin5.reserveBalance = 0.1

		let exp = self.expectation(description: "waiting for coins")
		exp.expectedFulfillmentCount = 1
		let convertVM = ConvertCoinsViewModel()
		Session.shared.allCoins.accept([
			coin1, coin2, coin3, coin4, coin5
		])

		convertVM.coinNames(by: "Coin", completion: { coins in
			if
				//first coin should be with equal symbols
				coins[0] == (coin5.symbol ?? "")
				//then sorted by reserve
				&& coins[1] == (coin4.symbol ?? "")
				&& coins[2] == (coin3.symbol ?? "") {
				exp.fulfill()
			}
		})
		waitForExpectations(timeout: 3)
	}

	func testCoinNamesWithBaseCoin() {
		let coin1 = Coin.baseCoin()
		coin1.reserveBalance = Decimal.greatestFiniteMagnitude

		let coin2 = MinterCore.Coin()
		coin2.symbol = "MNT2"
		coin2.reserveBalance = 2.0

		let coin3 = MinterCore.Coin()
		coin3.symbol = "MNT3"
		coin3.reserveBalance = 3.0

		let coin4 = MinterCore.Coin()
		coin4.symbol = "MNT4"
		coin4.reserveBalance = 4.0

		let coin5 = MinterCore.Coin()
		coin5.symbol = "MNT5"
		coin5.reserveBalance = 0.1

		Session.shared.allCoins.accept([
			coin1, coin2, coin3, coin4, coin5
		])

		let exp = self.expectation(description: "waiting for coins")
		exp.expectedFulfillmentCount = 1
		let convertVM = ConvertCoinsViewModel()

		convertVM.coinNames(by: "MNT", completion: { coins in
			if
				//first coin should be BaseCoin
				coins[0] == (Coin.baseCoin().symbol ?? "")
				//then sorted by reserve
				&& coins[1] == (coin4.symbol ?? "")
				&& coins[2] == (coin3.symbol ?? "") {
				exp.fulfill()
			}
		})
		waitForExpectations(timeout: 3)
	}

}
