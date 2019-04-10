//
//  CoinManager+Rx.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 28/01/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterExplorer

enum ExplorerCoinManagerRxError : Error {
	case noCoin
}

extension ExplorerCoinManager {

	func coin(by term: String) -> Observable<Coin?> {
		return Observable.create { (observer) -> Disposable in
			self.coins(term: term) { (coins, error) in

				guard error == nil else {
					observer.onError(error!)
					return
				}
				if let coin = coins?.filter({ (coin) -> Bool in
					return coin.symbol?.lowercased() == term.lowercased()
				}).first {
					observer.onNext(coin)
				}
				else {
					observer.onNext(nil)
				}
				observer.onCompleted()
			}
			return Disposables.create()
		}
	}

	func coins(term: String) -> Observable<[Coin]?> {
		return Observable.create { (observer) -> Disposable in
			self.coins(term: term) { (coins, error) in
				
				guard error == nil else {
					observer.onError(error!)
					return
				}
				
				observer.onNext(coins)
				observer.onCompleted()
			}
			return Disposables.create()
		}
	}

}
