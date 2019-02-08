//
//  TransactionManager+Rx.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 22/01/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterExplorer
import RxSwift

enum ExplorerTransactionManagerErrorRx : Error {
	case noCount
	case noCommission
	case noTransaction
}

extension ExplorerTransactionManager {
	
	func estimateComission(tx: String) -> Observable<Decimal> {
		return Observable.create { (observer) -> Disposable in
			self.estimateCommission(for: tx) { (commission, error) in
				
				guard let commission = commission, nil == error else {
					observer.onError(error ?? ExplorerTransactionManagerErrorRx.noCommission)
					return
				}
				
				observer.onNext(commission)
				observer.onCompleted()
			}
			return Disposables.create()
		}
	}
	
	func estimateCoinSell(coinFrom: String, coinTo: String, value: Decimal) -> Observable<(Decimal, Decimal)> {
		return Observable.create { (observer) -> Disposable in
			self.estimateCoinSell(coinFrom: coinFrom, coinTo: coinTo, value: value, completion: { (res1, res2, error) in
				
				guard error == nil && res1 != nil && res2 != nil else {
					observer.onError(error ?? ExplorerTransactionManagerErrorRx.noCommission)
					return
				}
				
				observer.onNext((res1!, res2!))
				observer.onCompleted()
			})
			return Disposables.create()
		}
	}
	
	func count(address: String) -> Observable<Int> {
		return Observable.create { (observer) -> Disposable in
			self.count(for: address) { (count, error) in
				
				guard let count = count, nil == error else {
					observer.onError(error ?? ExplorerTransactionManagerErrorRx.noCount)
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
			self.minGas(completion: { (gas, error) in
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
				observer.onError(ExplorerTransactionManagerErrorRx.noTransaction)
			}
			return Disposables.create()
		}
	}

}
