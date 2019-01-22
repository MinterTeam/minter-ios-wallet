//
//  AuthManager+Rx.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/01/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterMy
import RxSwift


extension AuthManager {
	
	func login(username: String, password: String) -> Observable<(String?, String?, User?)> {
		return Observable<(String?, String?, User?)>.create { (observer) -> Disposable in
			self.login(username: username, password: password) { (accessToken, refreshToken, user, error) in
				
				defer {
					observer.onCompleted()
				}
				
				guard nil == error && accessToken != nil && refreshToken != nil && user != nil else {
					observer.onError(error!)
					return
				}
				
				observer.onNext((accessToken, refreshToken, user))
			}
			return Disposables.create()
		}
	}
}
