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


struct AccountPickerItem {
	
	var title: String?
	
	var address: String?
	
	var balance: Decimal?
	
	var coin: String?
	
}



class SendViewModel: BaseViewModel {
	
	enum cellIdentifierPrefix : String {
		case address = "TextFieldTableViewCell_Address"
		case coin = "PickerTableViewCell_Coin"
		case amount = "AmountTextFieldTableViewCell_Amount"
		case fee = "TwoTitleTableViewCell_TransactionFee"
		case separator = "SeparatorTableViewCell"
		case blank = "BlankTableViewCell"
		case swtch = "SwitchTableViewCell"
		case button = "ButtonTableViewCell"
	}
	
	//MARK: -

	var title: String {
		get {
			return "Send".localized()
		}
	}
	
	private var toField: String? {
		didSet {
			self.getAddress()
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
	
	//MARK: -
	
	var sections = Variable([BaseTableSectionItem]())
	private var _sections = Variable([BaseTableSectionItem]())
	
	private let formatter = CurrencyNumberFormatter.decimalFormatter
	private let shortDecimalFormatter = CurrencyNumberFormatter.decimalShortFormatter
	private let decimalsNoMantissaFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter
	private let coinFormatter = CurrencyNumberFormatter.coinFormatter
	
	private var isLoadingAddress = Variable(false)
	private var isLoadingNonce = Variable(false)
	
	private var addressStateObservable = Variable(TextViewTableViewCell.State.default)
	private var amountStateObservable = Variable(TextFieldTableViewCell.State.default)
	
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
		return CurrencyNumberFormatter.formattedDecimal(with: selectedAddressBalance ?? 0, formatter: formatter) //formatter.string(from: (selectedAddressBalance ?? 0.0) as NSNumber)
	}
	
	var baseCoinBalance: Decimal {
		let balances = Session.shared.allBalances.value
		if let ads = selectedAddress, let cn = Coin.baseCoin().symbol, let smt = balances[ads], let blnc = smt[cn] {
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
	
	func coinToPayComission(amount: Decimal) -> String? {
		
		guard let selectedCoin = self.selectedCoin.value else {
			return nil
		}
		
		if isBaseCoin == true {
			let balance = self.baseCoinBalance * TransactionCoinFactorDecimal
			if balance >= amount + RawTransactionType.sendCoin.commission() {
				return Coin.baseCoin().symbol!
			}
		}
		else {
			//If it's not base coin we try pay commission from base coin
			if canPayCommissionWithBaseCoin() {
				return Coin.baseCoin().symbol!
			}
			//If it's impossible we try to pay comission from the selected coin
			let selectedBalance = (self.selectedAddressBalance ?? 0.0) * TransactionCoinFactorDecimal
			if selectedBalance >= amount + (RawTransactionType.sendCoin.commission()) {
				return selectedCoin
			}
		}
		return nil
	}
	
	func canPayCommissionWithBaseCoin() -> Bool {
		let balance = self.baseCoinBalance
		if balance >= (RawTransactionType.sendCoin.commission() / TransactionCoinFactorDecimal) {
			return true
		}
		return false
	}
	
	private var lastSentTransactionHash: String?
	private var selectedCoin = Variable<String?>(nil)
	
	private var to = Variable<String?>(nil)
	private var toAddress = Variable<String?>(nil)
	private var amount = Variable<Decimal?>(nil)
	private var nonce = Variable<Int?>(nil)
	
	private let accountManager = AccountManager()
	private let infoManager = InfoManager.default
	
	var notifiableError = Variable<NotifiableError?>(nil)
	var txError = Variable<NotifiableError?>(nil)
	
	var showPopup = Variable<PopupViewController?>(nil)
	
	//used to send request before real countdown finished
	var fakeCountdownFinished = Variable(false)
	var countdownFinished = Variable(false)
	
	var isPrepearingObservable: Observable<Bool> {
		return isLoadingNonce.asObservable()
	}
	
	var isSubmitButtonEnabledObservable: Observable<Bool> {
		return Observable.combineLatest(self.toAddress.asObservable(), self.amount.asObservable(), self.selectedCoin.asObservable()).map({ (val) -> Bool in
			return (val.0?.isValidAddress() ?? false) && self.isAmountValid(amount: (val.1 ?? 0))
		})
	}
	
	var isFreeTx = Variable(false)
	
	var isCountingDown = false
	
	private let disposeBag = DisposeBag()
	
	//MARK: -

	override init() {
		super.init()
		
		Session.shared.allBalances.asObservable().distinctUntilChanged().filter({ (_) -> Bool in
			return true //nil == self.selectedAddress
		}).subscribe(onNext: { [weak self] (val) in
			if let addr = self?.selectedAddress, let selCoin = self?.selectedCoin.value, nil == val[addr]?[selCoin] {
				self?.selectedAddress = nil
				self?.selectedCoin.value = nil
			}
			self?.sections.value = self?.createSections() ?? []
		}).disposed(by: disposeBag)
		
		fakeCountdownFinished.asObservable().filter({ (val) -> Bool in
			return val == true
		}).subscribe(onNext: { [weak self] (val) in
			self?.isCountingDown = false
			
			self?.sendTX()
			
		}).disposed(by: disposeBag)
		
		Observable.combineLatest(fakeCountdownFinished.asObservable(), countdownFinished.asObservable()).subscribe { [weak self] (val) in
			
			guard let to = self?.toAddress.value, val.event.element?.0 == true && val.event.element?.1 == true else {
				return
			}
			
			DispatchQueue.main.async {
				self?.showPopup.value = PopupRouter.sentPopupViewCointroller(viewModel: self!.sentViewModel(to: self!.toField ?? to, address: to))
			}
			
			DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2), execute: {
				Session.shared.loadTransactions()
				SessionHelper.reloadAccounts()
			})
		}.disposed(by: disposeBag)
		
		sections.asObservable().subscribe(onNext: { [weak self] (items) in
				self?._sections.value = items
		}).disposed(by: disposeBag)

	}
	
	//MARK: - Sections
	
	func createSections() -> [BaseTableSectionItem] {
		
		let username = AddressTextViewTableViewCellItem(reuseIdentifier: "AddressTextViewTableViewCell1", identifier: cellIdentifierPrefix.address.rawValue)
		username.title = "TO (@USERNAME, EMAIL OR MX ADDRESS)".localized()
		username.isLoadingObservable = isLoadingAddress.asObservable()
		username.stateObservable = addressStateObservable.asObservable()
		username.value = toField ?? ""
		username.keybordType = .emailAddress
		
		let coin = PickerTableViewCellItem(reuseIdentifier: "PickerTableViewCell", identifier: cellIdentifierPrefix.coin.rawValue + (selectedBalanceText ?? ""))
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
		
		let amount = AmountTextFieldTableViewCellItem(reuseIdentifier: "AmountTextFieldTableViewCell", identifier: cellIdentifierPrefix.amount.rawValue)
		amount.title = "AMOUNT".localized()
		amount.rules = [FloatRule(message: "INCORRECT AMOUNT".localized())]
		amount.value = self.amountField ?? ""
		amount.stateObservable = amountStateObservable.asObservable()
		amount.keyboardType = .decimalPad
		
		let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell", identifier: cellIdentifierPrefix.fee.rawValue)
		fee.title = "Transaction Fee".localized()
		fee.subtitle = "0.0100 " + (Coin.baseCoin().symbol ?? "")
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: cellIdentifierPrefix.separator.rawValue)
		
		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell", identifier: cellIdentifierPrefix.blank.rawValue)
		
//		let sendForFree = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell", identifier: cellIdentifierPrefix.swtch.rawValue)
//		sendForFree.title = "Send for free!".localized()
//		sendForFree.isOn.value = isFreeTx.value
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: cellIdentifierPrefix.button.rawValue)
		button.title = "SEND".localized()
		button.buttonPattern = "purple"
		button.isButtonEnabled = validate().count == 0
		button.isLoadingObserver = isPrepearingObservable
		button.isButtonEnabledObservable = isSubmitButtonEnabledObservable.asObservable()
		
		var section = BaseTableSectionItem(header: "")
		section.items = [coin, username, amount, fee, separator, blank, button]
		return [section]
	}
	
	//MARK: - Validation
	
	func validate() -> [String : String] {
		var errs = [String : String]()
		if let toFld = toField, toFld != "" && (self.toAddress.value?.isValidAddress() ?? false) {
			
		}
		else {
			errs[cellIdentifierPrefix.address.rawValue] = "ADDRESS OR USERNAME IS INCORRECT".localized()
		}
		
		if let amnt = self.amount.value {
			
		}
		else {
			errs[cellIdentifierPrefix.address.rawValue] = "AMOUNT IS INCORRECT".localized()
		}
		
		return errs
	}
	
	func validateField(item: BaseCellItem, value: String) -> Bool {
		
		defer {
			self._sections.value = self.createSections()
		}
		
		if item.identifier.hasPrefix(cellIdentifierPrefix.address.rawValue) {
			self.toField = value
			
			return isToValid(to: value)
		}
		else if item.identifier.hasPrefix(cellIdentifierPrefix.amount.rawValue) {
			self.amountField = value.replacingOccurrences(of: ",", with: ".")
			
			return isAmountValid(amount: Decimal(string: value) ?? 0)
		}
		
		assert(true)
		return false
	}
	
	func submitField(item: BaseCellItem, value: String) {
		
		if item.identifier.hasPrefix(cellIdentifierPrefix.amount.rawValue) {
			self.amountField = value.replacingOccurrences(of: ",", with: ".")
			
			if isAmountValid(amount: self.amount.value ?? 0) || self.amountField == "" 	 {
				amountStateObservable.value = .default
			}
			else {
				amountStateObservable.value = .invalid(error: "AMOUNT IS INCORRECT".localized())
			}
		}
		
		self._sections.value = self.createSections()
	}
	
	func isToValid(to: String) -> Bool {
		if to.count > 65 {
			return false
		}
		let usernameTest = NSPredicate(format:"SELF MATCHES %@", "^@[a-zA-Z0-9_]{5,16}")
		let usernameTest1 = NSPredicate(format:"SELF MATCHES %@", "^[a-zA-Z0-9_]{5,16}")
		let addressTest = NSPredicate(format:"SELF MATCHES %@", "^Mx[a-zA-Z0-9]{40}$")
		return usernameTest.evaluate(with: to) || usernameTest1.evaluate(with: to) || addressTest.evaluate(with: to) || to.isValidEmail()
	}
	
	func isAmountValid(amount: Decimal) -> Bool {
		return true
		
//		return amount <= (selectedAddressBalance ?? 0) && amount > 0
	}
	
	func getAddress() {
		self.toAddress.value = nil
		
		let to = (toField ?? "")
		
		guard isToValid(to: to) else {
			
			if to.count >= 65 {
				self.addressStateObservable.value = .invalid(error: "TOO MANY SYMBOLS".localized())
				return
			}
			else if to == "" {
				self.addressStateObservable.value = .default
			}
			else {
				self.addressStateObservable.value = .invalid(error: "INVALID VALUE".localized())
			}
			
			return
		}
		
		if to.isValidAddress() {
			toAddress.value = toField
			addressStateObservable.value = .default
			
		}
		else if to.isValidEmail() {
			//get by email
			
			isLoadingAddress.value = true
			infoManager.address(email: to) { [weak self] (address, user, error) in
				self?.isLoadingAddress.value = false
				
				guard nil == error, let address = address else {
					//show field error
					self?.addressStateObservable.value = .invalid(error: "EMAIL CAN NOT BE FOUND".localized())
					return
				}
				if address.isValidAddress(), let toFld = self?.toField?.lowercased(), let usr = user?.email?.lowercased(), toFld == usr {
					self?.toAddress.value = address
					self?.addressStateObservable.value = .default
				}
				else {
					self?.addressStateObservable.value = .invalid(error: "EMAIL CAN NOT BE FOUND".localized())
					//Show address error
				}
			}
		}
		else {
			//get by username
			var val = to
			if val.hasPrefix("@") {
				val.removeFirst()
			}
			isLoadingAddress.value = true
			infoManager.address(username: val) { [weak self] (address, user, error) in
				self?.isLoadingAddress.value = false
				
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
				}
				else {
					self?.addressStateObservable.value = .invalid(error: "USERNAME CAN NOT BE FOUND".localized())
					//Show address error
				}
			}
		}
	}

	//MARK: - Rows

	func rowsCount(for section: Int) -> Int {
		return _sections.value[safe: section]?.items.count ?? 0
	}

	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return _sections.value[safe: section]?.items[safe: row]
	}
	
	//MARK: -
	
	func accountPickerItems() -> [PickerTableViewCellPickerItem] {
		var ret = [AccountPickerItem]()

		let balances = Session.shared.allBalances.value
		balances.keys.forEach { (address) in
			balances[address]?.keys.sorted(by: { (val1, val2) -> Bool in
				return val1 < val2
			}).forEach({ (coin) in
				let balance = (balances[address]?[coin] ?? 0.0)
				
//				guard balance > 0 else { return }
				let balanceString = CurrencyNumberFormatter.formattedDecimal(with: balance, formatter: coinFormatter)
				let title = coin + " (" + balanceString + ")"
				let item = AccountPickerItem(title: title, address: address, balance: balance, coin: coin)
				ret.append(item)
			})
		}
		
		return ret.map({ (account) -> PickerTableViewCellPickerItem in
			return PickerTableViewCellPickerItem(title: account.title, object: account)
		})
	}
	
	func selectedPickerItem() -> PickerTableViewCellPickerItem? {
		guard let adrs = selectedAddress, let coin = selectedCoin.value else {
			return nil
		}
		
		guard let balances = Session.shared.allBalances.value[adrs], let balance = balances[coin] else {
			return nil
		}
		
		let balanceString = CurrencyNumberFormatter.formattedDecimal(with: balance, formatter: coinFormatter)
		let title = coin + " (" + balanceString + ")"
		let item = AccountPickerItem(title: title, address: adrs, balance: balance, coin: coin)
		return PickerTableViewCellPickerItem(title: item.title, object: item)
	}
	
	//MARK: -
	
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
	
	//MARK: -
	
	func clear() {
		
		self.toField = nil
		self.to.value = nil
		self.amount.value = nil
		self.amountField = nil
		self.nonce.value = nil
		self.toAddress.value = nil
	}
	
	func sendButtonTaped() {
		
		getNonce { [weak self] (suc) in
			
			guard suc else {
				assert(true)
				self?.notifiableError.value = NotifiableError(title: "Can't get nonce", text: nil)
				return
			}
			
			//Get difficulty hash?
			DispatchQueue.main.async {
				let amount = self?.amount.value ?? 0.0
				guard let address = self?.toAddress.value else {
					//Show error?
					return
				}
				
				let vm = self?.sendPopupViewModel(to: self!.toField ?? address, address: address, amount: amount)
				let vc = Storyboards.Popup.instantiateInitialViewController()
				vc.viewModel = vm
				
				self?.showPopup.value = vc
			}
		}
	}
	
	func submitSendButtonTaped() {
		
		self.countdownFinished.value = false
		self.fakeCountdownFinished.value = false
		
		if isFreeTx.value {
			let vm = self.countdownPopupViewModel()
			self.showPopup.value = PopupRouter.countdownPopupViewController(viewModel: vm)
		}
		else {
			sendTX()
		}
		
	}
	
	func getNonce(completion: ((Bool) -> ())?) {
		
		if isLoadingNonce.value == true {
			return
		}
		isLoadingNonce.value = true
		
		MinterExplorer.ExplorerTransactionManager.default.count(for: "Mx" + self.selectedAddress!) { [weak self] (count, err) in
		
			var success = false
			
			defer {
				self?.isLoadingNonce.value = false
				completion?(success)
			}
			
			guard nil == err, nil != count else {
				success = false
				return
			}
			
			self?.nonce.value = NSDecimalNumber(decimal: count ?? 0).intValue + 1
			success = true
		}
	}
	
	func sendTX() {
		
		let amount = self.amount.value ?? 0.0
		
		guard let to = self.toAddress.value, let selectedCoin = self.selectedCoin.value, let nonce = self.nonce.value else {
			self.notifiableError.value = NotifiableError(title: "Transaction can't be sent".localized(), text: nil)
			return
		}
		
		guard let strVal = decimalsNoMantissaFormatter.string(from: amount * TransactionCoinFactorDecimal as NSNumber) else {
			return
		}
		
		let value = (BigUInt(strVal) ?? BigUInt(0))
		
		let selectedBalance = self.selectedAddressBalance ?? 0.0

		let maxComparableSelectedBalance = (Decimal(string: formatter.string(from: (selectedBalance) as NSNumber) ?? "") ?? 0.0) * TransactionCoinFactorDecimal
		
		let maxComparableBalance = decimalsNoMantissaFormatter.string(from: maxComparableSelectedBalance as NSNumber) ?? ""
		let isMax = (value > 0 && value == (BigUInt(maxComparableBalance) ?? BigUInt(0)))
		
		let isBaseCoin = selectedCoin == Coin.baseCoin().symbol!
		
		
		DispatchQueue.global().async { [weak self] in
			
			guard let mnemonic = self?.accountManager.mnemonic(for: self!.selectedAddress!), let seed = self?.accountManager.seed(mnemonic: mnemonic) else {
				//Error no Private key found
				assert(true)
				DispatchQueue.main.async {
					self?.notifiableError.value = NotifiableError(title: "No private key found".localized(), text: nil)
				}
				return
			}
			
			guard let nonce = self?.nonce.value, let to = self?.toAddress.value, let selectedCoin = self?.selectedCoin.value else {
				DispatchQueue.main.async {
					self?.notifiableError.value = NotifiableError(title: "Can't get nonce".localized(), text: nil)
				}
				return
			}
			
			let toFld = self?.toField
			
			var newAmount = amount * TransactionCoinFactorDecimal
			if isMax {
				//if we want to send all coins at first we check if can pay comission with the base coin
				//if so we subtract commission amount from the requested amount
				if isBaseCoin {
					//In case of base coin just subtract static commission
					/// - SeeAlso: https://minter-go-node.readthedocs.io/en/docs/commissions.html
					newAmount = (self?.selectedAddressBalance ?? 0) * TransactionCoinFactorDecimal - RawTransactionType.sendCoin.commission()
					self?.proceedSend(seed: seed, nonce: nonce, to: to, toFld: toFld, commissionCoin: Coin.baseCoin().symbol!, amount: newAmount)
				}
				/// In case if we send not a base (e.g. BELTCOIN) coin we try to pay commission with base coin
				else if !(self?.canPayCommissionWithBaseCoin() ?? true) {
					//we make fake tx to get it's commission
					guard let tx = self?.rawTransaction(nonce: BigUInt(nonce), gasCoin: self!.selectedCoin.value!, to: to, value: BigUInt(decimal: newAmount)!, coin: self!.selectedCoin.value!), let pk = self?.accountManager.privateKey(from: seed), let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: pk.raw.toHexString()) else {

						DispatchQueue.main.async {
							self?.notifiableError.value = NotifiableError(title: "Can't check tx".localized(), text: nil)
							self?.showPopup.value = nil
						}
						return
					}
					
					/// Checking commission for the following tx
					MinterExplorer.ExplorerTransactionManager.default.estimateCommission(for: signedTx, completion: { [weak self] (commission, error) in
						
						guard error == nil, nil != commission else {
							return
						}
						let normalizedCommission = commission! / TransactionCoinFactorDecimal
						
						let normalizedAmount = amount - normalizedCommission
						
						//if new amount less than 0 - show error
						if normalizedAmount < 0  {
							//error
							let needs = self?.formatter.string(from: (amount + normalizedCommission) as NSNumber) ?? ""
							self?.notifiableError.value = NotifiableError(title: "Not enough coins.", text: "Needs " + needs)
							self?.showPopup.value = nil
							return
						}
						
						self?.proceedSend(seed: seed, nonce: nonce, to: to, toFld: toFld, commissionCoin: selectedCoin, amount: normalizedAmount * TransactionCoinFactorDecimal)
						
					})
				}
				//otherwise just multiply decimal amount to factor
				else {
					newAmount = (self?.selectedAddressBalance ?? 0) * TransactionCoinFactorDecimal
					self?.proceedSend(seed: seed, nonce: nonce, to: to, toFld: toFld, commissionCoin: Coin.baseCoin().symbol!, amount: newAmount)
				}
			}
			else {
				
				let commissionCoin = (self?.canPayCommissionWithBaseCoin() ?? false) ? Coin.baseCoin().symbol! : selectedCoin
				
				self?.proceedSend(seed: seed, nonce: nonce, to: to, toFld: toFld, commissionCoin: commissionCoin, amount: newAmount)
			}
		}
	}
	
	private func proceedSend(seed: Data, nonce: Int, to: String, toFld: String?, commissionCoin: String, amount: Decimal) {
		
		self.sendTx(seed: seed, nonce: nonce, to: to, coin: selectedCoin.value!, commissionCoin: commissionCoin, amount: amount) { [weak self, toFld] res in
			
			if res == true {
				
				self?.clear()
				
				self?.sections.value = self?.createSections() ?? []
				
				DispatchQueue.main.async {
					self?.showPopup.value = PopupRouter.sentPopupViewCointroller(viewModel: self!.sentViewModel(to: toFld ?? to, address: to))
				}
				
				DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2), execute: {
					Session.shared.loadTransactions()
					Session.shared.loadBalances()
				})
			}
		}
	}
	
	private func sendTx(seed: Data, nonce: Int, to: String, coin: String, commissionCoin: String, amount: Decimal, completion: ((Bool?) -> ())? = nil) {
		
		let newPk = self.accountManager.privateKey(from: seed)
		let nonce = BigUInt(nonce)
		
		let decimalAmount = BigUInt(decimal: amount)
		
		guard let value = decimalAmount else {
			completion?(false)
			return
		}
		
		let tx = self.rawTransaction(nonce: nonce, gasCoin: commissionCoin, to: to, value: value, coin: coin)
		let pkString = newPk.raw.toHexString()
		
		guard let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: pkString) else {
			completion?(false)
			return
		}
		
		self.nonce.value = nil
		
		MinterExplorer.ExplorerTransactionManager.default.sendRawTransaction(rawTransaction: signedTx) { [weak self] (hash, err) in
			
			var res = false
			
			defer {
				completion?(res)
			}
			
			guard err == nil && nil != hash else {
				
				if let error = err as? APIClient.APIClientResponseError {
					if let errorMessage = error.userData?["log"] as? String {
						self?.txError.value =  NotifiableError(title: "Tx Error", text: errorMessage)
					}
				}
				else {
					self?.txError.value = NotifiableError(title: "Unable to send transaction".localized(), text: nil)
				}
				
				res = false
				return
			}
			res = true
			self?.lastSentTransactionHash = hash
		}
	}
	
	private func getComission(forCoin: String, completion: ((Decimal?) -> ())?) {
		
		let comission = RawTransactionType.sendCoin.commission() / TransactionCoinFactorDecimal
		
		MinterExplorer.ExplorerTransactionManager.default.estimateCoinSell(coinFrom: forCoin, coinTo: Coin.baseCoin().symbol!, value: comission) { (result, commission, error) in
			guard error == nil, let result = result, let commission = commission else {
				completion?(nil)
				return
			}
			
			let val = result / TransactionCoinFactorDecimal
			let com = comission / TransactionCoinFactorDecimal
			
			completion?(val + com)
			
		}
	}
	
	private func rawTransaction(nonce: BigUInt, gasCoin: String, to: String, value: BigUInt, coin: String) -> RawTransaction {
		let cn = gasCoin
		let coinData = cn.data(using: .utf8)?.setLengthRight(10) ?? Data(repeating: 0, count: 10)
		return SendCoinRawTransaction(nonce: nonce, gasCoin: coinData, to: to, value: value, coin: coin.uppercased())
	}
	
	//MARK: -
	
	func sendPopupViewModel(to: String, address: String, amount: Decimal) -> SendPopupViewModel {
		
		let vm = SendPopupViewModel()
		vm.amount = amount
		vm.coin = selectedCoin.value
		vm.username = to
		vm.avatarImage = MinterMyAPIURL.avatarAddress(address: address).url()
		vm.popupTitle = "You're Sending"
		vm.buttonTitle = "SEND".localized()
		vm.cancelTitle = "CANCEL".localized()
		return vm
	}
	
	func sentViewModel(to: String, address: String) -> SentPopupViewModel {
		
		let vm = SentPopupViewModel()
		vm.actionButtonTitle = "VIEW TRANSACTION".localized()
		vm.avatarImage = MinterMyAPIURL.avatarAddress(address: address).url()
		vm.secondButtonTitle = "CLOSE".localized()
		vm.username = to
		vm.title = "Success!".localized()
		return vm
	}
	
	func countdownPopupViewModel() -> CountdownPopupViewModel {
		
		let vm = CountdownPopupViewModel()
		vm.popupTitle = "Please wait".localized()
		vm.unit = (one: "second", two: "seconds", other: "seconds")
		vm.count = 13
		vm.desc1 = "Coins will be received in".localized()
		vm.desc2 = "Too long? You can make a faster transaction for 0.1 BIP".localized()
		vm.buttonTitle = "Express transaction".localized()
		return vm
	}
	
	//MARK: -
	
	func lastTransactionExplorerURL() -> URL? {
		guard nil != lastSentTransactionHash else {
			return nil
		}
		
		return URL(string: MinterExplorerBaseURL + "/transactions/" + (lastSentTransactionHash ?? ""))
	}
	
	//MARK: -

}
