//
//  GetCoinsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 17/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import RxSwift
import MinterCore
import BigInt


class GetCoinsViewModel : ConvertCoinsViewModel {

	//MARK: -
	
	override init() {
		super.init()
		
		let val = pickerItems().first
		let ads = val?.address
		let cn = val?.coin
		
		self.spendCoin.value = cn
		self.selectedCoin = cn
		self.selectedAddress = ads
		
		Observable.combineLatest(getCoin.asObservable(), getAmount.asObservable(), spendCoin.asObservable()).filter { (val) -> Bool in
			return true
		}.subscribe(onNext: { [weak self] (val) in
			self?.approximately.value = ""
			self?.calculateApproximately()
		}).disposed(by: disposeBag)
		
		shouldClearForm.asObservable().subscribe(onNext: { (val) in
			self.getAmount.value = nil
			self.getCoin.value = nil
		}).disposed(by: disposeBag)
		
		getCoin.asObservable().subscribe(onNext: { [weak self] (val) in
			self?.loadCoin()
		}).disposed(by: disposeBag)
		
		Session.shared.loadBalances()
		
	}
	
	//MARK: -
	
	var spendCoin = Variable<String?>(nil)
	
	var getAmount = Variable<String?>(nil)
	
	var isApproximatelyLoading = Variable(false)
	
	var approximately = Variable<String?>(nil)
	
	var approximatelySum = Variable<Decimal?>(nil)
	
	var approximatelyReady = Variable<Bool>(false)
	
	var isButtonEnabled: Observable<Bool> {
		return Observable.combineLatest(getCoin.asObservable(), approximatelySum.asObservable(), hasCoin.asObservable()).map({ (val) -> Bool in
			
			if (self.selectedCoin ?? "") == (val.0 ?? "") {
				return false
			}
			
			let amnt = (val.1 ?? 0)

			return amnt > 0 /*&& amnt <= (self.selectedBalance ?? 0)*/ && self.hasCoin.value
		})
	}
	
	//MARK: -
	
	override func validateErrors() {
		if let getCn = getCoin.value, getCn != "" && !hasCoin.value {
			self.getCoinError.value = "COIN NOT FOUND".localized()
		}
		else {
			self.getCoinError.value = ""
		}
		
		if let amountString = self.getAmount.value, let amnt = Decimal(string: amountString), amnt > 0 {
			if (approximatelySum.value ?? 0.0) > (selectedBalance ?? 0.0) {
				self.amountError.value = "INSUFFICIENT FUNDS".localized()
			}
			else {
				self.amountError.value = ""
			}
		}
		else {
			self.amountError.value = ""
		}
		
		
	}
	
	func calculateApproximately() {
		
		approximatelyReady.value = false
		self.approximatelySum.value = nil
		
		guard let from = selectedCoin?.uppercased(), let to = self.getCoin.value?.uppercased(), let amountString = self.getAmount.value, let amnt = Decimal(string: amountString), amnt > 0 else {
			return
		}
		
		if to.count < 3 {
			return
		}
		
		isApproximatelyLoading.value = true
		
		CoinManager.default.estimateCoinBuy(from: from, to: to, amount: amnt * TransactionCoinFactorDecimal) { [weak self] (val, commission, error) in
			
			self?.isApproximatelyLoading.value = false
			
			guard nil == error, let ammnt = val, let commission = commission else {
				return
			}
			
			let normalizedCommission = commission / TransactionCoinFactorDecimal
			let val = (ammnt / TransactionCoinFactorDecimal) + normalizedCommission
			
			self?.approximately.value = CurrencyNumberFormatter.formattedDecimal(with: val > 0 ? val : 0 , formatter: self!.formatter) + " " + from
			
			self?.approximatelySum.value = val
			
			if to == self?.getCoin.value {
				self?.approximatelyReady.value = true
			}
		}
	}
	
	func exchange() {
		
		guard let coinFrom = self.selectedCoin?.uppercased(),
			let coinTo = self.getCoin.value?.uppercased(),
//			let amount = self.approximatelySum.value,
			let selectedAddress = self.selectedAddress,
			let amntString = self.getAmount.value, let amount = Decimal(string: amntString)
			else {
				return
		}
		
		let frmttr = NumberFormatter()
		frmttr.generatesDecimalNumbers = true
		
		let ammnt = amount * TransactionCoinFactorDecimal
		guard let amountString = frmttr.string(from: ammnt as NSNumber) else {
			return
		}
		
		let convertVal = (BigUInt(amountString) ?? BigUInt(0))
		
		let value = convertVal
		
		if value <= 0 {
			return
		}
		
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
				
				let coin = (self?.canPayComission() ?? false) ? Coin.baseCoin().symbol : coinFrom
				let coinData = coin?.data(using: .utf8)?.setLengthRight(10) ?? Data(repeating: 0, count: 10)
				
				let tx = BuyCoinRawTransaction(nonce: BigUInt(nonce), gasCoin: coinData, coinFrom: coinFrom, coinTo: coinTo, value: value)
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
					self?.successMessage.value = NotifiableSuccess(title: "Coins have been successfully bought".localized(), text: nil)
				}
			}
		}
	}
	
}
