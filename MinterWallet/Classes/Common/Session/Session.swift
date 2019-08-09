//
//  Session.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 15/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterMy
import MinterExplorer
import RxAppState

fileprivate let SessionAccessTokenKey = "AccessToken"
fileprivate let SessionRefreshTokenKey = "RefreshToken"
fileprivate let SessionUserKey = "User"
fileprivate let SessionPINAttemptNumberKey = "SessionPINAttemptNumberKey"

class Session {

	static let shared = Session()

	var isLoggedIn = Variable(false)

	private let accountManager = AccountManager()
	private let gateManager = GateManager.shared
	private let minterAccountManager = MinterCore.AccountManager.default
	private let transactionManager = MinterExplorer.ExplorerTransactionManager.default
	private let addressManager = MinterExplorer.ExplorerAddressManager.default
	private var profileManager: MinterMy.ProfileManager?
	private let transactionManger = WalletTransactionManager()
	private let syncer = SessionAddressSyncer()

	private var disposeBag = DisposeBag()

	private let secureStorage = SecureStorage()
	private let localStorage = LocalStorage()
	private let dataBaseStorage = RealmDatabaseStorage.shared
	
	private var lastBackgroundDate: Date?

	// MARK: -

	var isLoading = Variable(true)
	var accounts = Variable([Account]())
	var transactions = Variable([TransactionItem]())
	var baseCoinBalances = Variable([String: Decimal]())
	var allBalances = Variable([String: [String: Decimal]]())
	var balances = Variable([String: Decimal]())
	var mainCoinBalance = Variable(Decimal(0.0))
	var delegatedBalance = BehaviorSubject<Decimal>(value: 0.0)
	var allDelegatedBalance = BehaviorSubject<[AddressDelegation]>(value: [AddressDelegation]())
	var accessToken = Variable<String?>(nil)
	
	var isPINRequired = BehaviorSubject<Bool>(value: PINManager.shared.isPINset)

	private var refreshToken = Variable<String?>(nil)

	var user = Variable<User?>(nil)

	var currentGasPrice = Variable<Int>(1)

	// MARK: -

	private init() {

		_ = self.allBalances.asObservable().subscribe(onNext: { [weak self] (val) in
			var newBalance = [String : Decimal]()

			val.values.forEach { (adr) in
				adr.keys.forEach({ (key) in
					if nil == newBalance[key] {
						newBalance[key] = 0.0
					}
					newBalance[key]! += (adr[key] ?? 0.0)
				})
			}

			self?.balances.value = newBalance
		}).disposed(by: disposeBag)

		Observable.combineLatest(self.accessToken.asObservable(),
														 self.refreshToken.asObservable())
		.distinctUntilChanged({ (a, b) -> Bool in
			return (a.0 ?? "" == b.0 ?? "") && (a.1 ?? "" == b.1 ?? "")
		}).subscribe(onNext: { [weak self] (at, rt) in
			self?.isLoggedIn.value = at != nil && rt != nil
		}).disposed(by: disposeBag)

		accounts.asObservable().distinctUntilChanged().filter({ (accs) -> Bool in
			return accs.count > 0
		}).subscribe(onNext: { [weak self] (accounts) in
			self?.loadTransactions()
			self?.loadBalances()
			self?.loadDelegatedBalance()
		}).disposed(by: disposeBag)

		UIApplication.shared.rx.applicationDidBecomeActive
			.subscribe(onNext: { [weak self] (state) in
			if let backgroundDate = self?.lastBackgroundDate, PINManager.shared.isPINset {
				if backgroundDate.timeIntervalSinceNow < -PINRequiredMinimumSeconds {
					self?.isPINRequired.onNext(true)
				}
			}
			self?.lastBackgroundDate = nil
			self?.loadTransactions()
			self?.loadBalances()
			self?.loadDelegatedBalance()
		}).disposed(by: disposeBag)
		
		UIApplication.shared.rx.applicationDidEnterBackground
			.subscribe(onNext: { [weak self] (state) in
				self?.lastBackgroundDate = Date()
			}).disposed(by: disposeBag)

		restore()
	}

	func setAccessToken(_ token: String) {
		secureStorage.set(token as NSString, forKey: SessionAccessTokenKey)
		self.accessToken.value = token
	}

	func setRefreshToken(_ token: String) {
		secureStorage.set(token as NSString, forKey: SessionRefreshTokenKey)
		self.refreshToken.value = token
	}

	func setPINAttempts(attempts: Int) {

		secureStorage.set(String(attempts).data(using: .utf8) ?? Data(),
											forKey: SessionPINAttemptNumberKey)
	}

	func getPINAttempts() -> Int {
		let attempts = secureStorage.object(forKey: SessionPINAttemptNumberKey) as? Data
		let str = String(data: attempts ?? Data(), encoding: .utf8) ?? ""
		return Int(str) ?? 0
	}

	func setUser(_ user: User) {
		self.user.value = user
		saveUser(user: user)
	}

	func saveUser(user: User) {
		guard let res = dataBaseStorage.objects(class: UserDataBaseModel.self)?.first as? UserDataBaseModel else {
			let dbObject = UserDataBaseModel()
			dbObject.substitute(with: user)

			dataBaseStorage.add(object: dbObject)
			return
		}

		_ = dataBaseStorage.objects(class: UserDataBaseModel.self) as? [UserDataBaseModel]

		dataBaseStorage.update {
			res.substitute(with: user)
		}
	}

	func restore() {
		if let accessToken = secureStorage.object(forKey: SessionAccessTokenKey) as? String {
			self.accessToken.value = accessToken
		}

		if let refreshToken = secureStorage.object(forKey: SessionRefreshTokenKey) as? String {
			self.refreshToken.value = refreshToken
		}

		if let user = dataBaseStorage.objects(class: UserDataBaseModel.self)?.first as? UserDataBaseModel {
			self.user.value = User(dbModel: user)
		} else {
			//retrive user if doesn't exist?
		}

		AppSettingsManager.shared.restore()
	}

	func logout() {

		accessToken.value = nil
		refreshToken.value = nil

		secureStorage.removeAll()
		localStorage.removeAll()
		dataBaseStorage.removeAll()

		baseCoinBalances.value = [:]
		accounts.value = []
		transactions.value = []
		allBalances.value = [:]
		balances.value = [:]
		mainCoinBalance.value = 0.0
		user.value = nil
		
		isPINRequired.onNext(false)
		
	}

	// MARK: -

	func loadAccounts() {
		self.isLoading.value = true
		syncer.isSyncing.asObservable().skip(1).filter({ (val) -> Bool in
			return val == false
		}).subscribe(onNext: { [weak self] (val) in

			self?.isLoading.value = false

			var accs = [Account]()
			accs = self?.accountManager.loadLocalAccounts() ?? []

			self?.accounts.value = accs.sorted(by: { (acc1, acc2) -> Bool in
				return (acc1.isMain && !acc2.isMain)
			})
		}).disposed(by: disposeBag)

		syncer.startSync()
	}

	var isLoadingTransaction = false

	func loadTransactions() {

		if isLoadingTransaction {
			return
		}
		isLoadingTransaction = true

		let addresses = accounts.value.map { (acc) -> String in
			return "Mx" + acc.address
		}

		guard addresses.count > 0 else {
			isLoadingTransaction = false
			return
		}

		//TODO: move to helper

		self.isLoading.value = true

		transactionManger.transactions { [weak self] (transactions, users, error) in
			self?.isLoadingTransaction = false
			self?.isLoading.value = false

			guard (self?.isLoggedIn.value ?? false) || (self?.accounts.value ?? []).count > 0 else {
				return
			}

			guard nil == error else {
				return
			}

			self?.transactions.value = transactions?.map({ (transaction) -> TransactionItem in
				let item = TransactionItem()
				item.transaction = transaction

				let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
					account.address.stripMinterHexPrefix().lowercased() == transaction.from?.stripMinterHexPrefix().lowercased()
				})

				var key = transaction.from?.lowercased()

				if hasAddress, let to = transaction.data?.to {
					key = to.lowercased()
				}
				if let key = key, let usr = users?[key] {
					item.user = usr
				}
				return item
			}) ?? []

		}
	}

	func loadDelegatedBalance() {
		let addresses = accounts.value.map({ (account) -> String in
			return "Mx" + account.address.stripMinterHexPrefix()
		})

		guard addresses.count > 0 else {
			return
		}

		ExplorerAddressManager.default
			.delegations(address: addresses.first!).subscribe(onNext: { [weak self] (delegation, total) in
				self?.allDelegatedBalance.onNext(delegation ?? [])
				if total != nil {
					self?.delegatedBalance.onNext(total ?? 0.0)
				} else {
					let delegated = delegation?.reduce(0) { $0 + ($1.bipValue ?? 0.0) }
					self?.delegatedBalance.onNext(delegated ?? 0.0)
				}
			}).disposed(by: disposeBag)
	}

	func loadBalances() {
		
		let addresses = accounts.value.map({ (account) -> String in
			return "Mx" + account.address.stripMinterHexPrefix()
		})
		
		guard addresses.count > 0 else {
			return
		}
		
		addressManager.addresses(addresses: addresses) { [weak self] (response, err) in
			
			guard (self?.isLoggedIn.value ?? false) || (self?.accounts.value ?? []).count > 0 else {
				return
			}
			
			guard nil == err else {
				return
			}
			
			var newMainCoinBalance = Decimal(0.0)
			
			response?.forEach({ (address) in
				
				guard let ads = (address["address"] as? String)?.stripMinterHexPrefix(), let coins = address["balances"] as? [[String : Any]] else {
					return
				}
				
				let baseCoinBalance = coins.filter({ (dict) -> Bool in
					return ((dict["coin"] as? String) ?? "").uppercased() == Coin.baseCoin().symbol!.uppercased()
				}).map({ (dict) -> Decimal in
					return Decimal(string: (dict["amount"] as? String) ?? "0.0") ?? 0.0
				}).reduce(0, +)
				
				self?.baseCoinBalances.value[ads] = baseCoinBalance
				
				newMainCoinBalance += baseCoinBalance
				
				var newAllBalances = self?.allBalances.value
				
				var blncs = [String : Decimal]()
				if let defaultCoin = Coin.baseCoin().symbol {
					blncs[defaultCoin] = 0.0
				}
				coins.forEach({ (dict) in
					if let key = dict["coin"] as? String {
						let amnt = Decimal(string: (dict["amount"] as? String) ?? "0.0") ?? 0.0
						blncs[key.uppercased()] = amnt
					}
				})
				
				newAllBalances?[ads] = blncs
				
				self?.allBalances.value = newAllBalances ?? [:]
			})
			
			self?.mainCoinBalance.value = newMainCoinBalance
		}
	}
	
	func updateGas() {
		gateManager.minGasPrice { (gas, err) in
			if let gas = gas {
				self.currentGasPrice.value = gas
			}
		}
	}
	
	func loadUser() {
		
		guard let client = APIClient.withAuthentication() else {
			return
		}
		
		if nil == profileManager {
			profileManager = ProfileManager(httpClient: client)
		}
		profileManager?.httpClient = client
		
		profileManager?.profile(completion: { [weak self] (user, err) in
			guard nil == err else {
				return
			}
			
			if let user = user {
				self?.user.value = user
				self?.saveUser(user: user)
			}
		})
	}

}

extension Session {

	func checkPin(_ pin: String, forChange: Bool = false, completion: ((Bool) -> ())?) {
		let pinAttempts = self.getPINAttempts()
		if pinAttempts >= PINMaxAttempts {
			self.logout()
		} else {
			self.setPINAttempts(attempts: pinAttempts+1)
		}

		let check = PINManager.shared.checkPIN(code: pin)
		if check {
			self.setPINAttempts(attempts: 0)
			if !forChange {
				self.isPINRequired.onNext(false)
			}
		}
		completion?(check)
	}

}
