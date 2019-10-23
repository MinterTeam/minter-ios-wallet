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

struct AccountPickerItem {
	var title: String?
	var address: String?
	var balance: Decimal?
	var coin: String?
}

class SendViewModel: BaseViewModel, ViewModelProtocol {

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
		var showViewController: Observable<UIViewController?>
		var setAddressField: Observable<String?>
	}

	// MARK: -

	enum cellIdentifierPrefix: String {
		case address = "UsernameTableViewCell_Address"
		case coin = "PickerTableViewCell_Coin"
		case amount = "AmountTextFieldTableViewCell_Amount"
		case fee = "TwoTitleTableViewCell_TransactionFee"
		case separator = "SeparatorTableViewCell"
		case blank = "BlankTableViewCell"
		case swtch = "SwitchTableViewCell"
		case button = "ButtonTableViewCell"
	}

	// MARK: -

	var title: String {
		get {
			return "Send".localized()
		}
	}

	private var toField: String? {
		didSet {
			self.getAddress()
			self.forceUpdateFee.onNext(())
		}
	}

	private var amountField: String? {
		didSet {
			self.amount.value = Decimal(string: amountField ?? "0.0")
			
			if isAmountValid(amount: self.amount.value ?? 0) {
				amountStateObservable.value = .default
			}
		}
	}

	let fakePK = Data(hex: "678b3252ce9b013cef922687152fb71d45361b32f8f9a57b0d11cc340881c999").toHexString()

	// MARK: -

	var sections = Variable([BaseTableSectionItem]())
	private var _sections = Variable([BaseTableSectionItem]())

	//Formatters
	private let formatter = CurrencyNumberFormatter.decimalFormatter
	private let shortDecimalFormatter = CurrencyNumberFormatter.decimalShortFormatter
	private let decimalsNoMantissaFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter
	private let coinFormatter = CurrencyNumberFormatter.coinFormatter

	//Loading observables
	private var isLoadingAddress = Variable(false)
	private var isLoadingNonce = Variable(false)

	//State obervables
	private var addressStateObservable = Variable(TextViewTableViewCell.State.default)
	private var amountStateObservable = Variable(TextFieldTableViewCell.State.default)
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
		if let ads = selectedAddress,
			let cn = Coin.baseCoin().symbol,
			let smt = balances[ads],
			let blnc = smt[cn] {
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

	private func canPayCommissionWithBaseCoin() -> Bool {
		let balance = self.baseCoinBalance
		if balance >= currentCommission {
			return true
		}
		return false
	}

	private var currentCommission: Decimal {
		let payloadCom = payloadComission().decimalFromPIP()
		if (toField ?? "").isValidPublicKey() {
			let val = (payloadCom + RawTransactionType.delegate.commission()).PIPToDecimal()
			return Decimal(Session.shared.currentGasPrice.value) * val
		}
		let val = (payloadCom + RawTransactionType.sendCoin.commission()).PIPToDecimal()
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
	private var to = Variable<String?>(nil)
	private var toAddress = Variable<String?>(nil)
	private var amount = Variable<Decimal?>(nil)
	private var nonce = Variable<Int?>(nil)
	private var currentGas = Variable<Int>(RawTransactionDefaultGasPrice)
	private var forceUpdateFee = PublishSubject<Void>()
	private let accountManager = AccountManager()
	private let infoManager = InfoManager.default
	private let payloadSubject = BehaviorSubject<String?>(value: "")
	private let clearPayloadSubject = BehaviorSubject<String?>(value: "")
	private let errorNotificationSubject = PublishSubject<NotifiableError?>()
	private let txErrorNotificationSubject = PublishSubject<NotifiableError?>()
	private let txScanButtonDidTap = PublishSubject<Void>()
	private var didScanQRSubject = PublishSubject<String?>()
	private var showViewControllerSubject = PublishSubject<UIViewController?>()
	private var setAddressFieldSubject = PublishSubject<String?>()

	var showPopup = Variable<PopupViewController?>(nil)

	var isPrepearingObservable: Observable<Bool> {
		return isLoadingNonce.asObservable()
	}

	var forceRefreshSubmitButtonState = Variable(false)

	var isSubmitButtonEnabledObservable: Observable<Bool> {
		return Observable.combineLatest(self.toAddress.asObservable(),
																		self.amount.asObservable(),
																		self.selectedCoin.asObservable(),
																		forceRefreshSubmitButtonState.asObservable())
			.map({ (val) -> Bool in

			let toValue = val.0 ?? ""
			let amountValue = val.1 ?? 0.0
			return (toValue.isValidAddress() || toValue.isValidPublicKey()) && self.isAmountValid(amount: amountValue)
		})
	}

	var gasObservable: Observable<String> {
		return Observable.combineLatest(forceUpdateFee.asObservable(),
																		currentGas.asObservable(),
																		clearPayloadSubject.asObservable(),
																		payloadSubject.asObservable())
			.map({ [weak self] (obj) -> String in
				let payloadData = obj.2?.data(using: .utf8)
				return self?.comissionText(for: obj.1, payloadData: payloadData) ?? ""
		})
	}

	// MARK: -

	override init() {
		super.init()

		self.input = Input(payload: payloadSubject.asObserver(),
											 txScanButtonDidTap: txScanButtonDidTap.asObserver(),
											 didScanQR: didScanQRSubject.asObserver())
		self.output = Output(errorNotification: errorNotificationSubject.asObservable(),
												 txErrorNotification: txErrorNotificationSubject.asObservable(),
												 showViewController: showViewControllerSubject.asObservable(),
												 setAddressField: setAddressFieldSubject.asObservable())

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
		}).subscribe(onNext: { (val) in
			self.clearPayloadSubject.onNext(val)
		}).disposed(by: disposeBag)

		Session.shared.allBalances.asObservable().distinctUntilChanged()
			.subscribe(onNext: { [weak self] (val) in
			if let addr = self?.selectedAddress,
				let selCoin = self?.selectedCoin.value,
				nil == val[addr]?[selCoin] {
					self?.selectedAddress = nil
					self?.selectedCoin.value = nil
			}
			self?.sections.value = self?.createSections() ?? []
		}).disposed(by: disposeBag)

		sections.asObservable().subscribe(onNext: { [weak self] (items) in
			self?._sections.value = items
		}).disposed(by: disposeBag)

		Session.shared.accounts.asDriver().drive(onNext: { [weak self] (val) in
			self?.clear()
			self?.sections.value = self?.createSections() ?? []
		}).disposed(by: disposeBag)

		didScanQRSubject.asObservable().subscribe(onNext: { [weak self] (val) in
			if true == val?.isValidPublicKey() || true == val?.isValidAddress() {
				self?.setAddressFieldSubject.onNext(val)
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
			.notification(SendViewControllerAddressNotification)
			.subscribe(onNext: { [weak self] (not) in
				if let recipient = not.userInfo?["address"] as? String {
					if recipient.isValidAddress() || recipient.isValidPublicKey() {
						self?.setAddressFieldSubject.onNext(recipient)
					}
				}
			}).disposed(by: disposeBag)
	}

	// MARK: - Sections

	func createSections() -> [BaseTableSectionItem] {
		let username = UsernameTableViewCellItem(reuseIdentifier: "UsernameTableViewCell",
																						 identifier: cellIdentifierPrefix.address.rawValue)
		username.title = "TO (MX ADDRESS OR PUBLIC KEY)".localized()
		if let delegateProxy = UIApplication.shared.delegate as? RxApplicationDelegateProxy,
			let appDele = delegateProxy.forwardToDelegate() as? AppDelegate,
			appDele.isTestnet {
			username.title = "TO (@USERNAME, EMAIL, MX ADDRESS OR PUBLIC KEY)".localized()
		}
		username.isLoadingObservable = isLoadingAddress.asObservable()
		username.stateObservable = addressStateObservable.asObservable()
		username.value = toField ?? ""
		username.keybordType = .emailAddress

		let coin = PickerTableViewCellItem(reuseIdentifier: "PickerTableViewCell",
																			 identifier: cellIdentifierPrefix.coin.rawValue + (selectedBalanceText ?? ""))
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
			}
		}

		let amount = AmountTextFieldTableViewCellItem(reuseIdentifier: "AmountTextFieldTableViewCell",
																									identifier: cellIdentifierPrefix.amount.rawValue)
		amount.title = "AMOUNT".localized()
		amount.rules = [FloatRule(message: "INCORRECT AMOUNT".localized())]
		amount.value = self.amountField ?? ""
		amount.stateObservable = amountStateObservable.asObservable()
		amount.keyboardType = .decimalPad

		let payload = TextViewTableViewCellItem(reuseIdentifier: "SendPayloadTableViewCell",
																						identifier: "SendPayloadTableViewCell_Payload")
		payload.title = "PAYLOAD MESSAGE (max 1024 symbols)".localized()
		payload.keybordType = .default
		payload.stateObservable = payloadStateObservable.asObservable()
		payload.titleObservable = clearPayloadSubject.asObservable()

		let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell",
																				identifier: cellIdentifierPrefix.fee.rawValue)
		fee.title = "Transaction Fee".localized()
		let payloadData = (try? clearPayloadSubject.value() ?? "")?.data(using: .utf8)
		fee.subtitle = self.comissionText(for: 1, payloadData: payloadData)
		fee.subtitleObservable = self.gasObservable

		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
																							 identifier: cellIdentifierPrefix.separator.rawValue)

		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																			 identifier: cellIdentifierPrefix.blank.rawValue)

		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																				 identifier: cellIdentifierPrefix.button.rawValue)
		button.title = "SEND".localized()
		button.buttonPattern = "purple"
		button.isButtonEnabled = validate().count == 0
		button.isLoadingObserver = isPrepearingObservable
		button.isButtonEnabledObservable = isSubmitButtonEnabledObservable.asObservable()

		var section = BaseTableSectionItem(header: "")
		section.items = [coin, username, amount, payload, fee, separator, blank, button]
		return [section]
	}

	// MARK: - Validation

	func validate() -> [String: String] {
		var errs = [String: String]()

		if let toFld = toField, toFld != "" &&
			((self.toAddress.value?.isValidAddress() ?? false)
				|| (self.toAddress.value?.isValidPublicKey() ?? false)
			) {
		} else {
			errs[cellIdentifierPrefix.address.rawValue] = "ADDRESS OR USERNAME IS INCORRECT".localized()
		}

		if nil == self.amount.value {
			errs[cellIdentifierPrefix.address.rawValue] = "AMOUNT IS INCORRECT".localized()
		}
		return errs
	}

	func validateField(item: BaseCellItem, value: String) -> Bool {

		defer {
			self._sections.value = self.createSections()
		}

		if item.identifier.hasPrefix(cellIdentifierPrefix.amount.rawValue) {
			self.amountField = value.replacingOccurrences(of: ",", with: ".")
			return isAmountValid(amount: Decimal(string: value) ?? 0)
		} else if item.identifier.hasPrefix(cellIdentifierPrefix.address.rawValue) && value.count >= 5 {
			self.toField = value
			return isToValid(to: value)
		}
		assert(true)
		return false
	}

	func submitField(item: BaseCellItem, value: String) {
		if item.identifier.hasPrefix(cellIdentifierPrefix.amount.rawValue) {
			self.amountField = value.replacingOccurrences(of: ",", with: ".")

			if isAmountValid(amount: self.amount.value ?? 0) || self.amountField == "" {
				amountStateObservable.value = .default
			} else {
				amountStateObservable.value = .invalid(error: "AMOUNT IS INCORRECT".localized())
			}
		} else if item.identifier.hasPrefix(cellIdentifierPrefix.address.rawValue) {
			self.toField = value
		}
		self._sections.value = self.createSections()
	}

	func isToValid(to: String) -> Bool {
		if to.count > 66 {
			return false
		}
		//username and address
		return to.isValidUsername() || to.isValidAddress() || to.isValidPublicKey() || to.isValidEmail()
	}

	func isAmountValid(amount: Decimal) -> Bool {
		return AmountValidator.isValid(amount: amount)
	}

	func getAddress() {

		self.toAddress.value = nil
		let to = (toField ?? "")

		guard isToValid(to: to) else {
			if to.count > 66 {
				self.addressStateObservable.value = .invalid(error: "TOO MANY SYMBOLS".localized())
			} else if to == "" || to.count < 6 {
				self.addressStateObservable.value = .default
			} else {
				self.addressStateObservable.value = .invalid(error: "INVALID VALUE".localized())
			}
			return
		}

		if to.isValidAddress() {
			toAddress.value = toField
			addressStateObservable.value = .default
		} else if to.isValidEmail() {
			//get by email

			isLoadingAddress.value = true
			infoManager.address(email: to) { [weak self] (address, user, error) in
				self?.isLoadingAddress.value = false
				self?.forceRefreshSubmitButtonState.value = true

				guard nil == error, let address = address else {
					//show field error
					self?.addressStateObservable.value = .invalid(error: "EMAIL CAN NOT BE FOUND".localized())
					return
				}
				if address.isValidAddress(),
					let toFld = self?.toField?.lowercased(),
					let usr = user?.email?.lowercased(),
					toFld == usr {
						self?.toAddress.value = address
						self?.addressStateObservable.value = .default
				} else {
					self?.addressStateObservable.value = .invalid(error: "EMAIL CAN NOT BE FOUND".localized())
				}
			}
		} else if to.isValidPublicKey() {
			self.addressStateObservable.value = .default
			self.toAddress.value = to
			self.forceRefreshSubmitButtonState.value = true
		} else {
			//get by username
			var val = to
			if val.hasPrefix("@") {
				val.removeFirst()
			}
			isLoadingAddress.value = true
			infoManager.address(username: val) { [weak self] (address, user, error) in
				self?.isLoadingAddress.value = false
				self?.forceRefreshSubmitButtonState.value = true

				guard nil == error, let address = address else {
					self?.addressStateObservable.value = .invalid(error: "USERNAME CAN NOT BE FOUND".localized())
					return
				}

				var toFld = self?.toField?.lowercased()
				if toFld?.hasPrefix("@") == true {
					toFld?.removeFirst()
				}

				if address.isValidAddress(), let usr = user?.username?.lowercased(), toFld == usr {
					self?.toAddress.value = address
					self?.addressStateObservable.value = .default
				} else {
					self?.addressStateObservable.value = .invalid(error: "USERNAME CAN NOT BE FOUND".localized())
					//Show address error
				}
			}
		}
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
	}

	// MARK: -

	func clear() {
		self.toField = nil
		self.to.value = nil
		self.amount.value = nil
		self.amountField = nil
		self.nonce.value = nil
		self.toAddress.value = nil
		self.clearPayloadSubject.onNext(nil)
	}

	func sendButtonTaped() {
		if nil == self.selectedAddress || isLoadingNonce.value == true {
			return
		}

		Observable.combineLatest(GateManager.shared.nonce(address: "Mx" + selectedAddress!),
														 GateManager.shared.minGas())
			.do(onNext: { [weak self] (result) in
				let (nonce, gas) = result

				if (self?.currentGas.value ?? 1) != gas {
					let payloadData = (try? self?.clearPayloadSubject.value() ?? "")?.data(using: .utf8)
					let comissionText = self!.comissionText(for: gas, payloadData: payloadData)
					self?.errorNotificationSubject.onNext(NotifiableError(title: "Transaction fee changed".localized(),
																																text: "Current fee is: " + comissionText))
				}
				self?.nonce.value = nonce + 1
				self?.currentGas.value = gas

				let amount = self?.amount.value ?? 0.0
				guard let address = self?.toAddress.value else {
					//Show error?
					return
				}

				let vm = self?.sendPopupViewModel(to: self!.toField ?? address,
																					address: address,
																					amount: amount)
				let vc = Storyboards.Popup.instantiateInitialViewController()
				vc.viewModel = vm
				self?.showPopup.value = vc
		}, onError: { [weak self] (error) in
			self?.errorNotificationSubject.onNext(NotifiableError(title: "Can't get nonce"))
			self?.isLoadingNonce.value = false
		}, onCompleted: { [weak self] in
			self?.isLoadingNonce.value = false
		}, onSubscribe: { [weak self] in
			self?.isLoadingNonce.value = true
		}).subscribe().disposed(by: disposeBag)
	}

	func submitSendButtonTaped() {
		sendTX()
	}

	func sendCancelButtonTapped() {
		forceRefreshSubmitButtonState.value = true
	}

	func viewDidAppear() {
		GateManager.shared.minGasPrice().subscribe(onNext: { [weak self] (gas) in
			self?.currentGas.value = gas
		}).disposed(by: disposeBag)
	}

	// MARK: -

	func sendTX() {
		let amount = self.amount.value ?? 0.0
		guard let to = self.toAddress.value,
			let selectedCoin = self.selectedCoin.value,
			let nonce = self.nonce.value else {
			self.errorNotificationSubject.onNext(NotifiableError(title: "Transaction can't be sent".localized()))
			return
		}

		let isMax = (Decimal.PIPComparableBalance(from: amount)
			== Decimal.PIPComparableBalance(from: (self.selectedAddressBalance ?? 0.0)))

		let isBaseCoin = selectedCoin == Coin.baseCoin().symbol!
		let payload = self.payload()

		DispatchQueue.global().async { [weak self] in
			guard let mnemonic = self?.accountManager.mnemonic(for: self!.selectedAddress!),
				let seed = self?.accountManager.seed(mnemonic: mnemonic) else {
				//Error no Private key found
				assert(true)
				DispatchQueue.main.async {
					self?.errorNotificationSubject.onNext(NotifiableError(title: "No private key found".localized()))
				}
				return
			}

			guard let selectedCoin = self?.selectedCoin.value else {
				DispatchQueue.main.async {
					self?.errorNotificationSubject.onNext(NotifiableError(title: "Can't get nonce".localized()))
				}
				return
			}

			let toFld = self?.toField
			var newAmount = amount.decimalFromPIP()
			if isMax {
				//if we want to send all coins at first we check if can pay comission with the base coin
				//if so we subtract commission amount from the requested amount
				if isBaseCoin {
					//In case of base coin just subtract static commission
					/// - SeeAlso: https://minter-go-node.readthedocs.io/en/docs/commissions.html
					let amountWithCommission = max(0, amount - (self?.currentCommission ?? 0))
					guard (self?.selectedAddressBalance ?? 0) >= amountWithCommission else {
						let needs = self?.formatter.string(from: amountWithCommission as NSNumber) ?? ""
						self?.errorNotificationSubject.onNext(NotifiableError(title: "Not enough coins.",
																																	text: "Needs " + needs))
						self?.showPopup.value = nil
						return
					}

					newAmount = amountWithCommission.decimalFromPIP()
					self?.proceedSend(seed: seed,
														nonce: nonce,
														to: to,
														toFld: toFld,
														commissionCoin: Coin.baseCoin().symbol!,
														amount: newAmount,
														payload: payload)
				} else if !(self?.canPayCommissionWithBaseCoin() ?? true) {
					/// In case if we send not a base coin (e.g. BELTCOIN) we try to pay commission with base coin
					let tx: RawTransaction?
					if to.isValidPublicKey() {
						tx = self?.delegateRawTransaction(nonce: BigUInt(nonce),
																							gasCoin: self!.selectedCoin.value!,
																							to: to,
																							value: BigUInt(decimal: newAmount)!,
																							coin: self!.selectedCoin.value!,
																							payload: payload)
					} else {
						tx = self?.sendRawTransaction(nonce: BigUInt(nonce),
																					gasCoin: self!.selectedCoin.value!,
																					to: to,
																					value: BigUInt(decimal: newAmount)!,
																					coin: self!.selectedCoin.value!,
																					payload: payload)
					}

					//we make fake tx to get it's commission
					guard let fakeTx = tx,
						let signedTx = RawTransactionSigner.sign(rawTx: fakeTx,
																										 privateKey: self?.fakePK ?? "") else {

						DispatchQueue.main.async {
							self?.errorNotificationSubject.onNext(NotifiableError(title: "Can't check tx".localized()))
							self?.showPopup.value = nil
						}
						return
					}

					/// Checking commission for the following tx
					GateManager.shared.estimateTXCommission(for: signedTx,
																									completion: { [weak self] (commission, error) in
						guard error == nil, nil != commission else {
							return
						}
						let normalizedCommission = commission!.PIPToDecimal()
						let normalizedAmount = amount - normalizedCommission
						//if new amount less than 0 - show error
						if normalizedAmount < 0 {
							//error
							let needs = self?.formatter.string(from: (amount + normalizedCommission) as NSNumber) ?? ""
							self?.errorNotificationSubject.onNext(NotifiableError(title: "Not enough coins.".localized(),
																																		text: "Needs ".localized() + needs))
							self?.showPopup.value = nil
							return
						}

						self?.proceedSend(seed: seed,
															nonce: nonce,
															to: to,
															toFld: toFld,
															commissionCoin: selectedCoin,
															amount: normalizedAmount.decimalFromPIP(),
															payload: payload)
					})
				} else {
					newAmount = (self?.selectedAddressBalance ?? 0).decimalFromPIP()
					self?.proceedSend(seed: seed,
														nonce: nonce,
														to: to,
														toFld: toFld,
														commissionCoin: Coin.baseCoin().symbol!,
														amount: newAmount,
														payload: payload)
				}
			} else {
				let commissionCoin = (self?.canPayCommissionWithBaseCoin() ?? false) ? Coin.baseCoin().symbol! : selectedCoin
				self?.proceedSend(seed: seed,
													nonce: nonce,
													to: to,
													toFld: toFld,
													commissionCoin: commissionCoin,
													amount: newAmount,
													payload: payload)
			}
		}
	}

	private func proceedSend(seed: Data,
													 nonce: Int,
													 to: String,
													 toFld: String?,
													 commissionCoin: String,
													 amount: Decimal,
													 payload: String) {

		self.sendTx(seed: seed,
								nonce: nonce,
								to: to,
								coin: selectedCoin.value!,
								commissionCoin: commissionCoin,
								amount: amount,
								payload: payload) { [weak self, toFld] res in

			guard res == true else { return }

			self?.clear()
			self?.sections.value = self?.createSections() ?? []

			DispatchQueue.main.async {
				if let sentViewModel = self?.sentViewModel(to: toFld ?? to, address: to) {
					self?.showPopup.value = PopupRouter.sentPopupViewCointroller(viewModel: sentViewModel)
				}
			}

			DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2), execute: {
				Session.shared.loadTransactions()
				Session.shared.loadBalances()
				Session.shared.loadDelegatedBalance()
			})
		}
	}

	private func sendTx(seed: Data,
											nonce: Int,
											to: String,
											coin: String,
											commissionCoin: String,
											amount: Decimal,
											payload: String,
											completion: ((Bool?) -> ())? = nil) {

		let nonce = BigUInt(nonce)
		guard
			let newPk = try? self.accountManager.privateKey(from: seed),
			let value = BigUInt(decimal: amount) else {
			completion?(false)
			return
		}

		let tx: RawTransaction
		if to.isValidPublicKey() {
			tx = self.delegateRawTransaction(nonce: nonce,
																			 gasCoin: commissionCoin,
																			 to: to,
																			 value: value,
																			 coin: coin,
																			 payload: payload)
		} else {
			tx = self.sendRawTransaction(nonce: nonce,
																	 gasCoin: commissionCoin,
																	 to: to,
																	 value: value,
																	 coin: coin,
																	 payload: payload)
		}

		let pkString = newPk.raw.toHexString()
		guard let signedTx = RawTransactionSigner.sign(rawTx: tx,
																									 privateKey: pkString) else {
			completion?(false)
			return
		}

		self.nonce.value = nil
		GateManager.shared.send(rawTx: signedTx).do(onNext: { [weak self] (hash) in

			guard let hash = hash else {
				completion?(false)
				return
			}

			self?.lastSentTransactionHash = hash
			completion?(true)
		}, onError: { [weak self] (error) in
			self?.handle(error: error)
		}).subscribe(onNext: { (val) in
//			completion?(true)
		}).disposed(by: disposeBag)
	}

	private func comissionText(for gas: Int, payloadData: Data? = nil) -> String {
		let payloadCom = Decimal((payloadData ?? Data()).count) * RawTransaction.payloadByteComissionPrice.decimalFromPIP()
		var commission = (RawTransactionType.sendCoin.commission() + payloadCom).PIPToDecimal() * Decimal(gas)
		if (toField ?? "").isValidPublicKey() {
			commission = (RawTransactionType.delegate.commission() + payloadCom).PIPToDecimal() * Decimal(gas)
		}

		let balanceString = CurrencyNumberFormatter.formattedDecimal(with: commission,
																																 formatter: self.coinFormatter)
		return balanceString + " " + (Coin.baseCoin().symbol ?? "")
	}

	private func sendRawTransaction(nonce: BigUInt,
																	gasCoin: String,
																	to: String,
																	value: BigUInt,
																	coin: String,
																	payload: String) -> RawTransaction {

		let tx = SendCoinRawTransaction(nonce: nonce,
																		gasPrice: currentGas.value,
																		gasCoin: gasCoin,
																		to: to,
																		value: value,
																		coin: coin.uppercased())
		tx.payload = payload.data(using: .utf8) ?? Data()
		return tx
	}

	private func delegateRawTransaction(nonce: BigUInt,
																			gasCoin: String,
																			to: String,
																			value: BigUInt,
																			coin: String,
																			payload: String) -> RawTransaction {
		let tx = DelegateRawTransaction(nonce: nonce,
																		gasCoin: gasCoin,
																		publicKey: to,
																		coin: coin,
																		value: value)
		tx.payload = payload.data(using: .utf8) ?? Data()
		return tx
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
		let vm = SendPopupViewModel()
		vm.amount = amount
		vm.coin = selectedCoin.value
		vm.username = to
		if to.isValidPublicKey() {
			vm.avatarImage = UIImage(named: "delegateImage")
		} else {
			vm.avatarImageURL = MinterMyAPIURL.avatarAddress(address: address).url()
		}
		vm.popupTitle = "You're Sending"
		vm.buttonTitle = "SEND".localized()
		vm.cancelTitle = "CANCEL".localized()
		return vm
	}

	func sentViewModel(to: String, address: String) -> SentPopupViewModel {
		let vm = SentPopupViewModel()
		vm.actionButtonTitle = "VIEW TRANSACTION".localized()
		if to.isValidPublicKey() {
			vm.avatarImage = UIImage(named: "delegateImage")
		} else {
			vm.avatarImageURL = MinterMyAPIURL.avatarAddress(address: address).url()
		}
		vm.secondButtonTitle = "CLOSE".localized()
		vm.username = to
		vm.title = "Success!".localized()
		return vm
	}
}
