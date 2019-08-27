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

enum SpendCoindsViewModelError : Error {
	case incorrectParams
	case noPrivateKey
	case canNotGetNonce
	case canNotCreateTx
}

class SpendCoinsViewModel: ConvertCoinsViewModel, ViewModelProtocol {

	// MARK: - ViewModelProtocol

	var input: SpendCoinsViewModel.Input!
	var output: SpendCoinsViewModel.Output!

	struct Input {
		var spendAmount: AnyObserver<String?>
		var getCoin: AnyObserver<String?>
		var spendCoin: AnyObserver<String?>
		var useMaxDidTap: AnyObserver<Void>
		var exchangeDidTap: AnyObserver<Void>
		var selectedAddress: String?
		var selectedCoin: String?
	}

	struct Output {
		var approximately: Observable<String?>
		var spendCoin: Observable<String?>
		var spendAmount: Observable<String?>
		var hasMultipleCoinsObserver: Observable<Bool>
		var isButtonEnabled: Observable<Bool>
		var isLoading: Observable<Bool>
		var isCoinLoading: Observable<Bool>
		var errorNotification: Observable<NotifiableError?>
		var shouldClearForm: Observable<Bool>
		var amountError: Observable<String?>
		var getCoinError: Observable<String?>
	}

	// MARK: -

	let transactionManager = ExplorerTransactionManager.default

	private var coinObservable: Observable<String?> {
		return getCoin.asObservable()
	}

	override init() {
		super.init()

		self.output = Output(approximately: approximately.asObservable(),
												 spendCoin: spendCoinField.asObservable(),
												 spendAmount: spendAmount.asObservable(),
												 hasMultipleCoinsObserver: hasMultipleCoinsObserver,
												 isButtonEnabled: isButtonEnabled,
												 isLoading: isLoading.asObservable(),
												 isCoinLoading: coinIsLoading.asObservable(),
												 errorNotification: errorNotification.asObservable(),
												 shouldClearForm: shouldClearForm.asObservable(),
												 amountError: amountError.asObservable(),
												 getCoinError: getCoinError.asObservable()
		)

		self.input = Input(spendAmount: spendAmount.asObserver(),
											 getCoin: getCoin.asObserver(),
											 spendCoin: spendCoinField.asObserver(),
											 useMaxDidTap: useMaxDidTap.asObserver(),
											 exchangeDidTap: exchangeDidTap.asObserver(),
											 selectedAddress: selectedAddress,
											 selectedCoin: selectedCoin
		)

		self.coinObservable.distinctUntilChanged().do(onNext: { [weak self] (term) in
			if nil != term && term != "" {
				self?.hasCoin.value = false
				self?.getCoinError.value = "COIN NOT FOUND".localized()
			} else {
				self?.getCoinError.value = ""
			}
		}).map({ (term) -> String in
			return term?.transformToCoinName() ?? ""
		}).filter({ (term) -> Bool in
			return CoinValidator.isValid(coin: term)
		}).subscribe(onNext: { [weak self] (term) in

			guard let _self = self else { return }

			self?.coinManager.coin(by: term).do(onNext: { (coin) in
				self?.coinIsLoading.value = true
			}, onCompleted: {
				self?.coinIsLoading.value = false
			}).filter({ (coin) -> Bool in
				return coin != nil
			}).subscribe(onNext: { [weak self] (coin) in
				self?.hasCoin.value = true
				self?.getCoinError.value = ""
			}).disposed(by: _self.disposeBag)
		}).disposed(by: disposeBag)

		Session.shared.allBalances.asObservable()
			.subscribe(onNext: { [weak self] (val) in

			self?.spendCoinField.onNext(self?.spendCoinText)

			let val = self?.pickerItems().first
			let ads = val?.address
			let cn = val?.coin

			if let spend = try? self?.spendCoin.value(), nil == spend {
				self?.spendCoin.onNext(cn)
			}
			if nil == self?.selectedCoin {
				self?.selectedCoin = cn
			}
			if nil == self?.selectedAddress {
				self?.selectedAddress = ads
			}
		}).disposed(by: disposeBag)

		self.spendCoinField.throttle(1.0, scheduler: MainScheduler.instance)
			.distinctUntilChanged().map({ (val) -> SpendCoinPickerItem? in
			let item = self.spendCoinPickerItems.filter({ (item) -> Bool in
				return item.title == val
			}).first
			return item
		}).filter({ (item) -> Bool in
			return item != nil
		}).subscribe(onNext: { [weak self] (item) in
			self?.selectedAddress = item?.address
			self?.selectedCoin = item?.coin
			self?.spendCoin.onNext(item?.coin)
		}).disposed(by: disposeBag)

		self.spendCoin.distinctUntilChanged().asObservable().filter({ [weak self] (coin) -> Bool in
			return coin != nil && self?.selectedBalance != nil && self?.selectedAddress != nil
		}).subscribe(onNext: { [weak self] (coin) in
			guard let _self = self else { return }

			let item = SpendCoinPickerItem(coin: coin!,
																		 balance: _self.selectedBalance!,
																		 address: _self.selectedAddress!,
																		 formatter: _self.formatter)
			self?.spendCoinField.onNext(item.title)
		}).disposed(by: disposeBag)

		Observable.combineLatest(spendCoin.asObservable(),
														 spendAmount.asObservable(),
														 getCoin.asObservable())
			.distinctUntilChanged({ (val1, val2) -> Bool in
			return val1.0 == val2.0 && val1.1 == val2.1 && val1.2 == val2.2
		}).throttle(1, scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] (val) in
			self?.minimumValueToBuy.value = nil
			self?.approximately.onNext("")
			self?.validateErrors()

			if let from = self?.selectedCoin?.transformToCoinName(),
				let to = val.2?.transformToCoinName(),
				let amountString = val.1?.replacingOccurrences(of: " ", with: ""),
				let amnt = Decimal(string: amountString), amnt > 0 {
				self?.calculateApproximately(fromCoin: from, amount: amnt, getCoin: to)
			}
		}).disposed(by: disposeBag)

		approximatelyReady.asObservable().subscribe(onNext: { [weak self] (val) in
			self?.validateErrors()
		}).disposed(by: disposeBag)

		exchangeDidTap.asObservable().subscribe(onNext: { [weak self] _ in
			self?.exchange()
		}).disposed(by: disposeBag)

		shouldClearForm.asObservable().subscribe(onNext: { [weak self] (val) in
			self?.spendAmount.onNext(nil)
			self?.getCoin.onNext("")
			self?.validateErrors()
		}).disposed(by: disposeBag)

		useMaxDidTap.subscribe(onNext: { [weak self] (_) in
			guard let _self = self else { return }
			let selectedAmount = CurrencyNumberFormatter.formattedDecimal(with: _self.selectedBalance ?? 0.0,
																																		formatter: _self.decimalFormatter)
			self?.spendAmount.onNext(selectedAmount)
		}).disposed(by: disposeBag)

		Session.shared.accounts.asDriver().drive(onNext: { [weak self] (val) in
			self?.shouldClearForm.value = true
		}).disposed(by: disposeBag)

		Session.shared.loadBalances()
	}

	// MARK: -

	let useMaxDidTap = PublishSubject<Void>()
	let exchangeDidTap = PublishSubject<Void>()

	var spendCoin = BehaviorSubject<String?>(value: nil)
	var spendCoinField = ReplaySubject<String?>.create(bufferSize: 2)

	var spendAmount = BehaviorSubject<String?>(value: nil)

	var hasMultipleCoinsObserver: Observable<Bool> {
		return Session.shared.allBalances.asObservable().map({ (balances) -> Bool in
			balances.keys.map {
				return Session.shared.allBalances.value[$0]?.count ?? 0
			}.reduce(0, +) > 1
		})
	}

	private var approximately = PublishSubject<String?>()

	var approximatelyReady = Variable<Bool>(false)

	var minimumValueToBuy = Variable<Decimal?>(nil)

	private let decimalsNoMantissaFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter
	private let decimalFormatter = CurrencyNumberFormatter.decimalFormatter

	lazy var isButtonEnabled: Observable<Bool> =
		Observable.combineLatest(self.getCoin.asObservable(),
														 self.spendAmount.asObservable(),
														 self.spendCoin.asObservable(),
														 self.isLoading.asObservable(),
														 self.approximatelyReady.asObservable()
			).map({ (val) -> Bool in
				let getCoin = val.0?.transformToCoinName()
				let spendAmount = val.1
				let spendCoin = val.2?.transformToCoinName()
				let isLoading = val.3
				let approximatelyReady = val.4

				guard !isLoading && approximatelyReady else {
					return false
				}

				guard let amountString = val.1,
					let amnt = Decimal(string: amountString),
					AmountValidator.isValid(amount: amnt) else {
					return false
				}

				guard getCoin != (self.selectedCoin ?? "") else {
					return false
				}

				return CoinValidator.isValid(coin: getCoin) && CoinValidator.isValid(coin: spendCoin)
	})

	// MARK: -

	private func calculateApproximately(fromCoin: String, amount: Decimal, getCoin: String) {
		approximatelyReady.value = false

		guard let maxComparableBalance = Decimal.PIPComparableBalance(from: selectedBalance ?? 0.0) else {
			return
		}

		var value = amount.decimalFromPIP()

		let isMax = (value > 0 && value == maxComparableBalance)

		if isMax {
			value = (selectedBalance ?? Decimal(0.0)).decimalFromPIP()
		}

		if !CoinValidator.isValid(coin: getCoin) {
			return
		}

		GateManager.shared.estimateCoinSell(coinFrom: fromCoin,
																				coinTo: getCoin.transformToCoinName(),
																				value: value,
																				isAll: isMax).do(onNext: { (res) in

		}, onError: { [weak self] (error) in
			if let err = error as? HTTPClientError, let log = err.userData?["message"] as? String {
				self?.approximately.onNext(log)
				return
			}

			if self?.hasCoin.value == true {
				self?.approximately.onNext("Estimate can't be calculated at the moment".localized())
			}
		}).subscribe(onNext: { [weak self] (res) in

			guard let _self = self else { return }

			let ammnt = res.0
			let val = ammnt.PIPToDecimal()

			let appr = (CurrencyNumberFormatter.formattedDecimal(with: val > 0 ? val : 0,
																													 formatter: _self.formatter)) + " " + getCoin
			self?.approximately.onNext(appr)

			var approximatelyRoundedVal = (ammnt * 0.9)
			approximatelyRoundedVal.round(.up)
			self?.minimumValueToBuy.value = approximatelyRoundedVal

			let gtCoin = try? self?.getCoin.value() ?? ""
			if getCoin.transformToCoinName() == gtCoin?.transformToCoinName() {
				self?.approximatelyReady.value = true
			}
		}).disposed(by: disposeBag)
	}

	override func validateErrors() {
		if let amountString = try? self.spendAmount.value() ?? "",
			amountString != "",
			let amount = Decimal(string: amountString) {

				if amount > (selectedBalance ?? 0.0) {
					amountError.value = "INSUFFICIENT FUNDS".localized()
				} else {
					amountError.value = nil
				}
		} else {
			let amountString = try? self.spendAmount.value() ?? ""
			if nil == amountString || amountString == "" {
				amountError.value = nil
			} else {
				amountError.value = "INCORRECT AMOUNT".localized()
			}
		}
	}

	func exchange() {

		guard let coinFrom = self.selectedCoin?.transformToCoinName(),
			let coinTo = try? self.getCoin.value()?.transformToCoinName() ?? "",
			let amount = try? self.spendAmount.value() ?? "",
			let selectedAddress = self.selectedAddress,
			let minimumBuyValue = self.minimumValueToBuy.value
		else {
			return
		}

		self.processExchange(coinFrom: coinFrom,
												 coinTo: coinTo,
												 amount: amount,
												 selectedAddress: selectedAddress,
												 minimumBuyValue: minimumBuyValue).subscribe(onNext: { [weak self] (val) in
			self?.shouldClearForm.value = true
			self?.successMessage.onNext(NotifiableSuccess(title: "Coins have been successfully spent".localized(),
																										text: nil))
		}, onError: { [weak self] (error) in
			self?.handleError(error)
		}, onCompleted: {
			Session.shared.loadBalances()
			Session.shared.loadTransactions()
			Session.shared.loadDelegatedBalance()
		}).disposed(by: self.disposeBag)
	}

	private func handleError(_ err: Error?) {

		var title = "Can't send Transaction"
		var text = ""

		if let mvError = err as? SpendCoindsViewModelError {
			switch mvError {
			case .canNotCreateTx:
				title = "Can't create transaction".localized()
				break

			case .incorrectParams:
				title = "Incorrect params".localized()
				break

			case .noPrivateKey:
				title = "No private key found".localized()
				break

			case .canNotGetNonce:
				title = "Can't get nonce".localized()
				break
			}
		}

		if let apiError = err as? HTTPClientError,
			let errorCode = apiError.userData?["code"] as? Int {
			if errorCode == 107 {
				title = "Not enough coins to spend".localized()
			} else if errorCode == 103 {
				title = "Coin reserve balance is not sufficient for transaction".localized()
			} else {
				if let msg = apiError.userData?["message"] as? String {
					title = msg
				} else {
					title = "An error occured".localized()
				}
			}
		}

		self.errorNotification.onNext(NotifiableError(title: title, text: text))
	}

	func processExchange(coinFrom: String,
											 coinTo: String,
											 amount: String,
											 selectedAddress: String,
											 minimumBuyValue: Decimal) -> Observable<String?> {
		return Observable<String?>.create { [weak self] observer -> Disposable in

			guard let _self = self else { return Disposables.create() }

			guard let amnt = Decimal(string: amount),
				let minimumBuyVal = BigUInt(decimal: minimumBuyValue),
				let convertVal = BigUInt(decimal: amnt, fromPIP: true),
				let maxComparableSelectedBalance = Decimal.PIPComparableBalance(from: _self.selectedBalance ?? 0.0),
				convertVal > 0 else {
					observer.onError(SpendCoindsViewModelError.incorrectParams)
					return Disposables.create()
			}

			//Getting comparable value, since we are comparing not exact numbers, but it's shortened representations

			let maxComparableBalanceString = _self.decimalsNoMantissaFormatter.string(from: maxComparableSelectedBalance as NSNumber) ?? ""
			let isMax = (convertVal > 0 && convertVal == (BigUInt(maxComparableBalanceString) ?? BigUInt(0)))

			DispatchQueue.global(qos: .userInitiated).async {

				guard let pk = _self.accountManager.privateKey(for: selectedAddress) else {
					observer.onError(SpendCoindsViewModelError.noPrivateKey)
					return
				}

				Observable.zip(GateManager.shared.nonce(address: selectedAddress),
											 GateManager.shared.minGasPrice()).flatMap({ (val) -> Observable<String?> in
					let nonce = Decimal(val.0 + 1)

					var tx: RawTransaction!
					let coin = _self.canPayComissionWithBaseCoin() ? Coin.baseCoin().symbol! : coinFrom
					let isBaseCoin = Coin.baseCoin().symbol! == coinFrom

					//TODO: remove after https://github.com/MinterTeam/minter-go-node/issues/224
					let minValBuy = /*minimumBuyVal*/BigUInt(0)

					//Using SellAll TX in case we're using maximum amount or there is no base coin (MNT, BIP) to pay commission
					if isMax && (isBaseCoin || !_self.canPayComissionWithBaseCoin()) {
						tx = SellAllCoinsRawTransaction(nonce: BigUInt(decimal: nonce)!,
																						gasPrice: val.1,
																						gasCoin: coin,
																						coinFrom: coinFrom,
																						coinTo: coinTo,
																						minimumValueToBuy: minValBuy)
					} else {
						tx = SellCoinRawTransaction(nonce: BigUInt(decimal: nonce)!,
																				gasPrice: val.1,
																				gasCoin: coin,
																				coinFrom: coinFrom,
																				coinTo: coinTo,
																				value: convertVal,
																				minimumValueToBuy: minValBuy)
					}

					let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: pk.raw.toHexString())
					return GateManager.shared.send(rawTx: signedTx)
				}).subscribe(onNext: { [observer] (hash) in
					observer.onNext(hash)
					observer.onCompleted()
				}, onError: { [observer] err in
					observer.onError(err)
				}).disposed(by: _self.disposeBag)
			}

			return Disposables.create()
		}.do(onCompleted: { [weak self] in
			self?.isLoading.onNext(false)
		}, onSubscribe: { [weak self] in
			self?.isLoading.onNext(true)
		}, onDispose: { [weak self] in
			self?.isLoading.onNext(false)
		})
	}

}
