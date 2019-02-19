//
//  ConvertCoinsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterExplorer


struct ConvertPickerItem {
	var coin: String?
	var address: String?
	var balance: Decimal?
}

struct ConvertBalanceItem {
	var coin: String?
	var address: String?
	var balance: Decimal?
}

struct SpendCoinPickerItem {
	var title: String?
	
	var coin: String?
	var address: String?
	var balance: Decimal?
	
	init(coin: String, balance: Decimal, address: String, formatter: NumberFormatter) {
		let balanceString = CurrencyNumberFormatter.formattedDecimal(with: balance, formatter: formatter)
		self.title = coin + " (" + balanceString + ")"
		
		self.coin = coin
		self.address = address
		self.balance = balance
		
	}

}


class ConvertCoinsViewModel : BaseViewModel {
	
	var accountManager = AccountManager()
	
	let coinManager = ExplorerCoinManager.default
	
	var disposeBag = DisposeBag()
	
	var selectedAddress: String?
	
	var selectedCoin: String?
	
	var hasCoin = Variable<Bool>(false)
	
	var coinIsLoading = Variable(false)
	
	var getCoin = BehaviorSubject<String?>(value: "")
	
	var shouldClearForm = Variable(false)
	
	var amountError = Variable<String?>(nil)
	
	var getCoinError = Variable<String?>(nil)
	
	lazy var isLoading = BehaviorSubject<Bool>(value: false)
	
	lazy  var errorNotification = PublishSubject<NotifiableError?>()
	
	lazy var successMessage = PublishSubject<NotifiableSuccess?>()
	
	let formatter = CurrencyNumberFormatter.coinFormatter
	
	var currentGas = Session.shared.currentGasPrice
	
	lazy var feeObservable = PublishSubject<String>()
	
	var baseCoinCommission: Decimal {
		return Decimal(currentGas.value) * RawTransactionType.buyCoin.commission() / TransactionCoinFactorDecimal
	}
	
	
	//MARK: -
	
	override init() {
		super.init()
		
		Session.shared.updateGas()
		
		Session.shared.currentGasPrice.asObservable().map { (gas) -> String in
			return CurrencyNumberFormatter.formattedDecimal(with: self.baseCoinCommission, formatter: CurrencyNumberFormatter.decimalFormatter) + " " + (Coin.baseCoin().symbol ?? "")
			}.subscribe(onNext: { [weak self] (val) in
				self?.feeObservable.onNext(val)
			}).disposed(by: disposeBag)
		
	}
	
	var selectedBalance: Decimal? {
		let balances = Session.shared.allBalances.value
		if let ads = selectedAddress, let cn = selectedCoin, let smt = balances[ads], let blnc = smt[cn] {
			return blnc
		}
		return nil
	}
	
	var baseCoinBalance: Decimal {
		let balances = Session.shared.allBalances.value
		if let ads = selectedAddress, let cn = Coin.baseCoin().symbol, let smt = balances[ads], let blnc = smt[cn] {
			return blnc
		}
		return 0
	}
	
	var hasMultipleCoins: Bool {
		var coinCount = 0
		Session.shared.allBalances.value.keys.forEach { (key) in
			Session.shared.allBalances.value[key]?.forEach({ (val) in
				coinCount += 1
			})
		}
		return coinCount > 1
	}
	
	func canPayComissionWithBaseCoin() -> Bool {
		let balance = self.baseCoinBalance
		if balance >= self.baseCoinCommission {
			return true
		}
		return false
	}
	
	var selectedBalanceString: String? {
		if let balance = selectedBalance {
			return CurrencyNumberFormatter.formattedDecimal(with: balance, formatter: CurrencyNumberFormatter.decimalFormatter)
		}
		return nil
	}
	
	var spendCoinText: String {
		let selected = (selectedCoin ?? "")
		let bal = CurrencyNumberFormatter.formattedDecimal(with: (selectedBalance ?? 0.0), formatter: formatter) //formatter.string(from: (selectedBalance ?? 0.0) as NSDecimalNumber) ?? ""
		return selected + " (" + bal + ")"
	}
	
	//MARK: -
	
	/// Depricated!
	//TODO: move to SpendCoinPickerItem
	func pickerItems() -> [ConvertPickerItem] {
		
		var ret = [ConvertPickerItem]()
		
		let balances = Session.shared.allBalances.value
		balances.keys.forEach { (address) in
			balances[address]?.keys.sorted(by: { (val1, val2) -> Bool in
				return val1 < val2
			}).forEach({ (coin) in
				let balance = (balances[address]?[coin] ?? 0.0)
				
				let item = ConvertPickerItem(coin: coin, address: address, balance: balance)
				ret.append(item)
			})
		}
		return ret
	}
	
	var spendCoinPickerSource: [String : [String : Decimal]] { return Session.shared.allBalances.value }
	
	var spendCoinPickerItems: [SpendCoinPickerItem] {
		
		let balances = spendCoinPickerSource
		var ret = [SpendCoinPickerItem]()
		balances.keys.forEach { (address) in
			balances[address]?.keys.sorted(by: { (val1, val2) -> Bool in
				return val1 < val2
			}).forEach({ (coin) in
				let balance = (balances[address]?[coin] ?? 0.0)
				let item = SpendCoinPickerItem(coin: coin, balance: balance, address: address, formatter: self.formatter)
				ret.append(item)
			})
		}
		return ret
	}
	
	func coinNames(by term: String, completion: (([String]) -> ())?) {
		coinManager.coins(term: term) { (coins, error) in
			
			let res = coins?.map({ (coin) -> String in
				return coin.symbol ?? ""
			}).filter({ (symbol) -> Bool in
				symbol != ""
			}) ?? [String]()
			
			let resCoins = Array(res[safe: 0..<3] ?? [])
			completion?(resCoins)
			
		}
	}
	
	//MARK: -
	
	func validateErrors() {}
	
	
	func loadCoin() {
		
		self.hasCoin.value = false
		let coin = try? self.getCoin.value()?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
		//TODO: Add isValidCoin
		if (coin?.count ?? 0) >= 3 {
			
		}
		else {
			//Show error
			return
		}
		
		if coin == Coin.baseCoin().symbol {
			hasCoin.value = true
			self.validateErrors()
			return
		}
		
		
		self.coinIsLoading.value = true
		
		ExplorerCoinManager.default.coins(term: coin!) { [weak self] (coins, error) in
		
			defer {
				self?.coinIsLoading.value = false
				self?.validateErrors()
			}
			
			guard error == nil, (coins?.count ?? 0) > 0 else {
				//Error?
				return
			}
			
			if (coins?.filter({ (cn) -> Bool in
				return (cn.symbol?.uppercased() ?? "") == (coin ?? "")
			}).count ?? 0) > 0 {
				self?.hasCoin.value = true
			}
		}
	}
	
	
}
