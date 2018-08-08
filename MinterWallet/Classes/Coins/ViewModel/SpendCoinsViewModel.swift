//
//  SpendCoinsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import MinterExplorer
import BigInt


struct ConvertPickerItem {
	var coin: String?
	var address: String?
	var balance: Decimal?
}


class SpendCoinsViewModel : ConvertCoinsViewModel {
	
	//MARK: -
	
	override init() {
		super.init()
		
		Session.shared.allBalances.asObservable().subscribe(onNext: { [weak self] (val) in
			let val = self?.pickerItems().first
			let ads = val?.address
			let cn = val?.coin
			
			self?.spendCoin.value = cn
			self?.selectedCoin = cn
			self?.selectedAddress = ads
		}).disposed(by: disposeBag)
		
		Observable.combineLatest(spendCoin.asObservable(), spendAmount.asObservable(), getCoin.asObservable()).filter { (val) -> Bool in
			return true
		}.throttle(1, scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] (val) in
			self?.approximately.value = ""
			self?.calculateApproximately()
			self?.validateErrors()
		}).disposed(by: disposeBag)

		shouldClearForm.asObservable().subscribe(onNext: { [weak self] (val) in
			self?.spendAmount.value = nil
			self?.getCoin.value = nil
		}).disposed(by: disposeBag)
		
		approximatelyReady.asObservable().subscribe(onNext: { [weak self] (val) in
			self?.validateErrors()
		}).disposed(by: disposeBag)
		
		getCoin.asObservable().subscribe(onNext: { [weak self] (val) in
			self?.loadCoin()
		}).disposed(by: disposeBag)
		
		Session.shared.loadBalances()
		
	}
	
	//MARK: -
	
	var spendCoin = Variable<String?>(nil)
	
	var spendAmount = Variable<String?>(nil)
	
	var isApproximatelyLoading = Variable(false)
	
	var approximately = Variable<String?>(nil)
	
	var approximatelyReady = Variable<Bool>(false)
	
	private var fee: Decimal?
	
	private let shortDecimalFormatter = CurrencyNumberFormatter.decimalShortFormatter
	private let decimalsNoMantissaFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter
	
	var isButtonEnabled: Observable<Bool> {
		return Observable.combineLatest(hasCoin.asObservable(), getCoin.asObservable(), spendAmount.asObservable(), spendCoin.asObservable()).map({ (val) -> Bool in
			
			guard let amountString = val.2, let amnt = Decimal(string: amountString), amnt > 0 else {
				return false
			}
			
			guard (self.getCoin.value ?? "") != (self.selectedCoin ?? "") else {
				return false
			}
			
			return val.0 == true && (val.1 ?? "").count >= 3 && amnt <= (self.selectedBalance ?? 0) && (val.3 ?? "").count >= 3
		})
	}
	
	//MARK: -
	
	func calculateApproximately() {
		
		approximatelyReady.value = false
		
		guard let from = selectedCoin?.uppercased(), let to = self.getCoin.value?.uppercased(), let amountString = self.spendAmount.value, let amnt = Decimal(string: amountString), amnt > 0 else {
			return
		}
		
		let numberFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter
		
		guard let strVal = numberFormatter.string(from: amnt * TransactionCoinFactorDecimal as NSNumber) else {
			return
		}
		
		var value = Decimal(string: strVal) ?? Decimal(0)
		
		let maxComparableSelectedBalance = (Decimal(string: shortDecimalFormatter.string(from: (selectedBalance ?? 0.0) as NSNumber) ?? "") ?? 0.0) * TransactionCoinFactorDecimal
		
		let maxComparableBalance = decimalsNoMantissaFormatter.string(from: maxComparableSelectedBalance as NSNumber) ?? ""
		let isMax = (value > 0 && value == (Decimal(string: maxComparableBalance) ?? Decimal(0)))
		
		if isMax {
			value = selectedBalance ?? Decimal(0.0)
		}
		
		//TODO: isCoinValid
		if to.count < 3 {
			return
		}
		
		value *= TransactionCoinFactorDecimal
		
		CoinManager.default.estimateCoinSell(from: from, to: to, amount: value) { [weak self] (val, commission, error) in
			
			guard nil == error, let ammnt = val else {
				return
			}
			
			self?.approximately.value = (self?.formatter.string(from: ammnt as NSNumber) ?? "") + " " + to
			self?.fee = commission
			
			if to == self?.getCoin.value {
				self?.approximatelyReady.value = true
			}
		}
	}
	
	override func validateErrors() {
		if let amountString = self.spendAmount.value, amountString != "", let amount = Decimal(string: amountString) {
			if amount > (selectedBalance ?? 0.0) {
				amountError.value = "INSUFFICIENT FUNDS".localized()
			}
			else {
				amountError.value = nil
			}
		}
		else {
			let amountString = self.spendAmount.value
			if nil == amountString || amountString == "" {
				amountError.value = nil
			}
			else {
				amountError.value = "INCORRECT AMOUNT".localized()
			}
		}
			
		if let amountString = self.spendAmount.value, amountString != "", let amount = Decimal(string: amountString), let getCoin = self.getCoin.value, !hasCoin.value && getCoin != "" {
			getCoinError.value = "COIN NOT FOUND".localized()
		}
		else {
			getCoinError.value = nil
		}
	}
	
	func exchange() {
		
		guard let coinFrom = self.selectedCoin?.uppercased(),
			let coinTo = self.getCoin.value?.uppercased(),
			let amount = self.spendAmount.value,
			let selectedAddress = self.selectedAddress,
			let amountString = self.spendAmount.value, let amnt = Decimal(string: amountString)
		else {
				return
		}
		
		let numberFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter
		
		guard let strVal = numberFormatter.string(from: amnt * TransactionCoinFactorDecimal as NSNumber) else {
			return
		}
		
		let convertVal = (BigUInt(strVal) ?? BigUInt(0))
		
		let value = convertVal
		
		if value <= 0 {
			return
		}
		
		let maxComparableSelectedBalance = (Decimal(string: shortDecimalFormatter.string(from: (selectedBalance ?? 0.0) as NSNumber) ?? "") ?? 0.0) * TransactionCoinFactorDecimal
		
		let maxComparableBalance = decimalsNoMantissaFormatter.string(from: maxComparableSelectedBalance as NSNumber) ?? ""
		let isMax = (value > 0 && value == (BigUInt(maxComparableBalance) ?? BigUInt(0)))
		let isFromBaseCoin = coinFrom == Coin.baseCoin().symbol!
		
		isLoading.value = true
		
		DispatchQueue.global(qos: .userInitiated).async {
		guard let mnemonic = self.accountManager.mnemonic(for: selectedAddress), let seed = self.accountManager.seed(mnemonic: mnemonic) else {
			self.isLoading.value = false
			//Error no Private key found
			assert(true)
			self.errorNotification.value = NotifiableError(title: "No private key found", text: nil)
			return
		}
		
		let pk = self.accountManager.privateKey(from: seed).raw.toHexString()
		
		MinterCore.CoreTransactionManager.default.transactionCount(address: "Mx" + selectedAddress) { [weak self] (count, err) in
			
			guard err == nil, let nnce = count else {
				self?.isLoading.value = false
				self?.errorNotification.value = NotifiableError(title: "Can't get nonce", text: nil)
				return
			}
			
			let nonce = nnce + 1
			
			var tx: RawTransaction!
			if isMax {
				let coin = (self?.canPayComission() ?? false) ? Coin.baseCoin().symbol : coinFrom
				let coinData = coin?.data(using: .utf8)?.setLengthRight(10) ?? Data(repeating: 0, count: 10)
				
				tx = SellAllCoinsRawTransaction(nonce: BigUInt(nonce), gasCoin: coinData, coinFrom: coinFrom, coinTo: coinTo)
			}
			else {
				let coin = (self?.canPayComission() ?? false) ? Coin.baseCoin().symbol : coinFrom
				let coinData = coin?.data(using: .utf8)?.setLengthRight(10) ?? Data(repeating: 0, count: 10)
				
				tx = SellCoinRawTransaction(nonce: BigUInt(nonce), gasCoin: coinData, coinFrom: coinFrom, coinTo: coinTo, value: value)
			}
			
			let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: pk)
			
			MinterCore.CoreTransactionManager.default.send(tx: signedTx!) { (hash, status, err) in
				self?.isLoading.value = false
				
				defer {
					DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2, execute: {
						Session.shared.loadBalances()
						Session.shared.loadTransactions()
					})
					
					Session.shared.loadBalances()
					Session.shared.loadTransactions()
				}
				
				guard nil == err else {
					if let apiError = err as? APIClient.APIClientResponseError, let errorCode = apiError.userData?["code"] as? Int {
						if errorCode == 107 {
							self?.errorNotification.value = NotifiableError(title: "Not enough coins to spend".localized(), text: nil)
						}
						else if errorCode == 103 {
							self?.errorNotification.value = NotifiableError(title: "Coin reserve balance is not sufficient for transaction".localized(), text: nil)
						}
						else {
							if let msg = apiError.userData?["log"] as? String {
								self?.errorNotification.value = NotifiableError(title: msg, text: nil)
							}
							else {
								self?.errorNotification.value = NotifiableError(title: "An error occured".localized(), text: nil)
							}
						}
						return
					}
					self?.errorNotification.value = NotifiableError(title: "Can't send Transaction", text: nil)
					return
				}
				
				self?.shouldClearForm.value = true
				self?.successMessage.value = NotifiableSuccess(title: "Coins have been successfully spent".localized(), text: nil)
			}
		}
		}
	}

}
