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

enum GateManagerErrorRx: Error {
	case noCount
	case noCommission
	case noTransaction
}

extension GateManager {

	func estimateComission(tx: String) -> Observable<Decimal> {
		return Observable.create { (observer) -> Disposable in
			self.estimateTXCommission(for: tx) { (commission, error) in
				
				guard let commission = commission, nil == error else {
					observer.onError(error ?? GateManagerErrorRx.noCommission)
					return
				}
				
				observer.onNext(commission)
				observer.onCompleted()
			}
			return Disposables.create()
		}
	}

	func estimateCoinSell(coinFrom: String, coinTo: String, value: Decimal, isAll: Bool = false) -> Observable<(Decimal, Decimal)> {
		return Observable.create { (observer) -> Disposable in
//			if isAll {
//				self.estimateCoinSellAll(coinFrom: coinFrom,
//																 coinTo: coinTo,
//																 value: value,
//																 gasPrice: gasPrice,
//																 completion: { (res1, res2, error) in
//					guard error == nil && res1 != nil && res2 != nil else {
//						observer.onError(error ?? GateManagerErrorRx.noCommission)
//						return
//					}
//
//					observer.onNext((res1!, res2!))
//					observer.onCompleted()
//				})
//			} else {
				self.estimateCoinSell(coinFrom: coinFrom, coinTo: coinTo, value: value, completion: { (res1, res2, error) in
					guard error == nil && res1 != nil && res2 != nil else {
						observer.onError(error ?? GateManagerErrorRx.noCommission)
						return
					}
					
					observer.onNext((res1!, res2!))
					observer.onCompleted()
				})
				return Disposables.create()
//			}
		}
	}

	func nonce(address: String) -> Observable<Int> {
		return Observable.create { (observer) -> Disposable in
			self.nonce(for: address) { (count, error) in
				
				guard let count = count, nil == error else {
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

	func minGas() -> Observable<Int> {
		return Observable.create { (observer) -> Disposable in
			self.minGasPrice(completion: { (gas, error) in
				guard nil == error && gas != nil else {
					observer.onError(error!)
					return
				}
				observer.onNext(gas!)
				observer.onCompleted()
			})
			return Disposables.create()
		}
	}

	func send(rawTx: String?) -> Observable<String?> {
		return Observable.create { observer -> Disposable in
			if rawTx != nil {
				self.sendRawTransaction(rawTransaction: rawTx!, completion: { (hash, error) in
					guard nil == error else {
						observer.onError(error!)
						return
					}
					observer.onNext(hash)
					observer.onCompleted()
				})
			}
			else {
				observer.onError(GateManagerErrorRx.noTransaction)
			}
			return Disposables.create()
		}
	}

}
