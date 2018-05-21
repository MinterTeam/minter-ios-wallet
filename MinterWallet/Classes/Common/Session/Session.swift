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


class Session {
	
	static let shared = Session()
	
	var isLoggedIn = Variable(false)
	
	private let accountManager = AccountManager()
	private let minterAccountManager = MinterCore.AccountManager.default
	
	private var disposeBag = DisposeBag()
	
	//MARK: -
	
	var accounts = Variable([Account]())
	
	var transactions: [Transaction] = []
	
	var balances: [Any] = []
	
	private let transactionManager = TransactionManager.default
	
	private init() {

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
		
		transactions = []
		
		accounts.value.forEach { (account) in
			transactionManager.transactions(address: account.address, query: "tx.from=\"" + account.address + "\"", completion: { [weak self] (trns, error) in
				guard nil == error else {
					return
				}
				
				self?.transactions.append(contentsOf: trns)
			})
			transactionManager.transactions(address: account.address, query: "tx.to=\"" + account.address + "\"", completion: { [weak self] (trns, error) in
				guard nil == error else {
					return
				}
				
				self?.transactions.append(contentsOf: trns)
			})
		}
	}
	
	func loadBalances() {
		balances = []
		accounts.value.forEach { (account) in
			minterAccountManager.balance(address: account.address, with: { (res, error) in
				guard nil == error else {
					return
				}
				
				self.balances.append(res)
				
				
			})
		}
	}

}
