//
//  SendViewModelProtocol.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 31.10.2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift

protocol SendViewModelGateProtocol {
	func minGas() -> Observable<Int>
	func nonce(address: String) -> Observable<Int>
	func send(rawTx: String) -> Observable<String?>
	func estimateTXCommission(rawTx: String) -> Observable<Decimal>
}
protocol SendViewModelInfoProtocol {
	func address(term: String) -> Observable<String>
}
