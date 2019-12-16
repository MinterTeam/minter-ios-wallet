//
//  RawTransactionViewModelTests.swift
//  MinterWalletTests
//
//  Created by Alexey Sidorov on 09.11.2019.
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

class RawTransactionViewModelTests: XCTestCase {

	override func setUp() {
		let account = Account(id: 1,
													encryptedBy: .me,
													address: "Mx2cd39c2a1123181b46dbaaac00d28e81baab9811",
													isMain: true)
		Session.shared.accounts.accept([account])
	}

	override func tearDown() {
		Session.shared.accounts.accept([])
	}

	func testShouldCreateSendViewModel() {
		let rawType = RawTransactionType.sendCoin
		let sendData = SendCoinRawTransactionData(to: "Mx", value: BigUInt(1), coin: "BIP")
		let rlpEncoded = RLP.encode([rawType, sendData, ""]) ?? Data()

		let dependency = RawTransactionViewModel.Dependency(account: RawTransactionViewModelAccount(),
																												gate: GateManager.shared)
		let viewModel = try? RawTransactionViewModel(dependency: dependency,
																								 nonce: BigUInt(1),
																								 gasPrice: BigUInt(1),
																								 gasCoin: "MNT",
																								 type: rawType,
																								 data: rlpEncoded,
																								 payload: "",
																								 serviceData: nil,
																								 signatureType: nil)
		XCTAssert(viewModel != nil)
	}
	
	func testShouldCreateSendWithEmptyOptionalsParamsViewModel() {
		let rawType = RawTransactionType.sendCoin
		let sendData = SendCoinRawTransactionData(to: "Mx", value: BigUInt(1), coin: "BIP")
		let rlpEncoded = RLP.encode([rawType, sendData, "", [], [], []]) ?? Data()

		let dependency = RawTransactionViewModel.Dependency(account: RawTransactionViewModelAccount(),
																												gate: GateManager.shared)
		let viewModel = try? RawTransactionViewModel(dependency: dependency,
																								 nonce: BigUInt(1),
																								 gasPrice: BigUInt(1),
																								 gasCoin: "MNT",
																								 type: rawType,
																								 data: rlpEncoded,
																								 payload: "",
																								 serviceData: nil,
																								 signatureType: nil)
		XCTAssert(viewModel != nil)
	}

	func testShouldCreateSendWithFilledOptionalsParamsViewModel() {
		let rawType = RawTransactionType.sendCoin
		let sendData = SendCoinRawTransactionData(to: "Mx", value: BigUInt(1), coin: "BIP")
		let rlpEncoded = RLP.encode([rawType, sendData, "", [], [], "BIP"]) ?? Data()

		let dependency = RawTransactionViewModel.Dependency(account: RawTransactionViewModelAccount(),
																												gate: GateManager.shared)
		let viewModel = try? RawTransactionViewModel(dependency: dependency,
																								 nonce: BigUInt(1),
																								 gasPrice: BigUInt(1),
																								 gasCoin: "BIP",
																								 type: rawType,
																								 data: rlpEncoded,
																								 payload: "",
																								 serviceData: nil,
																								 signatureType: nil)
		XCTAssert(viewModel != nil)
		XCTAssert(viewModel != nil)
	}

//	func testShouldCreateCheckViewModel() {
//		let rawType = RawTransactionType.redeemCheck
//		let sendData = RedeemCheckRawTransactionData(rawCheck: "", proof: "")
//		let rlpEncoded = RLP.encode([rawType, sendData, ""]) ?? Data()
//
//		let dependency = RawTransactionViewModel.Dependency(account: RawTransactionViewModelAccount(),
//																												gate: GateManager.shared)
//		let viewModel = try? RawTransactionViewModel(dependency: dependency,
//																								 nonce: BigUInt(1),
//																								 gasPrice: BigUInt(1),
//																								 gasCoin: "MNT",
//																								 type: rawType,
//																								 data: rlpEncoded,
//																								 payload: "",
//																								 serviceData: nil,
//																								 signatureType: nil)
//		XCTAssert(viewModel != nil)
//	}

}
