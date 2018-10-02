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
import RxAppState


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
//			print("CHANNEL: " + (channel ?? "****"))
		}
	}
	
	var timestamp: Int?
	var token: String?
	
	var client: CentrifugeClient?
	var isConnected: Bool = false
	
	var addressManager = AddressManager.default

	override init() {
		super.init()
		
		SessionHelper.reloadAccounts()
		
		Session.shared.isLoggedIn.asObservable().filter({ (isLoggedIn) -> Bool in
			return isLoggedIn
		}).subscribe(onNext: { (isLoggedIn) in
			//show wallet
			SessionHelper.reloadAccounts()
			Session.shared.loadUser()
		}).disposed(by: disposeBag)
		
		Observable.combineLatest(UIApplication.shared.rx.applicationDidBecomeActive, Session.shared.accounts.asObservable()).distinctUntilChanged({ (val1, val2) -> Bool in
			return val1.1 == val2.1
		}).subscribe(onNext: { [weak self] (state, accounts) in
			
			let addresses = accounts.map({ (account) -> String in
				return "Mx" + account.address
			})
			
			guard addresses.count > 0 else {
				if self?.isConnected == true {
					self?.client?.disconnect()
				}
//				self?.unsubscribeAccountBalanceChange(completed: {
//
//				})
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
				
				self?.connect(completion: {
					if self?.isConnected == true {
						self?.subscribeAccountBalanceChange()
					}
				})
			})
			
		}).disposed(by: disposeBag)

	}
	
	func connect(completion: (() -> ())?) {
		
		guard let tkn = self.token, let tmstmp = self.timestamp else {
			return
		}
		
		let user = ""//String(Session.shared.user.value?.id ?? 0)
		let timestamp = String(tmstmp)
		let token = tkn
		
		let creds = CentrifugeCredentials(token: token, user: user, timestamp: timestamp)
		let url = MinterExplorerWebSocketURL
		client = Centrifuge.client(url: url, creds: creds, delegate: self)
		
		client?.connect { message, error in
			
			guard nil == error else {
				self.isConnected = false
				return
			}
			
			self.isConnected = true
			completion?()
			
		}
	}
	
	private func subscribeAccountBalanceChange() {
		guard self.isConnected == true, let cnl = self.channel else {
			return
		}
		
		self.client?.subscribe(toChannel: cnl, delegate: self, completion: { (mes, err) in
//			print(mes)
//			print(err)
		})

	}
	
	private func unsubscribeAccountBalanceChange(completed: (() -> ())?) {
		
		guard let cnl = self.channel else {
			completed?()
			return
		}
		
		self.client?.unsubscribe(fromChannel: cnl, completion: { (message, error) in

			defer {
				completed?()
			}
		})
	}

}



extension RootViewModel : CentrifugeClientDelegate, CentrifugeChannelDelegate {
	
	func client(_ client: CentrifugeClient, didReceiveRefreshMessage message: CentrifugeServerMessage) {
		self.isConnected = false
	}

	func client(_ client: CentrifugeClient, didDisconnectWithError error: Error) {
		self.isConnected = false
	}
	
	//MARK: -
	
	func client(_ client: CentrifugeClient, didReceiveMessageInChannel channel: String, message: CentrifugeServerMessage) {
		Session.shared.loadBalances()
		Session.shared.loadTransactions()
	}
	
	func client(_ client: CentrifugeClient, didReceiveJoinInChannel channel: String, message: CentrifugeServerMessage) {
		Session.shared.loadBalances()
		Session.shared.loadTransactions()
	}
	
	func client(_ client: CentrifugeClient, didReceiveLeaveInChannel channel: String, message: CentrifugeServerMessage) {
		Session.shared.loadBalances()
		Session.shared.loadTransactions()
	}
	
	func client(_ client: CentrifugeClient, didReceiveUnsubscribeInChannel channel: String, message: CentrifugeServerMessage) {
		Session.shared.loadBalances()
		Session.shared.loadTransactions()
	}
	
}
