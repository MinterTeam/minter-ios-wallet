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
import RxRelay

private let sessionAccessTokenKey = "AccessToken"
private let sessionRefreshTokenKey = "RefreshToken"
private let sessionUserKey = "User"
private let sessionPINAttemptNumberKey = "SessionPINAttemptNumberKey"

class Session {

	static let shared = Session()

	var isLoggedIn = BehaviorRelay<Bool>(value: false)

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

	var isLoading = BehaviorRelay<Bool>(value: true)
	var accounts = BehaviorRelay<[Account]>(value: [])
	var transactions = BehaviorRelay<[TransactionItem]>(value: [])
	var baseCoinBalances = Variable([String: Decimal]())
	var allBalances = Variable([String: [String: Decimal]]())
	var balances = Variable([String: Decimal]())
	var mainCoinBalance = Variable(Decimal(0.0))
	var totalMainCoinBalance = BehaviorSubject<Decimal>(value: 0.0)
	var totalUSDBalance = BehaviorSubject<Decimal>(value: 0.0)
	var delegatedBalance = BehaviorSubject<Decimal>(value: 0.0)
	var allDelegatedBalance = BehaviorSubject<[AddressDelegation]>(value: [AddressDelegation]())
	var accessToken = Variable<String?>(nil)
	var isPINRequired = BehaviorSubject<Bool>(value: PINManager.shared.isPINset)
	private var refreshToken = Variable<String?>(nil)
	var user = Variable<User?>(nil)
	var currentGasPrice = Variable<Int>(1)

	var allCoins = BehaviorRelay<[Coin]>(value: [])

	// MARK: -

	private init() {
		allBalances
			.asObservable()
			.subscribe(onNext: { [weak self] (val) in
				var newBalance = [String: Decimal]()
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
		.distinctUntilChanged({ (accToken, refreshToken) -> Bool in
			return (accToken.0 ?? "" == refreshToken.0 ?? "") && (accToken.1 ?? "" == refreshToken.1 ?? "")
		}).subscribe(onNext: { [weak self] (accToken, refreshToken) in
			self?.isLoggedIn.accept(accToken != nil && refreshToken != nil)
		}).disposed(by: disposeBag)

		accounts.asObservable().distinctUntilChanged().filter({ (accs) -> Bool in
			return accs.count > 0
		}).subscribe(onNext: { [weak self] (_) in
			self?.loadTransactions()
			self?.loadBalances()
			self?.loadDelegatedBalance()
		}).disposed(by: disposeBag)

		Observable.of(UIApplication.shared.rx.applicationDidBecomeActive.map {$0 as AnyObject},
									UIApplication.realAppDelegate()!.applicationOpenWithURL.asObservable().map {$0 as AnyObject }).merge()
			.subscribe(onNext: { [weak self] (_) in
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
			.subscribe(onNext: { [weak self] (_) in
				self?.lastBackgroundDate = Date()
			}).disposed(by: disposeBag)

		restore()
	}

	func setAccessToken(_ token: String) {
		secureStorage.set(token as NSString, forKey: sessionAccessTokenKey)
		self.accessToken.value = token
	}

	func setRefreshToken(_ token: String) {
		secureStorage.set(token as NSString, forKey: sessionRefreshTokenKey)
		self.refreshToken.value = token
	}

	func setPINAttempts(attempts: Int) {
		secureStorage.set(String(attempts).data(using: .utf8) ?? Data(),
											forKey: sessionPINAttemptNumberKey)
	}

	func getPINAttempts() -> Int {
		let attempts = secureStorage.object(forKey: sessionPINAttemptNumberKey) as? Data
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
		if let accessToken = secureStorage.object(forKey: sessionAccessTokenKey) as? String {
			self.accessToken.value = accessToken
		}

		if let refreshToken = secureStorage.object(forKey: sessionRefreshTokenKey) as? String {
			self.refreshToken.value = refreshToken
		}

		if let user = dataBaseStorage.objects(class: UserDataBaseModel.self)?.first as? UserDataBaseModel {
			self.user.value = User(dbModel: user)
		}

		AppSettingsManager.shared.restore()
	}

	func logout() {
		accessToken.value = nil
		refreshToken.value = nil
		secureStorage.removeAll()
		localStorage.removeAll()
		dataBaseStorage.removeAll()
		delegatedBalance.onNext(0.0)
		totalMainCoinBalance.onNext(0.0)
		totalUSDBalance.onNext(0.0)
		baseCoinBalances.value = [:]
		accounts.accept([])
		transactions.accept([])
		allBalances.value = [:]
		balances.value = [:]
		mainCoinBalance.value = 0.0
		user.value = nil
		isPINRequired.onNext(false)
	}

	// MARK: -

	func loadCoins() {
		ExplorerCoinManager.default.coins(term: "").map { (coins) -> [Coin] in
			return coins ?? []
		}.filter({ (coins) -> Bool in
			return coins.count > 0
		}).subscribe(onNext: { (coins) in
			self.allCoins.accept(coins.map({ (coin) -> Coin in
				if (coin.symbol ?? "") == Coin.baseCoin().symbol! {
					coin.reserveBalance = Decimal.greatestFiniteMagnitude
				}
				return coin
			}))
		}).disposed(by: disposeBag)
	}

	func loadAccounts() {
		self.isLoading.accept(true)
		syncer.isSyncing.asObservable().skip(1).filter({ (val) -> Bool in
			return val == false
		}).subscribe(onNext: { [weak self] (_) in
			self?.isLoading.accept(false)

			var accs = [Account]()
			accs = self?.accountManager.loadLocalAccounts() ?? []

			let accounts = accs.sorted(by: { (acc1, acc2) -> Bool in
				return (acc1.isMain && !acc2.isMain)
			})
			self?.accounts.accept(accounts)
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

		self.isLoading.accept(true)

		transactionManger.transactions { [weak self] (transactions, users, error) in
			self?.isLoadingTransaction = false
			self?.isLoading.accept(false)

			guard (self?.isLoggedIn.value ?? false) || (self?.accounts.value ?? []).count > 0 else {
				return
			}

			guard nil == error else {
				return
			}

			let txs = transactions?.map({ (transaction) -> TransactionItem in
				let item = TransactionItem()
				item.transaction = transaction

				let hasAddress = Session.shared.hasAddress(address: transaction.from ?? "")

				var key = transaction.from?.lowercased()

				if hasAddress, let to = transaction.data?.to {
					key = to.lowercased()
				}
				if let key = key, let usr = users?[key] {
					item.user = usr
				}
				return item
			}) ?? []
			self?.transactions.accept(txs)
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
			.delegations(address: addresses.first!)
			.subscribe(onNext: { [weak self] (delegation, total) in
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
		guard let address = accounts.value.map({ (account) -> String in
			return "Mx" + account.address.stripMinterHexPrefix()
		}).first else {
			return
		}

		addressManager.address(address: address, withSum: true) { [weak self] (response, err) in
			guard (self?.isLoggedIn.value ?? false) || (self?.accounts.value ?? []).count > 0 else {
				return
			}

			guard nil == err else {
				return
			}

			var newMainCoinBalance = Decimal(0.0)

			let address = response ?? [:]
			guard let ads = (address["address"] as? String)?.stripMinterHexPrefix(),
				let coins = address["balances"] as? [[String: Any]] else {
				return
			}

			if let totalBalanceBaseCoin = address["total_balance_sum"] as? String,
				let totalBalance = Decimal(string: totalBalanceBaseCoin) {
				self?.totalMainCoinBalance.onNext(totalBalance)
			}

			if let totalBalanceUSD = address["total_balance_sum_usd"] as? String,
				let totalBalance = Decimal(string: totalBalanceUSD) {
				self?.totalUSDBalance.onNext(totalBalance)
			}

			let baseCoinBalance = coins.filter({ (dict) -> Bool in
				return ((dict["coin"] as? String) ?? "").uppercased() == Coin.baseCoin().symbol!.uppercased()
			}).map({ (dict) -> Decimal in
				return Decimal(string: (dict["amount"] as? String) ?? "0.0") ?? 0.0
			}).reduce(0, +)

			self?.baseCoinBalances.value[ads] = baseCoinBalance

			newMainCoinBalance += baseCoinBalance

			var newAllBalances = self?.allBalances.value

			var blncs = [String: Decimal]()
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
			self?.mainCoinBalance.value = newMainCoinBalance
		}
	}

	func updateGas() {
		gateManager.minGasPrice { (gas, _) in
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

	func checkPin(_ pin: String,
								forChange: Bool = false,
								completion: ((Bool) -> ())?) {
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
