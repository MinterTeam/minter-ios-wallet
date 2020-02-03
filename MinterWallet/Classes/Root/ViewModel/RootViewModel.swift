//
//  RootRootViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import SwiftCentrifuge
import MinterCore
import MinterExplorer
import RxAppState

class RootViewModel: BaseViewModel, ViewModelProtocol {

	// MARK: -

	struct Input {
		var pin: AnyObserver<String>
		var biometricsSucceed: AnyObserver<Bool>
		var proceedURL: AnyObserver<URL?>
		var didOpenURL: AnyObserver<URL?>
	}
	struct Output {
		var shouldPresentPIN: Observable<Bool>
		var shouldGoNextStep: Observable<Bool>
		var openURL: Observable<URL?>
		var viewControllers: () -> ([UIViewController])
	}
	struct Dependency {}
	var input: RootViewModel.Input!
	var output: RootViewModel.Output!
	var dependency: RootViewModel.Dependency!

	// MARK: -

	private var pinCodeSubject: PublishSubject<String> = PublishSubject()
	private var goNextStepSubject: PublishSubject<Bool> = PublishSubject()
	private var biometricsSucceedSubject: PublishSubject<Bool> = PublishSubject()
	private var proceedURLSubject: PublishSubject<URL?> = PublishSubject()
	private var urlToProceedObservable: Observable<URL?> {
		return Observable
			.combineLatest(shouldPresent.asObservable(),
										 proceedURLSubject.asObservable())
			.filter({ (val) -> Bool in
				return !val.0
			}).map { (val) -> URL? in
				return val.1
			}
	}
	private var didOpenURLSubject = PublishSubject<URL?>()

	// MARK: -

	var channel: String?
	var client: CentrifugeClient?
	var isConnected: Bool = false {
		didSet {
			if self.isConnected == true && !oldValue {
				self.subscribeAccountBalanceChange()
			}
		}
	}

	var addressManager = ExplorerAddressManager.default

	var shouldPresent: Observable<Bool> {
		return Session.shared.isPINRequired.asObservable()
	}

	override init() {
		super.init()

		input = Input(pin: pinCodeSubject.asObserver(),
									biometricsSucceed: biometricsSucceedSubject.asObserver(),
									proceedURL: proceedURLSubject.asObserver(),
									didOpenURL: didOpenURLSubject.asObserver())
		output = Output(shouldPresentPIN: shouldPresent,
										shouldGoNextStep: goNextStepSubject.asObservable(),
										openURL: urlToProceedObservable.asObservable(),
										viewControllers: {
											self.tabbarViewControllers()
										})

		Session
			.shared
			.isLoggedIn
			.asObservable()
			.filter({ (isLoggedIn) -> Bool in
				return isLoggedIn
			}).subscribe(onNext: { (isLoggedIn) in
			//show wallet
				SessionHelper.reloadAccounts()
				Session.shared.loadUser()
			}).disposed(by: disposeBag)

		Session.shared.updateGas()

		pinCodeSubject.asObservable().subscribe(onNext: { [weak self] (val) in
			if PINManager.shared.checkPIN(code: val) {
				Session.shared.isPINRequired.onNext(false)
				self?.goNextStepSubject.onNext(true)
			}
		}).disposed(by: disposeBag)

		Session.shared.isPINRequired.subscribe(onNext: { [weak self] (val) in
			self?.goNextStepSubject.onNext(true)
		}).disposed(by: disposeBag)

		Observable.combineLatest(UIApplication.shared.rx.applicationDidBecomeActive,
														 Session.shared.accounts.asObservable(),
														 Session.shared.isLoggedIn.asObservable())
			.distinctUntilChanged({ (val1, val2) -> Bool in
			return val1.1 == val2.1 && val1.2 == val2.2
		}).filter({ (val) -> Bool in
			let accounts = val.1
			let loggedIn = val.2
			return loggedIn || accounts.count > 0
		}).subscribe(onNext: { [weak self] (state, accounts, loggedIn) in
			let addresses = accounts.map({ (account) -> String in
				return "Mx" + account.address
			})

			guard addresses.count > 0 else {
				if self?.isConnected == true {
					self?.client?.disconnect()
				}
				self?.unsubscribeAccountBalanceChange(completed: {})
				return
			}
			self?.channel = addresses.first
			self?.connect(completion: {})
		}).disposed(by: disposeBag)

		didOpenURLSubject.subscribe(onNext: { [weak self] (url) in
			self?.proceedURLSubject.onNext(nil)
		}).disposed(by: disposeBag)
	}

	func didLoad() {
		SessionHelper.reloadAccounts()
	}

	func connect(completion: (() -> ())?) {
		if nil == client {
			let config = CentrifugeClientConfig()
			client = CentrifugeClient(url: MinterExplorerWebSocketURL!.absoluteURL.absoluteString + "?format=protobuf",
																config: config,
																delegate: self)
		}
		self.client?.connect()
	}

	var sub: CentrifugeSubscription?

	private func subscribeAccountBalanceChange() {
		guard self.isConnected == true, let cnl = self.channel else {
			return
		}
		do {
			let sub = try client?.newSubscription(channel: cnl, delegate: self)
			sub?.subscribe()
		} catch {
			print("Can not create subscription: \(error)")
		}
	}

	private func unsubscribeAccountBalanceChange(completed: (() -> ())?) {
		guard self.channel != nil else {
			completed?()
			return
		}
	}

	// MARK: -

	func reloadData() {
		Session.shared.loadBalances()
		Session.shared.loadTransactions()
	}

	func tabbarViewControllers() -> [UIViewController] {
		var vcs = [UIViewController]()
		let coinVM = CoinsViewModel()
		if let coinVC = CoinsRouter.coinsViewController(viewModel: coinVM) {
			vcs.append(coinVC)
		}
		let sendVM = SendViewModel(dependency: SendViewModel.Dependency())
		if let sendVC = SendRouter.sendViewController(viewModel: sendVM) {
			vcs.append(sendVC)
		}

    let receiveVM = ReceiveViewModel(dependency: ReceiveViewModel.Dependency(accounts: Session.shared.accounts.asObservable()))
		if let receiveVC = ReceiveRouter.receiveViewController(viewModel: receiveVM) {
			vcs.append(receiveVC)
		}
		let settingsVM = SettingsViewModel()
		if let settingsVC = SettingsRouter.settingsViewController(viewModel: settingsVM) {
			vcs.append(settingsVC)
		}
		return vcs
	}
}

extension RootViewModel: CentrifugeClientDelegate, CentrifugeSubscriptionDelegate {

	// MARK: -

	func onConnect(_ client: CentrifugeClient, _ event: CentrifugeConnectEvent) {
		self.isConnected = true
	}

	func onDisconnect(_ client: CentrifugeClient, _ event: CentrifugeDisconnectEvent) {
		self.isConnected = false
	}

	func onPublish(_ subscription: CentrifugeSubscription, _ event: CentrifugePublishEvent) {
		self.reloadData()
	}
}
