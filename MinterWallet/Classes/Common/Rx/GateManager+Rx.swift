//
//  GasManager+Rx.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/01/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift

enum GateManagerRxError : Error {
	case noGas
}

extension GateManager {
	
	func minGasPrice() -> Observable<Int> {
		return Observable.create { (observer) -> Disposable in
			self.minGasPrice(completion: { (gas, error) in
				guard error == nil && gas != nil else {
					observer.onError(error ?? GateManagerRxError.noGas)
					return
				}
				observer.onNext(gas!)
				observer.onCompleted()
			})
			return Disposables.create()
		}
	}
	
}
