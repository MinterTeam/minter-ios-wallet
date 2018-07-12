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
	
	var balance: Double?
	
	var coin: String?
	
}



class SendViewModel: BaseViewModel {
	
	enum cellIdentifierPrefix : String {
		case address = "TextFieldTableViewCell_Address"
		case coin = "PickerTableViewCell_Coin"
		case amount = "TextFieldTableViewCell_Amount"
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
			self.amount.value = Double(amountField ?? "0.0")
			
			if isAmountValid(amount: self.amount.value ?? 0) {
				amountStateObservable.value = .default
			}
//			else {
//				amountStateObservable.value = .invalid(error: "AMOUNT IS INCORRECT".localized())
//			}
			
		}
	}
	
	//MARK: -
	
	var sections = Variable([BaseTableSectionItem]())
	
	
	private var isLoadingAddress = Variable(false)
	private var isLoadingNonce = Variable(false)
	
	private var addressStateObservable = Variable(TextViewTableViewCell.State.default)
	private var amountStateObservable = Variable(TextFieldTableViewCell.State.default)
	
	private var selectedAddress: String?
	private var selectedAddressBalance: Double? {
		guard nil != selectedAddress && nil != selectedCoin.value else {
			return nil
		}
		let balance = Session.shared.allBalances.value.filter { (val) -> Bool in
			if selectedAddress != val.key { return false }
			
			return (nil != val.value[selectedCoin.value!])
		}
		return balance[selectedAddress!]![selectedCoin.value!]
	}
	
	private var lastSentTransactionHash: String?
	private var selectedCoin = Variable<String?>(nil)
	
	private var to = Variable<String?>(nil)
	private var toAddress = Variable<String?>(nil)
	private var amount = Variable<Double?>(nil)
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
			self?.createSections()
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
				self?.showPopup.value = PopupRouter.sentPopupViewCointroller(viewModel: self!.sentViewModel(to: to))
			}
			
			DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2), execute: {
				Session.shared.loadTransactions()
				SessionHelper.reloadAccounts()
			})
		}.disposed(by: disposeBag)

	}
	
	//MARK: - Sections
	
	func createSections() {
		
		let username = AddressTextViewTableViewCellItem(reuseIdentifier: "AddressTextViewTableViewCell", identifier: cellIdentifierPrefix.address.rawValue)
		username.title = "TO (@USERNAME, EMAIL, MOBILE OR MX ADDRESS)".localized()
		username.rules = [RegexRule(regex: "^Mx[a-zA-Z0-9]{40}$", message: "INCORRECT ADDRESS".localized())]
		username.rules = [RegexRule(regex: "^@[a-zA-Z0-9_]{5,32}", message: "INCORRECT ADDRESS".localized())]
		username.isLoadingObservable = isLoadingAddress.asObservable()
		username.stateObservable = addressStateObservable.asObservable()
		username.value = toField ?? ""
		username.keybordType = .emailAddress
		
		let coin = PickerTableViewCellItem(reuseIdentifier: "PickerTableViewCell", identifier: cellIdentifierPrefix.coin.rawValue)
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
		
		let amount = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: cellIdentifierPrefix.amount.rawValue)
		amount.title = "AMOUNT".localized()
		amount.rules = [FloatRule(message: "INCORRECT AMOUNT".localized())]
		amount.value = self.amountField ?? ""
		amount.stateObservable = amountStateObservable.asObservable()
		amount.keyboardType = .decimalPad
		
		let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell", identifier: cellIdentifierPrefix.fee.rawValue)
		fee.title = "Transaction Fee".localized()
		fee.subtitle = "0.00000001 BIP"
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: cellIdentifierPrefix.separator.rawValue)
		
		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell", identifier: cellIdentifierPrefix.blank.rawValue)
		
		let sendForFree = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell", identifier: cellIdentifierPrefix.swtch.rawValue)
		sendForFree.title = "Send for free!".localized()
		sendForFree.isOn.value = isFreeTx.value
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: cellIdentifierPrefix.button.rawValue)
		button.title = "SEND!".localized()
		button.buttonPattern = "purple"
		button.isButtonEnabled = validate().count == 0
		button.isLoadingObserver = isPrepearingObservable
		button.isButtonEnabledObservable = isSubmitButtonEnabledObservable.asObservable()
		
		var section = BaseTableSectionItem(header: "")
		section.items = [coin, username, amount, fee, separator, blank, sendForFree, separator, blank, button]
		sections.value = [section]
	}
	
	//MARK: - Validation
	
	func validate() -> [String : String] {
		var errs = [String : String]()
		if let toFld = toField, toFld != "" && (self.toAddress.value?.isValidAddress() ?? false) {
			
		}
		else {
			errs[cellIdentifierPrefix.address.rawValue] = "ADDRESS OR USERNAME IS INCORRECT".localized()
		}
		
		if let amnt = self.amount.value, amnt > 0 {
			
		}
		else {
			errs[cellIdentifierPrefix.address.rawValue] = "AMOUNT IS INCORRECT".localized()
		}
		
		return errs
	}
	
	func validateField(item: BaseCellItem, value: String) -> Bool {
		
		if item.identifier.hasPrefix(cellIdentifierPrefix.address.rawValue) {
			self.toField = value
			
			return isToValid(to: value)
		}
		else if item.identifier.hasPrefix(cellIdentifierPrefix.amount.rawValue) {
			self.amountField = value.replacingOccurrences(of: ",", with: ".")
			
			return isAmountValid(amount: Double(value) ?? 0)
		}
		
		assert(true)
		return false
	}
	
	func submitField(item: BaseCellItem, value: String) {
		
//		if item.identifier.hasPrefix(cellIdentifierPrefix.address.rawValue) {
//			self.toField = value
//
//			if isAmountValid(amount: self.amount.value ?? 0) {
//				amountStateObservable.value = .default
//			}
//			else {
//				amountStateObservable.value = .invalid(error: "AMOUNT IS INCORRECT".localized())
//			}
//		}
//		else
		if item.identifier.hasPrefix(cellIdentifierPrefix.amount.rawValue) {
			self.amountField = value.replacingOccurrences(of: ",", with: ".")
			
			if isAmountValid(amount: self.amount.value ?? 0) {
				amountStateObservable.value = .default
			}
			else {
				amountStateObservable.value = .invalid(error: "AMOUNT IS INCORRECT".localized())
			}
		}
	}
	
	func isToValid(to: String) -> Bool {
		let usernameTest = NSPredicate(format:"SELF MATCHES %@", "^@[a-zA-Z0-9_]{5,32}")
		let usernameTest1 = NSPredicate(format:"SELF MATCHES %@", "^[a-zA-Z0-9_]{5,32}")
		let addressTest = NSPredicate(format:"SELF MATCHES %@", "^Mx[a-zA-Z0-9]{40}$")
		return usernameTest.evaluate(with: to) || usernameTest1.evaluate(with: to) || addressTest.evaluate(with: to) || to.isValidEmail()
	}
	
	func isAmountValid(amount: Double) -> Bool {
		return amount <= (selectedAddressBalance ?? 0) && amount > 0
	}
	
	func getAddress() {
		self.toAddress.value = nil
		
		let to = (toField ?? "")
		
		guard isToValid(to: to) else {
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
		return sections.value[safe: section]?.items.count ?? 0
	}

	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections.value[safe: section]?.items[safe: row]
	}
	
	//MARK: -
	
	func accountPickerItems() -> [PickerTableViewCellPickerItem] {
		var ret = [AccountPickerItem]()

		let balances = Session.shared.allBalances.value
		balances.keys.forEach { (address) in
			balances[address]?.keys.forEach({ (coin) in
				let balance = (balances[address]?[coin] ?? 0.0)
				
//				guard balance > 0 else { return }
				
				let title = coin + " (" + String(balance) + ")"
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
		
		let title = coin + " (" + String(balance) + ")"
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
				
				guard let address = self?.toAddress.value, let amount = self?.amount.value else {
					//Show error?
					return
				}
				
				let vm = self?.sendViewModel(to: address, amount: amount)
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
		
		MinterCore.TransactionManagerr.default.transactionCount(address: "Mx" + self.selectedAddress!) { [weak self] (count, err) in
			
			var success = false
			
			defer {
				self?.isLoadingNonce.value = false
				completion?(success)
			}
			
			guard nil == err, nil != count else {
				success = false
				return
			}
			
			self?.nonce.value = (count ?? 0) + 1
			success = true
		}
	}
	
	func sendTX() {
		
		guard let to = self.toAddress.value, let amount = self.amount.value, let selectedCoin = self.selectedCoin.value, let nonce = self.nonce.value else {
			self.notifiableError.value = NotifiableError(title: "Transaction can't be sent", text: nil)
			return
		}
		
		DispatchQueue.global().async { [weak self] in
			
			guard let mnemonic = self?.accountManager.mnemonic(for: self!.selectedAddress!), let seed = self?.accountManager.seed(mnemonic: mnemonic) else {
				//Error no Private key found
				assert(true)
				self?.notifiableError.value = NotifiableError(title: "No private key found", text: nil)
				return
			}
			
			guard let nonce = self?.nonce.value, let to = self?.toAddress.value, let selectedCoin = self?.selectedCoin.value, let amount = self?.amount.value else {
				return
			}
			
			self?.sendTx(seed: seed, nonce: nonce, to: to, coin: selectedCoin, amount: amount) { [weak self] res in
				
				if res == true {
					
					self?.clear()
					
					self?.createSections()
					
					DispatchQueue.main.async {
						self?.showPopup.value = PopupRouter.sentPopupViewCointroller(viewModel: self!.sentViewModel(to: to))
					}
					
					DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2), execute: {
						Session.shared.loadTransactions()
						SessionHelper.reloadAccounts()
					})
				}	
			}
		}
	}
	
	func sendTx(seed: Data, nonce: Int, to: String, coin: String, amount: Double, completion: ((Bool?) -> ())? = nil) {
		
		let newPk = self.accountManager.privateKey(from: seed)
		let nonce = BigUInt(nonce)
		
		
		guard let value = BigUInt(String(BigInt(amount * pow(10, 18)))) else {
			completion?(false)
			return
		}
		
		let tx = SendCoinRawTransaction(nonce: nonce, to: to, value: value, coin: coin.uppercased())
		let pkString = newPk.raw.toHexString()
		
		guard let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: pkString) else {
			completion?(false)
			return
		}
		
		self.nonce.value = nil
		
		MinterCore.TransactionManagerr.default.send(tx: signedTx) { [weak self] (hash, status, err) in
			
			var res = false
			
			defer {
				completion?(res)
			}
			
			guard err == nil && nil != hash else {
				self?.txError.value = NotifiableError(title: nil != status ? status : "Unable to send transaction".localized(), text: nil)
				res = false
				return
			}
			res = true
			self?.lastSentTransactionHash = hash
		}
	}
	
	//MARK: -
	
	func sendViewModel(to: String, amount: Double) -> SendPopupViewModel {
		
		let vm = SendPopupViewModel()
		vm.amount = amount
		vm.coin = selectedCoin.value
		vm.username = to
		vm.avatarImage = MinterMyAPIURL.avatarAddress(address: to).url()
		vm.popupTitle = "You're Sending"
		vm.buttonTitle = "BIP!".localized()
		vm.cancelTitle = "CANCEL".localized()
		return vm
	}
	
	func sentViewModel(to: String) -> SentPopupViewModel {
		
		let vm = SentPopupViewModel()
		vm.actionButtonTitle = "VIEW TRANSACTION".localized()
		vm.avatarImage = MinterMyAPIURL.avatarAddress(address: to).url()
		vm.secondButtonTitle = "CLOSE".localized()
		vm.username = to
		vm.title = "Success!".localized()
		return vm
	}
	
	func countdownPopupViewModel() -> CountdownPopupViewModel {
		
		let vm = CountdownPopupViewModel()
		vm.popupTitle = "Please wait"
		vm.unit = (one: "second", two: "seconds", other: "seconds")
		vm.count = 13
		vm.desc1 = "Coins will be received in"
		vm.desc2 = "Too long? You can make a faster transaction for 0.00000001 BIP"
		vm.buttonTitle = "Express transaction"
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
