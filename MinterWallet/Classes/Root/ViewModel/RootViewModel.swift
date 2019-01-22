//
//  RootRootViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import Centrifuge
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
	
	var channel: String?
	
	var client: CentrifugeClient? = CentrifugeNew(MinterExplorerWebSocketURL, CentrifugeDefaultConfig())
	
	var isConnected: Bool = false {
		didSet {
			print("***********DID Connect/Disconnect************ \(isConnected == true)")
			if self.isConnected == true {
				self.subscribeAccountBalanceChange()
			}
			if isConnected {
//				reloadData()
			}
		}
	}
	
	var addressManager = ExplorerAddressManager.default
	
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
		
		Observable.combineLatest(UIApplication.shared.rx.applicationDidBecomeActive, Session.shared.accounts.asObservable(), Session.shared.isLoggedIn.asObservable()).distinctUntilChanged({ (val1, val2) -> Bool in
			return val1.1 == val2.1 || val1.2 == val2.2 || val1.1 == val2.1
		}).subscribe(onNext: { [weak self] (state, accounts, loggedIn) in
			
			let addresses = accounts.map({ (account) -> String in
				return "Mx" + account.address
			})
			
			guard addresses.count > 0 else {
				if self?.isConnected == true {
					try? self?.client?.disconnect()
				}
				self?.unsubscribeAccountBalanceChange(completed: {
					
				})
				return
			}
			
			self?.channel = addresses.first
			
			self?.connect(completion: {

			})
			
		}).disposed(by: disposeBag)
		
	}
	
	let connectHandler = CentrifugueConnectHandler()
	
	let disconnectHandler = CentrifugueDisconnectHandler()
	
	let messageHandler = CentrifugueMessageHandler()
	let publishHandler = CentrifuguePublishHandler()
	let errorHandler = CentrifugueErrorHandler()
	let subscribeErrorHandler = CentrifugueSubscribeErrorHandler()
	
	func connect(completion: (() -> ())?) {
		connectHandler.delegate = self
		disconnectHandler.delegate = self
		messageHandler.delegate = self
		
		client?.onConnect(connectHandler)
		client?.onDisconnect(disconnectHandler)
		client?.onMessage(messageHandler)
		client?.onError(errorHandler)
		
		do {
			try client?.connect()
		} catch {
			return
		}
	}
	
	var sub: CentrifugeSubscription?
	
	private func subscribeAccountBalanceChange() {
		guard self.isConnected == true, let cnl = self.channel else {
			return
		}
		print("***********Connecting to \(cnl) ************")
		do {
			sub = try self.client?.newSubscription(cnl)
		} catch {
			print("***********ON SUBSCRIBE ERROR************")
			return
		}
		
		
		sub?.onPublish(publishHandler)
		sub?.onSubscribeError(subscribeErrorHandler)
		do {
			try sub?.subscribe()
		} catch {
			print("***********ON SUBSCRIBE ERROR************")
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
		//		})
	}
	
	//MARK: -
	
	func reloadData() {
		Session.shared.loadBalances()
		Session.shared.loadTransactions()
	}

}



extension RootViewModel : CentrifugueConnectHandlerDelegate, CentrifugueDisconnectHandlerDelegate, CentrifuguePublishHandlerDelegate {
	
	//MARK: -
	
	func didConnect() {
		self.isConnected = true
	}
	
	func didDisconnect() {
		self.isConnected = false
	}
	
	func didPublish() {
		DispatchQueue.main.async { [weak self] in
			print("***********DID PUBLISH************")
			self?.reloadData()
		}
	}
	
}

//MARK: -

protocol CentrifugueConnectHandlerDelegate : class {
	func didConnect()
}

protocol CentrifugueDisconnectHandlerDelegate : class {
	func didDisconnect()
}

protocol CentrifuguePublishHandlerDelegate : class {
	func didPublish()
}

//MARK: -

class CentrifugueConnectHandler : NSObject, CentrifugeConnectHandlerProtocol {
	
	weak var delegate: CentrifugueConnectHandlerDelegate?
	
	func onConnect(_ p0: CentrifugeClient!, p1: CentrifugeConnectEvent!) {
		
		delegate?.didConnect()
	}
}

class CentrifugueDisconnectHandler : NSObject, CentrifugeDisconnectHandlerProtocol {
	
	weak var delegate: CentrifugueDisconnectHandlerDelegate?
	
	func onDisconnect(_ p0: CentrifugeClient!, p1: CentrifugeDisconnectEvent!) {
		delegate?.didDisconnect()
	}
}

class CentrifuguePublishHandler : NSObject, CentrifugePublishHandlerProtocol {
	
	weak var delegate: CentrifuguePublishHandlerDelegate?
	
	func onPublish(_ p0: CentrifugeSubscription!, p1: CentrifugePublishEvent!) {
		print("***********ON PUBLISH************")
		delegate?.didPublish()
	}
}

class CentrifugueMessageHandler : NSObject, CentrifugeMessageHandlerProtocol {
	
	weak var delegate: CentrifuguePublishHandlerDelegate?
	
	func onMessage(_ p0: CentrifugeClient!, p1: CentrifugeMessageEvent!) {
		print("***********ON MESSAGE************")
		delegate?.didPublish()
	}
}

class CentrifugueErrorHandler : NSObject, CentrifugeErrorHandlerProtocol {
	
	func onError(_ p0: CentrifugeClient!, p1: CentrifugeErrorEvent!) {
		print("***********ON ERROR************")
	}
}

class CentrifugueSubscribeErrorHandler : NSObject, CentrifugeSubscribeErrorHandlerProtocol {
	
	func onSubscribeError(_ p0: CentrifugeSubscription!, p1: CentrifugeSubscribeErrorEvent!) {
		print("***********ON SUBSCRIBE ERROR************")
	}
	
	
}
