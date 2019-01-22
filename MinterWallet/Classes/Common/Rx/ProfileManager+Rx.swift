//
//  ProfileManager+Rx.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/01/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterMy



extension ProfileManager {
	
	func updateProfile(user: User) -> Observable<Bool> {
		return Observable.create{ (observer) -> Disposable in
			self.updateProfile(user: user) { (result, error) in
				
				defer {
//					observer.onCompleted()
				}
				
				guard nil == error && result != nil else {
					observer.onError(error!)
					return
				}
				
				observer.onNext(result!)
			}
			return Disposables.create()
		}
	}
}
