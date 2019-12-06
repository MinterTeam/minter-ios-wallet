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

class ConvertCoinsViewModel: BaseViewModel {

	var accountManager = AccountManager()
	let coinManager = ExplorerCoinManager.default
	var selectedAddress: String?
	var selectedCoin: String? {
		didSet {
			selectedCoin = selectedCoin?.uppercased()
				.trimmingCharacters(in: .whitespacesAndNewlines)
		}
	}
	var hasCoin = Variable<Bool>(false)
	var coinIsLoading = Variable(false)
	var getCoin = BehaviorSubject<String?>(value: "")
	var shouldClearForm = Variable(false)
	var amountError = Variable<String?>(nil)
	var getCoinError = Variable<String?>(nil)
	lazy var isLoading = BehaviorSubject<Bool>(value: false)
	lazy var errorNotification = PublishSubject<NotifiableError?>()
	lazy var successMessage = PublishSubject<NotifiableSuccess?>()
	let formatter = CurrencyNumberFormatter.coinFormatter
	var currentGas = Session.shared.currentGasPrice
	lazy var feeObservable = PublishSubject<String>()
	var baseCoinCommission: Decimal {
		return Decimal(currentGas.value) * RawTransactionType.buyCoin.commission() / TransactionCoinFactorDecimal
	}

	// MARK: -

	override init() {
		super.init()

		Session.shared.updateGas()

		Session.shared.currentGasPrice.asObservable().map { (_) -> String in
			return CurrencyNumberFormatter.formattedDecimal(with: self.baseCoinCommission,
																											formatter: CurrencyNumberFormatter.decimalFormatter) + " " + (Coin.baseCoin().symbol ?? "")
			}.subscribe(onNext: { [weak self] (val) in
				self?.feeObservable.onNext(val)
			}).disposed(by: disposeBag)
	}

	var selectedBalance: Decimal? {
		let balances = Session.shared.allBalances.value
		if
			let ads = selectedAddress,
			let cn = selectedCoin,
			let smt = balances[ads],
			let blnc = smt[cn] {
				return blnc
		}
		return nil
	}

	var baseCoinBalance: Decimal {
		let balances = Session.shared.allBalances.value
		if
			let ads = selectedAddress,
			let cn = Coin.baseCoin().symbol,
			let smt = balances[ads],
			let blnc = smt[cn] {
				return blnc
		}
		return 0
	}

	var hasMultipleCoins: Bool {
		return Session.shared.allBalances.value.keys.map {
			return Session.shared.allBalances.value[$0]?.count ?? 0
		}.reduce(0, +) > 1
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
			return CurrencyNumberFormatter.formattedDecimal(with: balance,
																											formatter: CurrencyNumberFormatter.decimalFormatter)
		}
		return nil
	}

	var spendCoinText: String {
		let selected = (selectedCoin ?? "")
		let bal = CurrencyNumberFormatter.formattedDecimal(with: (selectedBalance ?? 0.0),
																											 formatter: formatter)
		return selected + " (" + bal + ")"
	}

	// MARK: -

	/// Depricated!
	//TODO: move to SpendCoinPickerItem
	func pickerItems() -> [ConvertPickerItem] {

		var ret = [ConvertPickerItem]()

		let balances = Session.shared.allBalances.value
		balances.keys.forEach { (address) in
			var coins = balances[address]?.keys.filter({ (coin) -> Bool in
				return coin != Coin.baseCoin().symbol!
			}).sorted(by: { (val1, val2) -> Bool in
				return val1 < val2
			})
			coins?.insert(Coin.baseCoin().symbol!, at: 0)

			coins?.forEach({ (coin) in
				let balance = (balances[address]?[coin] ?? 0.0)
				let item = ConvertPickerItem(coin: coin, address: address, balance: balance)
				ret.append(item)
			})
		}
		return ret
	}

	var spendCoinPickerSource: [String: [String: Decimal]] { return Session.shared.allBalances.value }

	var spendCoinPickerItems: [SpendCoinPickerItem] {
		let balances = spendCoinPickerSource
		var ret = [SpendCoinPickerItem]()
		balances.keys.forEach { (address) in
			var coins = balances[address]?.keys.filter({ (coin) -> Bool in
				return coin != Coin.baseCoin().symbol!
			}).sorted(by: { (val1, val2) -> Bool in
				return val1 < val2
			})
			coins?.insert(Coin.baseCoin().symbol!, at: 0)
			coins?.forEach({ (coin) in
				let balance = (balances[address]?[coin] ?? 0.0)
				let item = SpendCoinPickerItem(coin: coin,
																			 balance: balance,
																			 address: address,
																			 formatter: self.formatter)
				ret.append(item)
			})
		}
		return ret
	}

	func coinNames(by term: String, completion: (([String]) -> Void)?) {
		let term = term.lowercased()
		let coins = Session.shared.allCoins.value.filter { (con) -> Bool in
			return (con.symbol ?? "").lowercased().starts(with: term)
		}.sorted(by: { (coin1, coin2) -> Bool in
			if term == (coin1.symbol ?? "").lowercased() {
				return true
			} else if (coin2.symbol ?? "").lowercased() == term {
				return false
			}
			return (coin1.reserveBalance ?? 0) > (coin2.reserveBalance ?? 0)
		}).map { (coin) -> String in
			return coin.symbol ?? ""
		}
		let resCoins = Array(coins[safe: 0..<3] ?? [])
		completion?(resCoins)
	}

	// MARK: -

	func validateErrors() {}

	func loadCoin() {
		self.hasCoin.value = false
		let coin = try? self.getCoin.value()?
			.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
		guard coin?.isValidCoin() ?? false else {
			//Show error
			return
		}

		if coin == Coin.baseCoin().symbol {
			hasCoin.value = true
			self.validateErrors()
			return
		}
		let coins = Session.shared.allCoins.value.filter { (con) -> Bool in
			return (con.symbol ?? "") == coin!
		}
		if coins.count > 0 {
			self.hasCoin.value = true
		}
		validateErrors()
	}
}
