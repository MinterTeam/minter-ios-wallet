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
	
	var balances: [Any] = []
	
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
		
		transactions.value = []
		
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
		balances = []
		accounts.value.forEach { (account) in
			minterAccountManager.balance(address: account.address, with: { [weak self] (res, error) in
				guard nil == error else {
					return
				}
				
				self?.balances.append(res)
				
				
			})
		}
	}

}
