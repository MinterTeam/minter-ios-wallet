//
//  RootRootViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import CentrifugeiOS
import MinterCore
import MinterExplorer


class RootViewModel: BaseViewModel {
	
	private let session = Session.shared
	
	private let disposeBag = DisposeBag()

	var title: String {
		get {
			return "Root".localized()
		}
	}
	
	var channel: String? {
		didSet {
			print("CHANNEL: " + (channel ?? "****"))
		}
	}
	
	var timestamp: Int?
	var token: String?
	
	var client: CentrifugeClient?
	
	var addressManager = AddressManager.default

	override init() {
		super.init()
		
		SessionHelper.reloadAccounts()
		
		Session.shared.isLoggedIn.asObservable().distinctUntilChanged().subscribe(onNext: { /*[weak self]*/ (isLoggedIn) in
			if isLoggedIn {
				//show wallet
				SessionHelper.reloadAccounts()
				Session.shared.loadUser()
			}
		}).disposed(by: disposeBag)
		
		Session.shared.accounts.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (accounts) in
			
			let addresses = accounts.map({ (account) -> String in
				return "Mx" + account.address
			})
			
			guard addresses.count > 0 else {
				return
			}
			
			self?.addressManager.balanceChannel(addresses: addresses, completion: { (channel, token, timestamp, error) in
				
				guard nil == error else {
					return
				}
				
				guard (self?.channel ?? "") != (channel ?? "") else {
					return
				}
				
				self?.channel = channel
				self?.timestamp = timestamp
				self?.token = token
				
				self?.unsubscribeAccountBalanceChange() {
					
				}
				
				self?.subscribeAccountBalanceChange()
				
			})
			
		}).disposed(by: disposeBag)
		
		
	}
	
	private func subscribeAccountBalanceChange() {
		
		guard let cnl = self.channel, let tkn = self.token, let tmstmp = self.timestamp else {
			return
		}
		
		client?.disconnect()
		
		let user = ""//String(Session.shared.user.value?.id ?? 0)
		let timestamp = String(tmstmp)
		let token = tkn

		let creds = CentrifugeCredentials(token: token, user: user, timestamp: timestamp)
		let url = "ws://92.53.87.98:8000/connection/websocket"
		client = Centrifuge.client(url: url, creds: creds, delegate: self)

		client?.connect { message, error in

			guard nil == error else {
				return
			}

			self.client?.subscribe(toChannel: cnl, delegate: self, completion: { (message, error) in
				print(message)
				print(error)
			})
		}
	}
	
	private func unsubscribeAccountBalanceChange(completed: (() -> ())?) {
		
		guard let cnl = self.channel else {
			completed?()
			return
		}
		
//		self.client?.unsubscribe(fromChannel: cnl, completion: { (message, error) in
//
//			defer {
//				completed?()
//			}
//
//		})
	}

}



extension RootViewModel : CentrifugeClientDelegate, CentrifugeChannelDelegate {
	
	func client(_ client: CentrifugeClient, didReceiveRefreshMessage message: CentrifugeServerMessage) {
		
	}

	func client(_ client: CentrifugeClient, didDisconnectWithError error: Error) {
		
	}
	
	//MARK: -
	
	func client(_ client: CentrifugeClient, didReceiveMessageInChannel channel: String, message: CentrifugeServerMessage) {
		Session.shared.loadBalances()
	}
	
	func client(_ client: CentrifugeClient, didReceiveJoinInChannel channel: String, message: CentrifugeServerMessage) {
		Session.shared.loadBalances()
	}
	
	func client(_ client: CentrifugeClient, didReceiveLeaveInChannel channel: String, message: CentrifugeServerMessage) {
		Session.shared.loadBalances()
	}
	
	func client(_ client: CentrifugeClient, didReceiveUnsubscribeInChannel channel: String, message: CentrifugeServerMessage) {
		Session.shared.loadBalances()
	}
	
}
