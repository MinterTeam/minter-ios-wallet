//
//  RootRootViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import CentrifugeiOS


class RootViewModel: BaseViewModel {
	
	private let session = Session.shared
	
	private let disposeBag = DisposeBag()

	var title: String {
		get {
			return "Root".localized()
		}
	}
	
	var client: CentrifugeClient?

	override init() {
		super.init()
		
//		let user = "1"
//		let secret = "0bd38df-69d2-4f76-99b0-f48f8c028f79"
//		let timestamp = "1530545035"//"\(Int(Date().timeIntervalSince1970))"
//		let token = "9b6fa42b8c1f328800c6dd325af0640efc2294ac446732fe9f71161e90383eca"//Centrifuge.createToken(string: user + "\(timestamp)", key: secret)
		
//		let creds = CentrifugeCredentials(token: token, user: user, timestamp: timestamp)
//		let url = "http://92.53.87.98:8000/connection/websocket"
//		client = Centrifuge.client(url: url, creds: creds, delegate: self)
		
//		client?.connect { message, error in
//
//			print(message)
//			print(error)
//
//
//			self.client?.subscribe(toChannel: "test", delegate: self, completion: { (message, error) in
//				print(message)
//				print(error)
//			})
//
//
//		}
		
		

		
		SessionHelper.reloadAccounts()
		
		Session.shared.isLoggedIn.asObservable().distinctUntilChanged().subscribe(onNext: { /*[weak self]*/ (isLoggedIn) in
			if isLoggedIn {
				//show wallet
				SessionHelper.reloadAccounts()
				Session.shared.loadUser()
			}
			else {
				
//				self.client?.unsubscribe(fromChannel: "mxa93163fdf10724dc4785ff5cbfb9ac0b5949409f", completion: { (message, error) in
//
//				})
				
				//show login/register
//				if let rootVC = UIViewController.stars_topMostController() as? RootViewController {
//					let vc = Storyboards.Main.instantiateInitialViewController()
//
//					rootVC.showViewControllerWith(vc, usingAnimation: .up) {
//
//					}
//				}
				
			}
		}).disposed(by: disposeBag)
		
		
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
		
	}
	
	func client(_ client: CentrifugeClient, didReceiveLeaveInChannel channel: String, message: CentrifugeServerMessage) {
		
	}
	
	func client(_ client: CentrifugeClient, didReceiveUnsubscribeInChannel channel: String, message: CentrifugeServerMessage) {
		
	}
	
}
