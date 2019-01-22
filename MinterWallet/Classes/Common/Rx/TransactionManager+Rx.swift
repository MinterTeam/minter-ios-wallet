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


extension ExplorerTransactionManager {
	
	func count(address: String) -> Observable<Decimal> {
		return Observable.create { (observer) -> Disposable in
			self.count(for: address) { (count, error) in
				
				guard nil == error && count != nil else {
					observer.onError(error!)
					return
				}
				observer.onNext(count!)
			}
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
			})
			
		}
	}
	
}
