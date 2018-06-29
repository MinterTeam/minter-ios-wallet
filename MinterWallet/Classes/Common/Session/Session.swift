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

fileprivate let SessionAccessTokenKey = "AccessToken"
fileprivate let SessionRefreshTokenKey = "RefreshToken"
fileprivate let SessionUserKey = "User"


class Session {
	
	static let shared = Session()
	
	var isLoggedIn = Variable(false)
	
	private let accountManager = AccountManager()
	private let minterAccountManager = MinterCore.AccountManager.default
	private let transactionManager = MinterExplorer.TransactionManager.default
	private let addressManager = MinterExplorer.AddressManager.default
	private var profileManager: MinterMy.ProfileManager?
	
	private var disposeBag = DisposeBag()
	
	private let secureStorage = SecureStorage()
	private let localStorage = LocalStorage()
	private let dataBaseStorage = RealmDatabaseStorage.shared
	
	//MARK: -
	
	var accounts = Variable([Account]())
	
	var transactions = Variable([TransactionItem]())
	
	var allBalances = Variable([String : [String : Double]]())
	
	var balances = Variable([String : Double]())
	
	var mainCoinBalance = Variable(0.0)
	
	var accessToken: String? {
		didSet {
			checkLogin()
		}
	}
	
	private var refreshToken: String? {
		didSet {
			checkLogin()
		}
	}
	
	var user = Variable<User?>(nil)

	//MARK: -
	
	private init() {
		_ = self.allBalances.asObservable().subscribe(onNext: { [weak self] (val) in
			
			var newBalance = [String : Double]()
			
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
		
		accounts.asObservable().filter({ (accs) -> Bool in
			return accs.count > 0
		}).subscribe(onNext: { [weak self] (accounts) in
			self?.loadTransactions()
			self?.loadBalances()
		}).disposed(by: disposeBag)
		
		restore()
		
	}
	
	func setAccessToken(_ token: String) {
		secureStorage.set(token as NSString, forKey: SessionAccessTokenKey)
		self.accessToken = token
	}
	
	func setRefreshToken(_ token: String) {
		secureStorage.set(token as NSString, forKey: SessionRefreshTokenKey)
		self.refreshToken = token
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
			self.accessToken = accessToken
		}
		
		if let refreshToken = secureStorage.object(forKey: SessionRefreshTokenKey) as? String {
			self.refreshToken = refreshToken
		}
		
		if let user = dataBaseStorage.objects(class: UserDataBaseModel.self)?.first as? UserDataBaseModel {
			self.user.value = User(dbModel: user)
		}
		else {
			//retreive user if doesn't exist?
		}
		
		
		checkLogin()
	}
	
	func logout() {
		
		accessToken = nil
		refreshToken = nil
		
		secureStorage.removeAll()
		localStorage.removeAll()
		dataBaseStorage.removeAll()
		
		accounts.value = []
		transactions.value = []
		allBalances.value = [:]
		balances.value = [:]
		mainCoinBalance.value = 0.0
		user.value = nil
		
		checkLogin()
	}
	
	private func checkLogin() {
		if nil != self.accessToken && nil != self.refreshToken {
			self.isLoggedIn.value = true
		}
		else {
			self.isLoggedIn.value = false
		}
	}
	
	//MARK: -
	
	let syncer = SessionAddressSyncer()
	
	func loadAccounts() {
		
		syncer.isSyncing.asObservable().skip(1).filter({ (val) -> Bool in
			return val == false
		}).subscribe(onNext: { (val) in
			var accs = [Account]()
			accs = self.accountManager.loadLocalAccounts() ?? []
			
			self.accounts.value = accs.sorted(by: { (acc1, acc2) -> Bool in
				return (acc1.isMain && !acc2.isMain)
			})
		}).disposed(by: disposeBag)
		
		syncer.startSync()

	}
	
	func loadTransactions() {
		
		let addresses = accounts.value.map { (acc) -> String in
			return "Mx" + acc.address
		}
		
		guard addresses.count > 0 else {
			return
		}
		
		//TODO: move to helper
		let transactionManger1 = TransactionManager()
		transactionManger1.transactions { [weak self] (transactions, users, error) in
			
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
				
				if hasAddress, let to = transaction.to {
					key = to.lowercased()
				}
				if let key = key, let usr = users?[key] {
					item.user = usr
				}
				return item
			}) ?? []
			
		}
		
	}
	
	func loadBalances() {
		
		addressManager.addresses(addresses: accounts.value.map({ (account) -> String in
			return "Mx" + account.address
		})) { [weak self] (response, err) in
			
			guard nil == err else {
				return
			}
			
			var newMainCoinBalance = 0.0
			
			response?.forEach({ (address) in
				
				guard let ads = (address["address"] as? String)?.stripMinterHexPrefix(), let coins = address["coins"] as? [[String : Any]] else {
					return
				}
				
				newMainCoinBalance += coins.map({ (dict) -> Double in
					return (dict["baseCoinAmount"] as? Double) ?? 0.0
				}).reduce(0, +)
				
				var newAllBalances = self?.allBalances.value
				
				var blncs = [String : Double]()
				if let defaultCoin = Coin.defaultCoin().symbol {
					blncs[defaultCoin] = 0.0
				}
				coins.forEach({ (dict) in
					if let key = dict["coin"] as? String {
						blncs[key.uppercased()] = dict["amount"] as? Double ?? 0.0
					}
				})
				
				newAllBalances?[ads] = blncs
				
				self?.allBalances.value = newAllBalances ?? [:]
			})
			
			self?.mainCoinBalance.value = newMainCoinBalance
		}
		
//		accounts.value.forEach { (account) in
//			minterAccountManager.balance(address: account.address, with: { [weak self] (res, error) in
//				guard nil == error else {
//					return
//				}
//
//				var newAllBalances = self?.allBalances.value
//
//				if let balance = res as? [String : String] {
//					newAllBalances?[account.address] = balance.mapValues({ (val) -> Double in
//						return (Double(val) ?? 0) / TransactionCoinFactor
//					})
//				}
//
//				self?.allBalances.value = newAllBalances ?? [:]
//			})
//		}
	}
	
	func loadUser() {
		
		guard let client = APIClient.withAuthentication() else {
			return
		}
		
		if nil == profileManager {
			profileManager = ProfileManager(httpClient: client)
		}
		
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
