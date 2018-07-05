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
	
	var getCoin = Variable<String?>(nil)
	
	var getAmount = Variable<Double?>(nil)
	
	var spendCoin = Variable<String?>(nil)
	
	var spendAmount = Variable<Double?>(nil)
	
	var disposeBag = DisposeBag()
	
	let coinManager = CoinManager.default
	
	var selectedAddress: String?
	
	var selectedCoin: String?
	
	var isLoading = Variable(false)
	
	var maxButtonTitle = Variable<String?>(nil)
	
	var selectedBalance: Double? {
		let balances = Session.shared.allBalances.value
		if let ads = selectedAddress, let cn = selectedCoin, let smt = balances[ads], let blnc = smt[cn] {
			return blnc
		}
		return nil
	}
	
	//MARK: -

	override init() {
		super.init()
		
		getCoin.asObservable().distinctUntilChanged({ (str1, str2) -> Bool in
			return (str1 ?? "") == (str2 ?? "")
		}).subscribe(onNext: { (coinSymbol) in
			self.updateForm()
		}).disposed(by: disposeBag)
		
		
		getAmount.asObservable().distinctUntilChanged({ (str1, str2) -> Bool in
			return (str1 ?? 0) == (str2 ?? 0)
		}).subscribe(onNext: { (val) in
//			self.updateForm()
		}).disposed(by: disposeBag)
		
		
		spendAmount.asObservable().distinctUntilChanged({ (str1, str2) -> Bool in
			return (str1 ?? 0) == (str2 ?? 0)
		}).subscribe(onNext: { (val) in
			self.updateForm()
		}).disposed(by: disposeBag)
		
		spendCoin.asObservable().distinctUntilChanged({ (str1, str2) -> Bool in
			return (str1 ?? "") == (str2 ?? "")
		}).subscribe(onNext: { (coinSymbol) in
			self.updateForm()
			
			self.maxButtonTitle.value = "USE MAX." + String(self.selectedBalance ?? 0)
			
		}).disposed(by: disposeBag)

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
	
//	func accountPickerItems() -> [PickerTableViewCellPickerItem] {
//		var ret = [AccountPickerItem]()
//
//		let balances = Session.shared.allBalances.value
//		balances.keys.forEach { (address) in
//			balances[address]?.keys.forEach({ (coin) in
//				let balance = (balances[address]?[coin] ?? 0.0)
//
//				//				guard balance > 0 else { return }
//
//				let title = coin + " (" + String(balance) + ")"
//				let item = AccountPickerItem(title: title, address: address, balance: balance, coin: coin)
//				ret.append(item)
//			})
//		}
//
//		return ret.map({ (account) -> PickerTableViewCellPickerItem in
//			return (title: title, object: account)
//		})
//	}
	
	func updateForm() {
		
		guard let fromCoin = self.selectedCoin,
			let toCoin = self.getCoin.value,
			let amount = self.spendAmount.value else {
				//show error
				return
		}
		
		isLoading.value = true
		
		self.coinManager.estimateExchangeReturn(from: fromCoin, to: toCoin, amount: amount, completion: { [weak self] (val, err) in
			
			self?.isLoading.value = false
			
			guard nil == err, let val = val else {
				return
			}
			
			self?.getAmount.value = val
			
		})
	}
	
}
