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
	
	//MARK: -

	var title: String {
		get {
			return "Send".localized()
		}
	}
	
	//MARK: -
	
	var sections = Variable([BaseTableSectionItem]())
	
	private var selectedAddress: String?
	private var selectedCoin: String?
	private var lastSentTransactionHash: String?
	private var to: String?
	private var amount: Double?
	private var nonce: Int? = 0
	
	private let accountManager = AccountManager()
	
	var notifiableError = Variable<NotifiableError?>(nil)
	var txError = Variable<NotifiableError?>(nil)
	
	var successfullySentViewModel = Variable<SentPopupViewModel?>(nil)
	
	var showPopup = Variable<PopupViewController?>(nil)
	
	//used to send request before real countdown finished
	var fakeCountdownFinished = Variable(false)
	var countdownFinished = Variable(false)
	
	var isCountingDown = false
	
	private let disposeBag = DisposeBag()
	
	//MARK: -

	override init() {
		super.init()
		
		Session.shared.allBalances.asObservable().filter({ (_) -> Bool in
			return true //nil == self.selectedAddress
		}).subscribe(onNext: { [weak self] (val) in
			self?.createSections()
		}).disposed(by: disposeBag)
		
		createSections()
		
		fakeCountdownFinished.asObservable().filter({ (val) -> Bool in
			return val == true
		}).subscribe(onNext: { [weak self] (val) in
			self?.isCountingDown = false
			
			guard let to = self?.to, let amount = self?.amount, let selectedCoin = self?.selectedCoin, let nonce = self?.nonce else {
				return
			}
			DispatchQueue.global().async {
				
				guard let mnemonic = self?.accountManager.mnemonic(for: self!.selectedAddress!), let seed = self?.accountManager.seed(mnemonic: mnemonic) else {
					//Error no Private key found
					assert(true)
					self?.notifiableError.value = NotifiableError(title: "No private key found", text: nil)
					return
				}
				
				self?.sendTx(seed: seed, nonce: nonce, to: to, coin: selectedCoin, amount: amount)
			}
			
		}).disposed(by: disposeBag)
		
		Observable.combineLatest(fakeCountdownFinished.asObservable(), countdownFinished.asObservable()).subscribe { [weak self] (val) in
			
			guard let to = self?.to, val.event.element?.0 == true && val.event.element?.1 == true else {
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
		
		let username = TextViewTableViewCellItem(reuseIdentifier: "TextViewTableViewCell", identifier: "TextViewTableViewCell_Username")
		username.title = "TO (@USERNAME, EMAIL, MOBILE IR MX ADDRESS)".localized()
		username.rules = [RegexRule(regex: "^Mx[a-zA-Z0-9]{40}$", message: "INCORRECT ADDRESS".localized())]
		
		let coin = PickerTableViewCellItem(reuseIdentifier: "PickerTableViewCell", identifier: "PickerTableViewCell_Coin")
		coin.title = "COIN".localized()
		if nil != self.selectedAddress && nil != self.selectedCoin {
			let item = accountPickerItems().filter { (item) -> Bool in
				if let object = item.object as? AccountPickerItem {
					return selectedAddress == object.address && selectedCoin == object.coin
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
				selectedCoin = object.coin
			}
		}
		
		let amount = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Amount")
		amount.title = "AMOUNT".localized()
		amount.rules = [FloatRule(message: "INCORRECT AMOUNT".localized())]
		
		let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell", identifier: "TwoTitleTableViewCell_TransactionFee")
		fee.title = "Transaction Fee".localized()
		fee.subtitle = "0.00000001 BIP"
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
		
		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell", identifier: "BlankTableViewCell")
		
		let sendForFree = SwitchTableViewCellItem(reuseIdentifier: "SwitchTableViewCell", identifier: "SwitchTableViewCell")
		sendForFree.title = "Send for free!".localized()
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell")
		button.title = "SEND!".localized()
		button.buttonPattern = "purple"
		
		var section = BaseTableSectionItem(header: "")
		section.items = [coin, username, amount, fee, separator, blank, sendForFree, separator, blank, button]
		sections.value = [section]
		
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
				
				guard balance > 0 else { return }
				
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
		guard let adrs = selectedAddress, let coin = selectedCoin else {
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
			return item.address?.stripMinterHexPrefix() == acc.key.stripMinterHexPrefix()
		}.first
		
		guard nil != balance else {
			return
		}
		
		selectedAddress = balance?.key
		selectedCoin = item.coin
	}
	
	//MARK: -
	
	func send(to: String, amount: Double, isFree: Bool = true) {
		
		guard to.isValidAddress(), nil != selectedCoin else {
			assert(true)
			self.notifiableError.value = NotifiableError(title: "Receiver address isn't valid", text: nil)
			return
		}
		
		isCountingDown = true
		
		self.to = to
		self.amount = amount
		
		DispatchQueue.global().async {
			self.prepareTX(to: to, amount: amount)
		}

	}
	
	func prepareTX(to: String, amount: Double) {
		
		self.countdownFinished.value = false
		self.fakeCountdownFinished.value = false
		
		MinterCore.TransactionManager.default.transactionCount(address: "Mx" + self.selectedAddress!) { [weak self] (count, err) in
			
			guard nil == err, nil != count else {
				assert(true)
				self?.notifiableError.value = NotifiableError(title: "Can't receive nonce", text: nil)
				return
			}
			
			self?.nonce = (count ?? 0) + 1
			
			//Get difficulty hash?
			DispatchQueue.main.async {
				self?.showPopup.value = PopupRouter.countdownPopupViewController(viewModel: self!.countdownPopupViewModel())
			}

		}
	}
	
	func sendTx(seed: Data, nonce: Int, to: String, coin: String, amount: Double) {
		
		let newPk = self.accountManager.privateKey(from: seed)
		
		let nonce = BigUInt(nonce)
		let value = BigUInt(amount * TransactionCoinFactor)
		let tx = SendCoinRawTransaction(nonce: nonce, to: to, value: value, coin: coin)
		let pkString = newPk.raw.toHexString()
		
		guard let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: pkString) else {
			return
		}
		
		MinterCore.TransactionManager.default.send(tx: signedTx) { [weak self] (hash, status, err) in
			guard err == nil && nil != hash else {
				self?.txError.value = NotifiableError(title: nil != status ? status : "Unable to send transaction".localized(), text: nil)
				return
			}
			
			self?.lastSentTransactionHash = hash
		}
	}
	
	//MARK: -
	
	func sendViewModel(to: String, amount: Double) -> SendPopupViewModel {
		
		let vm = SendPopupViewModel()
		vm.amount = amount
		vm.coin = selectedCoin
		vm.username = to
		vm.avatarImage = MinterMyAPIURL.avatar(address: to).url()
		vm.popupTitle = "You're Sending"
		vm.buttonTitle = "BIP!".localized()
		vm.cancelTitle = "CANCEL".localized()
		return vm
	}
	
	func sentViewModel(to: String) -> SentPopupViewModel {
		
		let vm = SentPopupViewModel()
		vm.actionButtonTitle = "VIEW TRANSACTION".localized()
		vm.avatarImage = MinterMyAPIURL.avatar(address: to).url()
		vm.secondButtonTitle = "CANCEL".localized()
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
