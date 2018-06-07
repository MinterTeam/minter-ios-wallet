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
import MinterExplorer


class Session {
	
	static let shared = Session()
	
	var isLoggedIn = Variable(false)
	
	private let accountManager = AccountManager()
	private let minterAccountManager = MinterCore.AccountManager.default
	private let transactionManager = MinterExplorer.TransactionManager.default
	
	private var disposeBag = DisposeBag()
	
	//MARK: -
	
	var accounts = Variable([Account]())
	
	var transactions = Variable([Transaction]())
	
	var allBalances = Variable([String : [String : Double]]())
	
	var balances = Variable([String : Double]())

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
	}
	
	//MARK: -
	
	func loadAccounts() {
		
		var accs = [Account]()
		accs = accountManager.loadLocalAccounts() ?? []
		
		if let remoteAccounts = accountManager.loadRemoteAccounts() {
			accs.append(contentsOf: remoteAccounts)
		}
		
		accounts.value = accs.sorted(by: { (acc1, acc2) -> Bool in
			return (acc1.isMain && !acc2.isMain)
		})
		
		accounts.asObservable().subscribe(onNext: { [weak self] (accounts) in
			self?.loadTransactions()
			self?.loadBalances()
		}).disposed(by: disposeBag)
	}
	
	func loadTransactions() {
		
		let addresses = accounts.value.map { (acc) -> String in
			return "Mx" + acc.address
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
