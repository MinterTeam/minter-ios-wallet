//
//  RawTransactionRouterTests.swift
//  MinterWalletTests
//
//  Created by Alexey Sidorov on 06.11.2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import XCTest
import CryptoSwift
@testable import MinterWallet

class RawTransactionRouterTests: XCTestCase {

	override func setUp() {
		super.setUp()
	}

	override func tearDown() {
		super.tearDown()
	}

	func testRouterEmptyParam() {
		let viewController = RawTransactionRouter.viewController(path: ["tx"], param: [:])
		XCTAssert(viewController == nil)
	}

	func testRouterCheck() {
		let viewController = RawTransactionRouter
			.viewController(path: ["tx"], param: ["d": "f8bf09b8aef8acb8a9f8a78677617a7a617002843b9ac9ff8a4d4e5400000000000000888ac7230489e80000b841a5e50e3e09b32ed00558ece561aa010f7601856ecf59f945e079f2df61a70ec84c99c2715a11b578f5c06c6bc4ae21697d2138026743db59ba867236ca9ccd8c011ba0183fc4b593d59c00489c2d4f954b66d618979e5f4883f171a4603c40748de566a014b658338e8306b2db92e9d0d8dbc7ecc31d4817040ad73469b93c51be739c7c808080018a4d4e5400000000000000",
																						"p": "pass"])
		XCTAssert(viewController != nil)
	}

}
