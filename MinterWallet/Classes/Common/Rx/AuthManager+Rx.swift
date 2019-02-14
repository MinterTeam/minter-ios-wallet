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

enum AuthManagerErrorRx : Error {
	case noToken
	case wrongResponse
}

extension AuthManager {
	
	func login(username: String, password: String) -> Observable<(String?, String?, User?)> {
		return Observable<(String?, String?, User?)>.create { (observer) -> Disposable in
			self.login(username: username, password: password) { (accessToken, refreshToken, user, error) in
				
				guard nil == error && accessToken != nil && refreshToken != nil && user != nil else {
					observer.onError(error ?? AuthManagerErrorRx.noToken)
					return
				}
				
				observer.onNext((accessToken, refreshToken, user))
				observer.onCompleted()
			}
			return Disposables.create()
		}
	}
	
	func isTaken(username: String) -> Observable<Bool> {
		return Observable<Bool>.create { (observer) -> Disposable in
			self.isTaken(username: username, completion: { (isTaken, error) in
				guard nil == error && isTaken != nil else {
					observer.onError(error ?? AuthManagerErrorRx.wrongResponse)
					return
				}
				
				observer.onNext(isTaken!)
				observer.onCompleted()
			})
			return Disposables.create()
		}
	}
}
