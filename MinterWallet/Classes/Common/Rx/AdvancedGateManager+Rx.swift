//
//  AdvancedGateManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/08/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore

class AdvancedGate: GateManager {}

extension AdvancedGate {

	func nonce(address: String) -> Observable<Int> {
		return Observable.create { (observer) -> Disposable in
			self.nonce(for: address) { (count, error) in

				guard let count = count, nil == error else {
//					MinterCore.
					
					
					observer.onError(error ?? GateManagerErrorRx.noCount)
					return
				}
				let int = NSDecimalNumber(decimal: count).intValue
				observer.onNext(int)
				observer.onCompleted()
			}
			return Disposables.create()
		}
	}
	
	
}
