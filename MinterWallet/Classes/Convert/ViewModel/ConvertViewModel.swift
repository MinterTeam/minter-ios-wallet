//
//  ConvertConvertViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import MinterCore
import BigInt


struct ConvertPickerItem {
	var coin: String?
	var address: String?
	var balance: Double?
}


class ConvertViewModel: BaseViewModel {

	//MARK: -
	
	var title: String {
		get {
			return "Convert Coins".localized()
		}
	}
	
	var errorNotification = Variable<NotifiableError?>(nil)
	
	var successMessage = Variable<NotifiableSuccess?>(nil)
	
	var getCoin = Variable<String?>(nil)
	
	var getAmount = Variable<Double?>(nil)
	
	var spendCoin = Variable<String?>(nil)
	
	var spendAmount = Variable<Double?>(nil)
	
	var disposeBag = DisposeBag()
	
	let coinManager = CoinManager.default
	
	var selectedAddress: String?
	
	var selectedCoin: String?
	
	var isLoading = Variable(false)
	
	var getAmountIsLoading = Variable(false)
	var spendAmountIsLoading = Variable(false)
	
	var maxButtonTitle = Variable<String?>(nil)
	
	var coinIsLoading = Variable(false)
	
	var hasCoin = Variable(false)
	
	var shouldUpdateForm = true
	
	var selectedBalance: Double? {
		let balances = Session.shared.allBalances.value
		if let ads = selectedAddress, let cn = selectedCoin, let smt = balances[ads], let blnc = smt[cn] {
			return blnc
		}
		return nil
	}
	
	var isButtonAvailableObservable: Observable<Bool> {
		return Observable.combineLatest(self.isLoading.asObservable(), self.hasCoin.asObservable(), self.spendAmount.asObservable()).map({ (val) -> Bool in
			return !val.0 && val.1 && (val.2 ?? 0.0 > 0.0) && (val.2 ?? 0.0 <= self.selectedBalance ?? 0.0)
		})
	}
	
	private let accountManager = AccountManager()
	
	//MARK: -

	override init() {
		super.init()
		
		let val = pickerItems().first
		let ads = val?.address
		let cn = val?.coin
		
		self.selectedCoin = cn
		self.selectedAddress = ads
		
		
		getCoin.asObservable().throttle(1, scheduler: MainScheduler.instance).distinctUntilChanged({ (str1, str2) -> Bool in
			return (str1 ?? "") == (str2 ?? "")
		}).subscribe(onNext: { (coinSymbol) in
//			self.updateForm()
			self.loadCoin()
		}).disposed(by: disposeBag)
		
		getAmount.asObservable().throttle(1, scheduler: MainScheduler.instance).distinctUntilChanged({ (str1, str2) -> Bool in
			return (str1 ?? 0) == (str2 ?? 0)
		}).subscribe(onNext: { (val) in

			if !self.shouldUpdateForm {
				return
			}
			
			guard (val ?? 0) > 0 && self.hasCoin.value, let from = self.getCoin.value?.uppercased(), let to = self.selectedCoin?.uppercased() else {
				return
			}
			
			self.loadRate(from: from, to: to, amount: val!, backConversion: true)
			
		}).disposed(by: disposeBag)
		
		spendAmount.asObservable().throttle(2, scheduler: MainScheduler.instance).distinctUntilChanged({ (str1, str2) -> Bool in
			return (str1 ?? 0) == (str2 ?? 0)
		}).subscribe(onNext: { (val) in
			
			guard nil != val else {
				return
			}
			
			if nil != val && self.shouldUpdateForm {
				self.updateForm()
			}
		}).disposed(by: disposeBag)
		
		spendCoin.asObservable().throttle(1, scheduler: MainScheduler.instance).distinctUntilChanged({ (str1, str2) -> Bool in
			return (str1 ?? "") == (str2 ?? "")
		}).subscribe(onNext: { (coinSymbol) in
			self.updateForm()
			
			self.maxButtonTitle.value = "USE MAX. " + String(self.selectedBalance ?? 0)
			
		}).disposed(by: disposeBag)

	}
	
	func loadCoin() {
		
		self.hasCoin.value = false
		let coin = self.getCoin.value?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
		if (coin?.count ?? 0) >= 3 {
			
		}
		else {
			//Show error
			return
		}
		
		if coin == Coin.defaultCoin().symbol {
			hasCoin.value = true
			return
		}
		
		
		self.coinIsLoading.value = true
		
		CoinManager.default.info(symbol: coin!) { [weak self] (cn, error) in
			
			defer {
				self?.coinIsLoading.value = false
			}
			
			guard error == nil, nil != cn else {
				//Error?
				return
			}
			
			if coin == cn?.symbol?.uppercased() {
				self?.hasCoin.value = true
			}
		}
	}
	
	func pickerItems() -> [ConvertPickerItem] {
		
		var ret = [ConvertPickerItem]()
		
		let balances = Session.shared.allBalances.value
		balances.keys.forEach { (address) in
			balances[address]?.keys.forEach({ (coin) in
				let balance = (balances[address]?[coin] ?? 0.0)
				
				let item = ConvertPickerItem(coin: coin, address: address, balance: balance)
				ret.append(item)
			})
		}
		return ret
	}
	
	func updateForm() {
		
		guard let fromCoin = self.selectedCoin,
			let toCoin = self.getCoin.value?.uppercased().trimmingCharacters(in: .whitespacesAndNewlines),
			let amount = self.spendAmount.value else {
				//show error
				return
		}
		
		guard hasCoin.value, amount > 0 else {
			return
		}
		
		loadRate(from: fromCoin, to: toCoin, amount: amount)

	}
	
	func loadRate(from: String, to: String, amount: Double, backConversion: Bool = false) {
		
		if backConversion {
			spendAmountIsLoading.value = true
		}
		else {
			getAmountIsLoading.value = true
		}
		
		isLoading.value = true
		
		self.coinManager.estimateExchangeReturn(from: from, to: to, amount: amount, includeCommission: true, completion: { [weak self] (val, err) in
			
			defer {
				self?.isLoading.value = false
				self?.getAmountIsLoading.value = false
				self?.spendAmountIsLoading.value = false
			}
			
			guard nil == err else {
				return
			}
			
			self?.shouldUpdateForm = false
			
			if backConversion {
				self?.spendAmount.value = val ?? 0.0
			}
			else {
				self?.getAmount.value = val ?? 0.0
			}
			self?.shouldUpdateForm = true
			
		})
	}
	
	
	
	func convert() {
		
		guard let coinFrom = self.selectedCoin,
			let coinTo = self.getCoin.value,
			let amount = self.spendAmount.value,
			let selectedAddress = self.selectedAddress,
			let value = BigUInt(String(BigInt(amount * pow(10, 18))))
		else {
				return
		}
		
		isLoading.value = true
		
		guard let mnemonic = self.accountManager.mnemonic(for: selectedAddress), let seed = self.accountManager.seed(mnemonic: mnemonic)  else {
			isLoading.value = false
			//Error no Private key found
			assert(true)
			self.errorNotification.value = NotifiableError(title: "No private key found", text: nil)
			return
		}
		
		let pk = accountManager.privateKey(from: seed).raw.toHexString()
		
		MinterCore.TransactionManagerr.default.transactionCount(address: "Mx" + selectedAddress) { [weak self] (count, err) in
			
			guard err == nil, let nnce = count else {
				self?.isLoading.value = false
				self?.errorNotification.value = NotifiableError(title: "Can't get nonce", text: nil)
				return
			}
			
			let nonce = nnce + 1
			
			let tx = ConvertCoinRawTransaction(nonce: BigUInt(nonce), coinFrom: coinFrom, coinTo: coinTo, value: value)
			let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: pk)
			
			MinterCore.TransactionManagerr.default.send(tx: signedTx!) { (hash, status, err) in
				self?.isLoading.value = false
				
				defer {
					Session.shared.loadBalances()
					Session.shared.loadTransactions()
				}
				
				guard nil == err else {
					self?.errorNotification.value = NotifiableError(title: "Can't send Transaction", text: nil)
					return
				}
			}
		}
	}
	
}
