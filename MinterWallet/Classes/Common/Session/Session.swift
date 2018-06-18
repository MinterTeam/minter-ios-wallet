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
	
	private var disposeBag = DisposeBag()
	
	private let secureStorage = SecureStorage()
	private let localStorage = LocalStorage()
	private let dataBaseStorage = RealmDatabaseStorage.shared
	
	//MARK: -
	
	var accounts = Variable([Account]())
	
	var transactions = Variable([Transaction]())
	
	var allBalances = Variable([String : [String : Double]]())
	
	var balances = Variable([String : Double]())
	
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
	
	var user: User?

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
		self.user = user
		
		let dbObject = UserDataBaseModel()
		dbObject.substitute(with: user)
		
		dataBaseStorage.add(object: dbObject)
	}
	
	func restore() {
		if let accessToken = secureStorage.object(forKey: SessionAccessTokenKey) as? String {
			self.accessToken = accessToken
		}
		
		if let refreshToken = secureStorage.object(forKey: SessionRefreshTokenKey) as? String {
			self.refreshToken = refreshToken
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
		
		transactionManager.transactions(addresses: addresses, completion: { [weak self] (trs, error) in
			guard nil == error else {
				return
			}
			
			self?.transactions.value = trs ?? []
		})
	}
	
	func loadBalances() {

		accounts.value.forEach { (account) in
			minterAccountManager.balance(address: account.address, with: { [weak self] (res, error) in
				guard nil == error else {
					return
				}

				var newAllBalances = self?.allBalances.value
				
				if let balance = res as? [String : String] {
					newAllBalances?[account.address] = balance.mapValues({ (val) -> Double in
						return (Double(val) ?? 0) / TransactionCoinFactor
					})
				}
				
				self?.allBalances.value = newAllBalances ?? [:]
			})
		}
	}

}
