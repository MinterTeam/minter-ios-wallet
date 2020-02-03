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
import MinterCore
@testable import MinterMy
import MinterExplorer
import BigInt

class RawTransactionRouterTests: XCTestCase {

	override func setUp() {
		super.setUp()
		let account = Account(id: 1,
													encryptedBy: .me,
													address: "Mx2cd39c2a1123181b46dbaaac00d28e81baab9811",
													isMain: true)
		Session.shared.accounts.accept([account])
	}

	override func tearDown() {
		super.tearDown()
	}

	func routerUrl(tx: String, password: String? = nil) -> URL {
		return URL(string: "https://testnet.bip.to/tx?d=\(tx)" + (password == nil ? "" : "&p=\(password!)"))!
	}

	func testRouterEmptyParam() {
		let viewController = RawTransactionRouter.viewController(path: ["tx"], param: [:])
		XCTAssert(viewController == nil)
	}

	func testRouterCheck() {
		let viewController = RawTransactionRouter
			.viewController(path: ["tx"], param: ["d": "f9010a09b8f9f8f7b8b2f8b08331323802843b9ac9ff8a4d4e54000000000000008906f05b59d3b20000008a4d4e5400000000000000b841b59c9a11ee79a5dbe6e40383a5db5a90960b452e5fddc63cc8f3d092ebf7e39303340d8f42bda3b55a681b9ece3229f9cf718d717ef0c2cb818c52a9b93f27d9001ca0afe5f4c59f1a1f64bd2d7bb97f0fc0cbb9cf1b40d12dc59f948dc419bbad51f8a05033b98e743a9d2af329e890933ea585785573d3a40f52aaa76858083d68654eb841133824027bddf75120c93cf183f5ff18beea9c350203eb7af02bcbbbca5e282201efe7e4eac2494de85b762296dd4b7ea7879b238a6dd8b012838ee6fc04d515018080018a4d4e5400000000000000",
																						"p": "8568656c6c6f"])
		XCTAssert(viewController != nil)
	}

	func testRouterTx() {
		let viewController = RawTransactionRouter
			.viewController(path: ["tx"], param: ["d": "f83a01aae98a42495000000000000000940bf1472d253960e4eae3bdf402f6fe9cf21e0e17880de0b6b3a764000080c0c08a42495000000000000000"])
		XCTAssert(viewController != nil)
	}

	func testRouterUnbondTx() {
		let tax = "f84208b838f7a095b76c6893dc28a34f005b9708bac59eae238232ef86798d672387bbb849bd228a424950000000000000008a4a92acdb4c1da6d0000080c0c083424950"
		let viewController = RawTransactionRouter
			.viewController(path: ["tx"], param: ["d": tax])
		XCTAssert(viewController != nil)
	}

	func testRouterTxWithoutGasCoin() {
		let tax = "f83f08b838f7a095b76c6893dc28a34f005b9708bac59eae238232ef86798d672387bbb849bd228a424950000000000000008a4a92acdb4c1da6d0000080c0c0c0"
		let viewController = RawTransactionRouter
			.viewController(path: ["tx"], param: ["d": tax])
		XCTAssert(viewController != nil)
	}

	func testRouterTxWrongOptionals() {
		let tax = "f83f08b838f7a095b76c6893dc28a34f005b9708bac59eae238232ef86798d672387bbb849bd228a424950000000000000008a4a92acdb4c1da6d0000080808080"
		let viewController = RawTransactionRouter
			.viewController(path: ["tx"], param: ["d": tax])
		XCTAssert(viewController != nil)
	}
	
	func testRouterWithURL() {
		let tax = "f83f08b838f7a095b76c6893dc28a34f005b9708bac59eae238232ef86798d672387bbb849bd228a424950000000000000008a4a92acdb4c1da6d0000080808080"
		let viewController = RawTransactionRouter.rawTransactionViewController(with: self.routerUrl(tx: tax))
		XCTAssert(viewController != nil)
	}
	
	func testRouterWithIncorrectURL() {
		let tax = "f83f08b838f7a095b76c6893dc28a34f005b9708bac59eae238232ef86798d672387bbb849bd228a424950000000000000008a4a92acdb4c1da6d0000080808080"
		let viewController = RawTransactionRouter.rawTransactionViewController(with: URL(string: "http://google.com/tx?a=\(tax)")!)
		XCTAssert(viewController == nil)
	}
	
	func testRouterWithIncorrectTx() {
		let tax = "incorrectTx"
		let viewController = RawTransactionRouter.rawTransactionViewController(with: self.routerUrl(tx: tax))
		XCTAssert(viewController == nil)
	}
	
	func testRouterWithURLWithoutOptionals() {
		let tax = "f83c08b838f7a095b76c6893dc28a34f005b9708bac59eae238232ef86798d672387bbb849bd228a424950000000000000008a4a92acdb4c1da6d0000080"
		let viewController = RawTransactionRouter.rawTransactionViewController(with: self.routerUrl(tx: tax))
		XCTAssert(viewController != nil)
	}

	func testRouterWithURLCheckWithPassword() {
		let tax = "f8bf09b8aef8acb8a9f8a78677617a7a617002843b9ac9ff8a4d4e5400000000000000888ac7230489e80000b841a5e50e3e09b32ed00558ece561aa010f7601856ecf59f945e079f2df61a70ec84c99c2715a11b578f5c06c6bc4ae21697d2138026743db59ba867236ca9ccd8c011ba0183fc4b593d59c00489c2d4f954b66d618979e5f4883f171a4603c40748de566a014b658338e8306b2db92e9d0d8dbc7ecc31d4817040ad73469b93c51be739c7c808080018a4d4e5400000000000000"
		let viewController = RawTransactionRouter.rawTransactionViewController(with: self.routerUrl(tx: tax, password: "86617364313233"))
		XCTAssert(viewController != nil)
	}

	func testRouterWithURLCheckWithoutPassword() {
		let tax = "f8bf09b8aef8acb8a9f8a78677617a7a617002843b9ac9ff8a4d4e5400000000000000888ac7230489e80000b841a5e50e3e09b32ed00558ece561aa010f7601856ecf59f945e079f2df61a70ec84c99c2715a11b578f5c06c6bc4ae21697d2138026743db59ba867236ca9ccd8c011ba0183fc4b593d59c00489c2d4f954b66d618979e5f4883f171a4603c40748de566a014b658338e8306b2db92e9d0d8dbc7ecc31d4817040ad73469b93c51be739c7c808080018a4d4e5400000000000000"
		let viewController = RawTransactionRouter.rawTransactionViewController(with: self.routerUrl(tx: tax))
		XCTAssert(viewController == nil)
	}

	func testRouterWithURLCheckWithoutPasswordWithProof() {
		let tax = "f9010109b8f0f8eeb8a9f8a78677617a7a617002843b9ac9ff8a4d4e5400000000000000888ac7230489e80000b841a5e50e3e09b32ed00558ece561aa010f7601856ecf59f945e079f2df61a70ec84c99c2715a11b578f5c06c6bc4ae21697d2138026743db59ba867236ca9ccd8c011ba0183fc4b593d59c00489c2d4f954b66d618979e5f4883f171a4603c40748de566a014b658338e8306b2db92e9d0d8dbc7ecc31d4817040ad73469b93c51be739c7cb8414e8ed0637054b79ebdf13253bc6292cfde912b7e460f24d5b458b726cd230f6673ad2d82ffc5f15558ceba4d5d624c3d90bd70bb8edaa3f022194c327a2c5e09008080018a4d4e5400000000000000"
		let viewController = RawTransactionRouter.rawTransactionViewController(with: self.routerUrl(tx: tax))
		XCTAssert(viewController != nil)
	}

	func testRouterWithURLCheckWithoutPassWithoutProod() {
		let tax = "f8bf09b8aef8acb8a9f8a78677617a7a617002843b9ac9ff8a4d4e5400000000000000888ac7230489e80000b841a5e50e3e09b32ed00558ece561aa010f7601856ecf59f945e079f2df61a70ec84c99c2715a11b578f5c06c6bc4ae21697d2138026743db59ba867236ca9ccd8c011ba0183fc4b593d59c00489c2d4f954b66d618979e5f4883f171a4603c40748de566a014b658338e8306b2db92e9d0d8dbc7ecc31d4817040ad73469b93c51be739c7c808080018a4d4e5400000000000000"
		let viewController = RawTransactionRouter.rawTransactionViewController(with: self.routerUrl(tx: tax))
		XCTAssert(viewController == nil)
	}

}
