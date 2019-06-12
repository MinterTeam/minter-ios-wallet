//
//  AddressManager+Rx.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/06/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterExplorer

extension ExplorerAddressManager {

	func delegations(address: String, page: Int = 1) -> Observable<([AddressDelegation]?, Decimal?)> {
		return Observable.create { (observer) -> Disposable in
			ExplorerAddressManager.default.delegations(address: address,
																								 page: page,
																								 limit: 50,
																								 completion: { (res, total, err) in
				guard err == nil else {
					observer.onError(err!)
					return
				}
				observer.onNext((res, total))
			})
			return Disposables.create()
		}
	}
}
