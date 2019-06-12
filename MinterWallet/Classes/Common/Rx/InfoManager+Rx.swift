//
//  InfoManager+Rx.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 22/01/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterMy
import RxSwift

enum InfoManagerErrorRx : Error {
	case noAddress
}

extension InfoManager {

	func address(term: String) -> Observable<String> {
		return Observable.create { (observer) -> Disposable in

			func completion(address: String?, user: User?, error: Error?) {
				guard error == nil && address != nil else {
					observer.onError(error ?? InfoManagerErrorRx.noAddress)
					return
				}
				observer.onNext(address!)
				return
			}

			if term.isValidEmail() {
				self.address(email: term, completion: { (address, user, error) in
					completion(address: address, user: user, error: error)
				})
			} else {
				self.address(username: term, completion: { (address, user, error) in
					completion(address: address, user: user, error: error)
				})
			}
			return Disposables.create()
		}
	}
}
