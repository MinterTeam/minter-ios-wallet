//
//  SendSendViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 13/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import MinterCore
import MinterExplorer
import MinterMy
import BigInt
import SwiftValidator
import RxAppState
import RxBiBinding
import RxRelay

struct AccountPickerItem {
	var title: String?
	var address: String?
	var balance: Decimal?
	var coin: String?
}

class SendViewModel: BaseViewModel, ViewModelProtocol { // swiftlint:disable:this type_body_length

	enum SendViewModelError: Error {
		case noPrivateKey
		case insufficientFunds
	}

	// MARK: - ViewModelProtocol

	var input: SendViewModel.Input!
	var output: SendViewModel.Output!
	struct Input {
		var payload: AnyObserver<String?>
		var txScanButtonDidTap: AnyObserver<Void>
		var didScanQR: AnyObserver<String?>
	}
	struct Output {
		var errorNotification: Observable<NotifiableError?>
		var txErrorNotification: Observable<NotifiableError?>
		var popup: Observable<PopupViewController?>
		var showViewController: Observable<UIViewController?>
	}

	// MARK: -

	var title: String {
		return "Send".localized()
	}

	typealias FormChangedObservable = (String?, String?, String?, String?)
	private let coinSubject = BehaviorRelay<String?>(value: "")
	private let recipientSubject = BehaviorRelay<String?>(value: "")
	private let addressSubject = BehaviorRelay<String?>(value: "")
	private var recipientAddress = BehaviorRelay<String?>(value: nil)
	private let amountSubject = BehaviorRelay<String?>(value: "")
	private var formChangedObservable: Observable<FormChangedObservable> {
		return Observable.combineLatest(coinSubject.asObservable(),
																		addressSubject.asObservable(),
																		amountSubject.asObservable(),
																		payloadSubject.asObservable())
	}

	let fakePK = Data(hex: "678b3252ce9b013cef922687152fb71d45361b32f8f9a57b0d11cc340881c999").toHexString()

	// MARK: -
	
	private var showViewControllerSubject = PublishSubject<UIViewController?>()

	var sections = Variable([BaseTableSectionItem]())
	private var _sections = Variable([BaseTableSectionItem]())

	//Formatters
	private let formatter = CurrencyNumberFormatter.decimalFormatter
	private let shortDecimalFormatter = CurrencyNumberFormatter.decimalShortFormatter
	private let decimalsNoMantissaFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter
	private let coinFormatter = CurrencyNumberFormatter.coinFormatter

	//Loading observables
	private var isLoadingAddressSubject = PublishSubject<Bool>()
	private var isLoadingNonceSubject = PublishSubject<Bool>()

	//State obervables
	private var didScanQRSubject = PublishSubject<String?>()
	private var addressStateSubject = PublishSubject<TextViewTableViewCell.State>()
	private var amountStateSubject = PublishSubject<TextFieldTableViewCell.State>()
	private var payloadStateObservable = PublishSubject<TextViewTableViewCell.State>()
	private var selectedAddress: String?
	private var selectedAddressBalance: Decimal? {
		guard nil != selectedAddress && nil != selectedCoin.value else {
			return nil
		}
		let balance = Session.shared.allBalances.value.filter { (val) -> Bool in
			if selectedAddress != val.key { return false }
			return (nil != val.value[selectedCoin.value!])
		}
		return balance[selectedAddress!]?[selectedCoin.value!]
	}

	var selectedBalanceText: String? {
		return CurrencyNumberFormatter.formattedDecimal(with: selectedAddressBalance ?? 0,
																										formatter: formatter)
	}

	var baseCoinBalance: Decimal {
		let balances = Session.shared.allBalances.value
		if
			let ads = selectedAddress,
			let coin = Coin.baseCoin().symbol,
			let smt = balances[ads],
			let blnc = smt[coin] {
				return blnc
		}
		return 0
	}

	var isBaseCoin: Bool? {
		guard selectedCoin.value != nil else {
			return nil
		}
		return selectedCoin.value == Coin.baseCoin().symbol!
	}

	private func canPayCommissionWithBaseCoin(isDelegate: Bool = false) -> Bool {
		let balance = self.baseCoinBalance
		if balance >= commission(isDelegate: isDelegate) {
			return true
		}
		return false
	}

	private func commission(isDelegate: Bool = false) -> Decimal {
		let payloadCom = payloadComission().decimalFromPIP()
		let val: Decimal
		if isDelegate {
			val = (payloadCom + RawTransactionType.delegate.commission()).PIPToDecimal()
		} else {
			val = (payloadCom + RawTransactionType.sendCoin.commission()).PIPToDecimal()
		}
		return Decimal(Session.shared.currentGasPrice.value) * val
	}

	private func payloadComission() -> Decimal {
		return Decimal((try? clearPayloadSubject.value() ?? "")?.count ?? 0) * RawTransaction.payloadByteComissionPrice
	}

	private func payload() -> String {
		return (try? clearPayloadSubject.value() ?? "") ?? ""
	}

	private var lastSentTransactionHash: String?
	private var selectedCoin = Variable<String?>(nil)
	private var forceUpdateFee = PublishSubject<Void>()
	private let accountManager = AccountManager()
	private let infoManager = InfoManager.default
	private let payloadSubject = BehaviorSubject<String?>(value: "")
	private let clearPayloadSubject = BehaviorSubject<String?>(value: "")
	private let errorNotificationSubject = PublishSubject<NotifiableError?>()
	private let txErrorNotificationSubject = PublishSubject<NotifiableError?>()
	private let txScanButtonDidTap = PublishSubject<Void>()
	private let popupSubject = PublishSubject<PopupViewController?>()
	private var currentGas = BehaviorSubject<Int>(value: RawTransactionDefaultGasPrice)
	var gasObservable: Observable<String> {
		return Observable.combineLatest(forceUpdateFee.asObservable(),
																		currentGas.asObservable(),
																		clearPayloadSubject.asObservable(),
																		formChangedObservable)
			.map({ [weak self] (obj) -> String in
				let payloadData = obj.3.3?.data(using: .utf8)
				let recipient = obj.3.1
				return self?.comissionText(recipient: recipient ?? "",
																	 for: obj.1,
																	 payloadData: payloadData) ?? ""
		})
	}

	// MARK: -

	override init() { // swiftlint:disable:this function_body_length cyclomatic_complexity
		super.init()

		self.input = Input(payload: payloadSubject.asObserver(),
											 txScanButtonDidTap: txScanButtonDidTap.asObserver(),
											 didScanQR: didScanQRSubject.asObserver())
		self.output = Output(errorNotification: errorNotificationSubject.asObservable(),
												 txErrorNotification: txErrorNotificationSubject.asObservable(),
												 popup: popupSubject.asObservable(),
												 showViewController: showViewControllerSubject.asObservable())

		payloadSubject.asObservable().subscribe(onNext: { (payld) in
			self.forceUpdateFee.onNext(())
			let data = (payld ?? "").data(using: .utf8) ?? Data()
			if data.count > RawTransaction.maxPayloadSize {
				self.payloadStateObservable.onNext(.invalid(error: "TOO MANY SYMBOLS".localized()))
			} else {
				self.payloadStateObservable.onNext(.default)
			}
		}).disposed(by: disposeBag)

		payloadSubject.asObservable().map({ (val) -> String? in
			var newVal = val
			while newVal?.data(using: .utf8)?.count ?? 0 > RawTransaction.maxPayloadSize {
				newVal?.removeLast()
			}
			return newVal
		}).subscribe(onNext: { [weak self] (val) in
			self?.clearPayloadSubject.onNext(val)
		}).disposed(by: disposeBag)

		Session.shared
			.allBalances
			.asObservable()
			.distinctUntilChanged()
			.subscribe(onNext: { [weak self] (val) in
				if
					let addr = self?.selectedAddress,
					let selCoin = self?.selectedCoin.value, nil == val[addr]?[selCoin] {
						self?.selectedAddress = nil
						self?.selectedCoin.value = nil
						self?.coinSubject.accept(nil)
				}
				self?.sections.value = self?.createSections() ?? []
			}).disposed(by: disposeBag)

		sections
			.asObservable()
			.subscribe(onNext: { [weak self] (items) in
				self?._sections.value = items
			}).disposed(by: disposeBag)

		Session
			.shared
			.accounts
			.asDriver()
			.drive(onNext: { [weak self] (val) in
				self?.clear()
				self?.sections.value = self?.createSections() ?? []
			}).disposed(by: disposeBag)

		didScanQRSubject
			.asObservable()
			.subscribe(onNext: { [weak self] (val) in
				if true == val?.isValidPublicKey() || true == val?.isValidAddress() {
					self?.recipientSubject.accept(val)
				} else if
					let url = URL(string: val ?? ""),
					url.host == "tx" || url.path.contains("tx") {

					if let rawViewController = RawTransactionRouter.viewController(path: [url.host ?? ""], param: url.params()) {
						self?.showViewControllerSubject.onNext(rawViewController)
					} else {
						//show error
						self?.errorNotificationSubject.onNext(NotifiableError(title: "Invalid transcation data".localized(), text: nil))
					}
				} else if let rawViewController = RawTransactionRouter.viewController(path: ["tx"], param: ["d": val ?? ""]) {
						self?.showViewControllerSubject.onNext(rawViewController)
				} else {
					self?.errorNotificationSubject.onNext(NotifiableError(title: "Invalid transcation data".localized(), text: nil))
				}
		}).disposed(by: disposeBag)

		NotificationCenter
			.default
			.rx
			.notification(sendViewControllerAddressNotification)
			.debounce(.seconds(1), scheduler: MainScheduler.instance)
			.subscribe(onNext: { [weak self] (not) in
				if let recipient = not.userInfo?["address"] as? String {
					if recipient.isValidAddress() || recipient.isValidPublicKey() {
						self?.recipientSubject.accept(recipient)
					}
				}
			}).disposed(by: disposeBag)

		formChangedObservable.subscribe(onNext: { [weak self] (val) in
			let recipient = val.1
			let amount = val.2

			if self?.recipientSubject.value == nil || self?.recipientSubject.value == "" {
				self?.addressStateSubject.onNext(.default)
			}

			if amount == nil || amount == "" {
				self?.amountStateSubject.onNext(.default)
			} else {
				let amnt = amount ?? ""
				if let dec = Decimal(string: amnt), dec >= 0 {
					self?.amountStateSubject.onNext(.default)
				} else {
					self?.amountStateSubject.onNext(.invalid(error: "AMOUNT IS INCORRECT".localized()))
				}
			}
		}).disposed(by: disposeBag)

		recipientSubject
			.do(onNext: { [weak self] (rec) in
				if self?.isValidMinterRecipient(recipient: rec ?? "") ?? false {
					self?.addressSubject.accept(rec)
				} else {
					self?.addressSubject.accept(nil)
				}
			})
			.filter { [weak self] in
				return !(self?.isValidMinterRecipient(recipient: $0 ?? "") ?? false)
			}
			.throttle(2.0, scheduler: MainScheduler.instance)
			.distinctUntilChanged()
			.do(onNext: { [weak self] (rec) in
				if !(self?.isToValid(to: rec ?? "") ?? false) {
					if (rec?.count ?? 0) > 66 {
						self?.addressStateSubject.onNext(.invalid(error: "TOO MANY SYMBOLS".localized()))
					} else if !(self?.shouldShowRecipientError(for: rec ?? "") ?? false) {
						self?.addressStateSubject.onNext(.default)
					} else {
						self?.addressStateSubject.onNext(.invalid(error: "INVALID VALUE".localized()))
					}
				}
				if self?.isValidMinterRecipient(recipient: rec ?? "") ?? false {
					self?.addressSubject.accept(rec)
				}
			})
			.filter({ [weak self] (rec) -> Bool in
				return self?.isToValid(to: rec ?? "") ?? false
			})
			.flatMap { (rec) -> Observable<Event<String>> in
				return InfoManager.default.address(term: rec ?? "").materialize()
			}.do(onNext: { [weak self] (_) in
				self?.isLoadingAddressSubject.onNext(false)
			}, onError: { [weak self] (_) in
				self?.isLoadingAddressSubject.onNext(false)
			}, onCompleted: { [weak self] in
				self?.isLoadingAddressSubject.onNext(false)
			}, onSubscribe: { [weak self] in
				self?.isLoadingAddressSubject.onNext(true)
			}).subscribe(onNext: { [weak self] (event) in
				switch event {
				case .completed:
					break
				case .next(let addr):
					if addr.isValidAddress() || addr.isValidPublicKey() {
						self?.addressSubject.accept(addr)
					}
					break
				case .error(_):
					self?.addressStateSubject.onNext(.invalid(error: "USERNAME CAN NOT BE FOUND".localized()))
					break
				}
			}).disposed(by: disposeBag)
	}

	// MARK: - Sections

	func createSections() -> [BaseTableSectionItem] {
		let username = UsernameTableViewCellItem(reuseIdentifier: "UsernameTableViewCell",
																						 identifier: CellIdentifierPrefix.address.rawValue)
		username.title = "TO (MX ADDRESS OR PUBLIC KEY)".localized()
		if let appDele = UIApplication.realAppDelegate(), appDele.isTestnet {
			username.title = "TO (@USERNAME, EMAIL, MX ADDRESS OR PUBLIC KEY)".localized()
		}
		username.isLoadingObservable = isLoadingAddressSubject.asObservable()
		username.stateObservable = addressStateSubject.asObservable()
		username.keybordType = .emailAddress
		(username.text <-> recipientSubject).disposed(by: disposeBag)

		let coin = PickerTableViewCellItem(reuseIdentifier: "PickerTableViewCell",
																			 identifier: CellIdentifierPrefix.coin.rawValue + (selectedBalanceText ?? ""))
		coin.title = "COIN".localized()
		if nil != self.selectedAddress && nil != self.selectedCoin.value {
			let item = accountPickerItems().filter { (item) -> Bool in
				if let object = item.object as? AccountPickerItem {
					return selectedAddress == object.address && selectedCoin.value == object.coin
				}
				return false
			}
			if let first = item.first {
				coin.selected = first
			}
		} else if let item = accountPickerItems().first {
			coin.selected = item
			if let object = item.object as? AccountPickerItem {
				selectedAddress = object.address
				selectedCoin.value = object.coin
				coinSubject.accept(object.coin)
			}
		}

		let amount = AmountTextFieldTableViewCellItem(reuseIdentifier: "AmountTextFieldTableViewCell",
																									identifier: CellIdentifierPrefix.amount.rawValue)
		amount.title = "AMOUNT".localized()
		amount.stateObservable = amountStateSubject.asObservable()
		amount.keyboardType = .decimalPad
		(amount.text <-> amountSubject).disposed(by: disposeBag)
		amount
			.output?
			.didTapUseMax
			.asDriver(onErrorJustReturn: ())
			.drive(onNext: { [weak self] (_) in
				guard let _self = self else { return } //swiftlint:disable:this identifier_name
				let selectedAmount = CurrencyNumberFormatter.formattedDecimal(with: _self.selectedAddressBalance ?? 0.0,
																																			formatter: _self.formatter)
				self?.amountSubject.accept(selectedAmount)
			}).disposed(by: disposeBag)

		let payload = TextViewTableViewCellItem(reuseIdentifier: "SendPayloadTableViewCell",
																						identifier: "SendPayloadTableViewCell_Payload")
		payload.title = "PAYLOAD MESSAGE (max 1024 symbols)".localized()
		payload.keybordType = .default
		payload.stateObservable = payloadStateObservable.asObservable()
		payload.titleObservable = clearPayloadSubject.asObservable()

		let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell",
																				identifier: CellIdentifierPrefix.fee.rawValue)
		fee.title = "Transaction Fee".localized()
		let payloadData = (try? clearPayloadSubject.value() ?? "")?.data(using: .utf8)
		fee.subtitle = self.comissionText(recipient: recipientSubject.value ?? "", for: 1, payloadData: payloadData)
		fee.subtitleObservable = self.gasObservable

		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
																							 identifier: CellIdentifierPrefix.separator.rawValue)

		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																			 identifier: CellIdentifierPrefix.blank.rawValue)

		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																				 identifier: CellIdentifierPrefix.button.rawValue)
		button.title = "SEND".localized()
		button.buttonPattern = "purple"
		button.isButtonEnabledObservable = formChangedObservable.map({ (val) -> Bool in
			let coin = val.0
			let recipient = val.1
			let amount = val.2
			return !(recipient ?? "").isEmpty && !(amount ?? "").isEmpty && !(coin ?? "").isEmpty
		})

		button
			.output?
			.didTapButton
			.asDriver(onErrorJustReturn: ())
			.drive(onNext: { [weak self] (_) in
				self?.sendButtonTaped()
			}).disposed(by: self.disposeBag)

		var section = BaseTableSectionItem(header: "")
		section.items = [coin, username, amount, payload, fee, separator, blank, button]
		return [section]
	}

	// MARK: - Validation

	func submitField(item: BaseCellItem, value: String) {
		self._sections.value = self.createSections()
	}

	func isToValid(to: String) -> Bool {
		if to.count > 66 {
			return false
		}
		//username and address
		return to.isValidUsername() || self.isValidMinterRecipient(recipient: to)
	}

	func shouldShowRecipientError(for recipient: String) -> Bool {
		return !recipient.isEmpty && recipient.count >= 6
	}

	func isValidMinterRecipient(recipient: String) -> Bool {
		return recipient.isValidAddress() || recipient.isValidPublicKey()
	}

	func isAmountValid(amount: Decimal) -> Bool {
		return AmountValidator.isValid(amount: amount)
	}

	// MARK: - Rows

	func rowsCount(for section: Int) -> Int {
		return _sections.value[safe: section]?.items.count ?? 0
	}

	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return _sections.value[safe: section]?.items[safe: row]
	}

	// MARK: -

	func accountPickerItems() -> [PickerTableViewCellPickerItem] {
		var ret = [AccountPickerItem]()
		let balances = Session.shared.allBalances.value
		balances.keys.forEach { (address) in
			var blns = balances[address]?.keys.filter({ (coin) -> Bool in
				return coin != (Coin.baseCoin().symbol ?? "")
			}).sorted(by: { (val1, val2) -> Bool in
				return val1 < val2
			})
			blns?.insert((Coin.baseCoin().symbol ?? ""), at: 0)
			blns?.forEach({ (coin) in
				let balance = (balances[address]?[coin] ?? 0.0)
				let balanceString = CurrencyNumberFormatter.formattedDecimal(with: balance,
																																		 formatter: coinFormatter)
				let title = coin + " (" + balanceString + ")"
				let item = AccountPickerItem(title: title,
																		 address: address,
																		 balance: balance,
																		 coin: coin)
				ret.append(item)
			})
		}
		return ret.map({ (account) -> PickerTableViewCellPickerItem in
			return PickerTableViewCellPickerItem(title: account.title, object: account)
		})
	}

	func selectedPickerItem() -> PickerTableViewCellPickerItem? {
		guard let adrs = selectedAddress,
			let coin = selectedCoin.value else {
				return nil
		}
		guard let balances = Session.shared.allBalances.value[adrs],
			let balance = balances[coin] else {
				return nil
		}
		let balanceString = CurrencyNumberFormatter.formattedDecimal(with: balance,
																																 formatter: coinFormatter)
		let title = coin + " (" + balanceString + ")"
		let item = AccountPickerItem(title: title,
																 address: adrs,
																 balance: balance,
																 coin: coin)
		return PickerTableViewCellPickerItem(title: item.title, object: item)
	}

	// MARK: -

	func accountPickerSelect(item: AccountPickerItem) {
		let balance = Session.shared.allBalances.value.filter { (acc) -> Bool in
			return item.address?.stripMinterHexPrefix().lowercased() == acc.key.stripMinterHexPrefix().lowercased()
		}.first

		guard nil != balance else {
			return
		}
		selectedAddress = balance?.key
		selectedCoin.value = item.coin
		coinSubject.accept(item.coin)
	}

	// MARK: -

	func newSend() {
		Observable
			.combineLatest(
				GateManager.shared.nonce(address: "Mx" + selectedAddress!),
				GateManager.shared.minGas()
			).do(onError: { [weak self] (error) in
				self?.errorNotificationSubject.onNext(NotifiableError(title: "Can't get nonce"))
			}, onCompleted: { [weak self] in
				self?.isLoadingNonceSubject.onNext(false)
			}, onSubscribe: { [weak self] in
				self?.isLoadingNonceSubject.onNext(true)
			}).map({ (val) -> (Int, Int) in
				return (val.0+1, val.1)
			}).flatMapLatest({ (val) -> Observable<((Int, Int), FormChangedObservable)> in
				return Observable.zip(
					Observable.just(val),
					self.formChangedObservable.asObservable())
			}).flatMapLatest({ (val) -> Observable<String?> in
				let nonce = BigUInt(val.0.0)
				let amount = (Decimal(string: val.1.2 ?? "") ?? Decimal(0))
				let coin = val.1.0 ?? Coin.baseCoin().symbol!
				let recipient = val.1.1 ?? ""
				let payload = val.1.3 ?? ""
				return self.prepareTx(nonce: nonce,
												 amount: amount,
												 selectedCoinBalance: self.selectedAddressBalance ?? 0.0,
												 recipient: recipient,
												 coin: coin,
												 payload: payload)
			}).flatMapLatest({ (signedTx) -> Observable<String?> in
				return GateManager.shared.send(rawTx: signedTx)
			}).subscribe(onNext: { [weak self] (val) in
				self?.lastSentTransactionHash = val

				self?.sections.value = self?.createSections() ?? []
				let rec = self?.recipientSubject.value ?? ""
				let address = self?.addressSubject.value ?? ""

				if let sentViewModel = self?.sentViewModel(to: rec, address: address) {
					let popup = PopupRouter.sentPopupViewCointroller(viewModel: sentViewModel)
					self?.popupSubject.onNext(popup)
				}

				DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2), execute: {
					Session.shared.loadTransactions()
					Session.shared.loadBalances()
					Session.shared.loadDelegatedBalance()
				})
				self?.clear()
			}, onError: { [weak self] (error) in
				self?.handle(error: error)
			}, onCompleted: { [weak self] in
				self?.isLoadingNonceSubject.onNext(false)
			}).disposed(by: disposeBag)
	}

	func clear() {
		self.clearPayloadSubject.onNext(nil)
		self.recipientSubject.accept(nil)
		self.amountSubject.accept(nil)
		self.payloadSubject.onNext(nil)
	}

	func sendButtonTaped() {
		let recipient = recipientSubject.value ?? ""
		let amount = Decimal(string: amountSubject.value ?? "") ?? 0
		let address = addressSubject.value ?? ""
		let sendVM = self.sendPopupViewModel(to: recipient,
																				 address: address,
																				 amount: amount)
		let sendPopup = Storyboards.Popup.instantiateInitialViewController()
		sendPopup.viewModel = sendVM
		self.popupSubject.onNext(sendPopup)
	}

	func submitSendButtonTaped() {
		newSend()
	}

	func sendCancelButtonTapped() {}

	func viewDidAppear() {
		GateManager
			.shared
			.minGasPrice()
			.subscribe(onNext: { [weak self] (gas) in
				self?.currentGas.onNext(gas)
		}).disposed(by: disposeBag)
	}

	// MARK: -

	func rawTransaction(nonce: BigUInt,
											gasCoin: String,
											recipient: String,
											value: BigUInt,
											coin: String,
											payload: String) -> RawTransaction {
		let rawTx: RawTransaction
		let gasPrice = (try? currentGas.value()) ?? 1
		if recipient.isValidPublicKey() {
			rawTx = DelegateRawTransaction(nonce: nonce,
																		 gasPrice: gasPrice,
																		 gasCoin: gasCoin,
																		 publicKey: recipient,
																		 coin: coin,
																		 value: value)
		} else {
			rawTx = SendCoinRawTransaction(nonce: nonce,
																		 gasPrice: gasPrice,
																		 gasCoin: gasCoin,
																		 to: recipient,
																		 value: value,
																		 coin: coin.uppercased())
		}
		rawTx.payload = payload.data(using: .utf8) ?? Data()
		return rawTx
	}

	func prepareTx(
		nonce: BigUInt,
		amount: Decimal,
		selectedCoinBalance: Decimal,
		recipient: String,
		coin: String,
		payload: String) -> Observable<String?> {
			return Observable.create { (observer) -> Disposable in
				let isMax = (Decimal.PIPComparableBalance(from: amount)
					== Decimal.PIPComparableBalance(from: selectedCoinBalance))
				let isBaseCoin = coin == Coin.baseCoin().symbol!
				let preparedAmount = amount.decimalFromPIP()
				let commission = self.commission(isDelegate: recipient.isValidPublicKey())
				if
					let mnemonic = self.accountManager.mnemonic(for: self.selectedAddress!),
					let seed = self.accountManager.seed(mnemonic: mnemonic),
					let newPk = try? self.accountManager.privateKey(from: seed) {

					let isPublicKey = recipient.isValidPublicKey()
					var gasCoin: String = Coin.baseCoin().symbol!
					var value: BigUInt = BigUInt(0)

					if isMax {
						if isBaseCoin {
							let amountWithCommission = max(0, amount - commission)
							if selectedCoinBalance < amountWithCommission {
								observer.onError(SendViewModelError.insufficientFunds)
							} else {
								value = BigUInt(decimal: amountWithCommission.decimalFromPIP()) ?? BigUInt(0)
							}
						} else if !self.canPayCommissionWithBaseCoin(isDelegate: isPublicKey) {
							let preparedAmountBigInt = BigUInt(decimal: preparedAmount)!
							let fakeTx: RawTransaction = self.rawTransaction(nonce: nonce,
																													 gasCoin: coin,
																													 recipient: recipient,
																													 value: preparedAmountBigInt,
																													 coin: coin,
																													 payload: payload)
							let fakeSignedTx = RawTransactionSigner.sign(rawTx: fakeTx, privateKey: self.fakePK)
							GateManager.shared.estimateTXCommission(for: fakeSignedTx!) { (commission, error) in
								guard error == nil else {
									observer.onError(error!)
									observer.onCompleted()
									return
								}
								let normalizedCommission = commission!.PIPToDecimal()
								let normalizedAmount = BigUInt(decimal: (amount - normalizedCommission).decimalFromPIP()) ?? BigUInt(0)
								let rawTx: RawTransaction = self.rawTransaction(nonce: nonce,
																																gasCoin: coin,
																																recipient: recipient,
																																value: normalizedAmount,
																																coin: coin,
																																payload: payload)
								let signedTx = RawTransactionSigner.sign(rawTx: rawTx, privateKey: newPk.raw.toHexString())
								observer.onNext(signedTx)
								observer.onCompleted()
							}
							return Disposables.create()
						} else {
							gasCoin = (self.canPayCommissionWithBaseCoin(isDelegate: isPublicKey)) ? Coin.baseCoin().symbol! : coin
							value = BigUInt(decimal: amount.decimalFromPIP()) ?? BigUInt(0)
						}
					} else {
						gasCoin = (self.canPayCommissionWithBaseCoin(isDelegate: isPublicKey)) ? Coin.baseCoin().symbol! : coin
						value = BigUInt(decimal: amount.decimalFromPIP()) ?? BigUInt(0)
					}
					let rawTx: RawTransaction = self.rawTransaction(nonce: nonce,
																													gasCoin: gasCoin,
																													recipient: recipient,
																													value: value,
																													coin: coin,
																													payload: payload)

					let pkString = newPk.raw.toHexString()
					let signedTx = RawTransactionSigner.sign(rawTx: rawTx, privateKey: pkString)
					observer.onNext(signedTx)
					observer.onCompleted()
				} else {
					observer.onError(SendViewModelError.noPrivateKey)
					observer.onCompleted()
				}
				return Disposables.create()
			}
	}

	private func comissionText(recipient: String, for gas: Int, payloadData: Data? = nil) -> String {
		let payloadCom = Decimal((payloadData ?? Data()).count) * RawTransaction.payloadByteComissionPrice.decimalFromPIP()
		var commission = (RawTransactionType.sendCoin.commission() + payloadCom).PIPToDecimal() * Decimal(gas)
		if recipient.isValidPublicKey() {
			commission = (RawTransactionType.delegate.commission() + payloadCom).PIPToDecimal() * Decimal(gas)
		}
		let balanceString = CurrencyNumberFormatter.formattedDecimal(with: commission,
																																 formatter: self.coinFormatter)
		return balanceString + " " + (Coin.baseCoin().symbol ?? "")
	}

	// MARK: -

	func lastTransactionExplorerURL() -> URL? {
		guard nil != lastSentTransactionHash else {
			return nil
		}
		return URL(string: MinterExplorerBaseURL! + "/transactions/" + (lastSentTransactionHash ?? ""))
	}

	// MARK: -

	private func handle(error: Error) {
		var notification: NotifiableError
		if let error = error as? HTTPClientError {
			if let errorMessage = error.userData?["log"] as? String {
				notification = NotifiableError(title: "An Error Occurred".localized(),
																			 text: errorMessage)
			} else {
				notification = NotifiableError(title: "An Error Occurred".localized(),
																			 text: "Unable to send transaction".localized())
			}
		} else {
			notification = NotifiableError(title: "An Error Occurred".localized(),
																		 text: "Unable to send transaction".localized())
		}
		self.txErrorNotificationSubject.onNext(notification)
	}
}

extension SendViewModel {

	// MARK: - ViewModels

	func sendPopupViewModel(to: String, address: String, amount: Decimal) -> SendPopupViewModel {
		let viewModel = SendPopupViewModel()
		viewModel.amount = amount
		viewModel.coin = selectedCoin.value
		viewModel.username = to
		if to.isValidPublicKey() {
			viewModel.avatarImage = UIImage(named: "delegateImage")
		} else {
			viewModel.avatarImageURL = MinterMyAPIURL.avatarAddress(address: address).url()
		}
		viewModel.popupTitle = "You're Sending".localized()
		viewModel.buttonTitle = "SEND".localized()
		viewModel.cancelTitle = "CANCEL".localized()
		return viewModel
	}

	func sentViewModel(to: String, address: String) -> SentPopupViewModel {
		let viewModel = SentPopupViewModel()
		viewModel.actionButtonTitle = "VIEW TRANSACTION".localized()
		if to.isValidPublicKey() {
			viewModel.avatarImage = UIImage(named: "delegateImage")
		} else {
			viewModel.avatarImageURL = MinterMyAPIURL.avatarAddress(address: address).url()
		}
		viewModel.secondButtonTitle = "CLOSE".localized()
		viewModel.username = to
		viewModel.title = "Success!".localized()
		return viewModel
	}
}

extension SendViewModel {
	enum CellIdentifierPrefix: String {
		case address = "UsernameTableViewCell_Address"
		case coin = "PickerTableViewCell_Coin"
		case amount = "AmountTextFieldTableViewCell_Amount"
		case fee = "TwoTitleTableViewCell_TransactionFee"
		case separator = "SeparatorTableViewCell"
		case blank = "BlankTableViewCell"
		case swtch = "SwitchTableViewCell"
		case button = "ButtonTableViewCell"
	}
} // swiftlint:disable:this file_length
