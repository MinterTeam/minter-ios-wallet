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
import BigInt

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
	
	var sections: [BaseTableSectionItem] = []
	
	private var selectedAddress: String?
	private var selectedCoin: String?
	private var lastSentTransactionHash: String?
	
	private let accountManager = AccountManager()
	
	var notifiableError = Variable<NotifiableError?>(nil)
	
	var successfullySentViewModel = Variable<SentPopupViewModel?>(nil)
	
	var showSuccessPopup : Observable<(SentPopupViewModel?, Bool)> {
		return Observable.combineLatest(self.successfullySentViewModel.asObservable(), countdownFinished.asObservable())
	}
	
	var countdownFinished = Variable(false)
	
	//MARK: -

	override init() {
		super.init()
		
		createSections()
	}
	
	//MARK: - Sections
	
	func createSections() {
		let username = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Username")
		username.title = "CHOOSE @USERNAME".localized()
		username.prefix = "@"
		
		let coin = PickerTableViewCellItem(reuseIdentifier: "PickerTableViewCell", identifier: "PickerTableViewCell_Coin")
		coin.title = "COIN".localized()
//		coin.
		
		let amount = TextFieldTableViewCellItem(reuseIdentifier: "TextFieldTableViewCell", identifier: "TextFieldTableViewCell_Amount")
		amount.title = "AMOUNT".localized()
		
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
		sections.append(section)
	}

	//MARK: - Rows

	func rowsCount(for section: Int) -> Int {
		return sections[safe: section]?.items.count ?? 0
	}

	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections[safe: section]?.items[safe: row]
	}
	
	//MARK: -
	
	func accountPickerItems() -> [AccountPickerItem] {
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
		return ret
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
	
	func send(to: String, amount: Double) {
		
		guard to.isValidAddress(), nil != selectedCoin else {
			self.notifiableError.value = NotifiableError(title: "Receiver address isn't valid", text: nil)
			return
		}
		
		guard let mnemonic = accountManager.mnemonic(for: selectedAddress!), let seed = accountManager.seed(mnemonic: mnemonic) else {
			//Error no Private key found
			self.notifiableError.value = NotifiableError(title: "No private key found", text: nil)
			return
		}
		
		countdownFinished.value = false
		
		MinterCore.TransactionManager.default.transactionCount(address: "Mx" + selectedAddress!) { [weak self] (count, err) in
			
			guard nil == err, nil != count else {
				self?.notifiableError.value = NotifiableError(title: "Can't receive nonce", text: nil)
				return
			}
			
			guard let coin = self?.selectedCoin else {
				self?.notifiableError.value = NotifiableError(title: "Should select coin", text: nil)
				return
			}
			
			let pk = PrivateKey(seed: seed)
			let newPk = pk.derive(at: 44, hardened: true).derive(at: 60, hardened: true).derive(at: 0, hardened: true).derive(at: 0).derive(at: 0)
			
			
			let nonce = BigUInt((count ?? 0) + 1)
			let value = BigUInt(amount * 100000000)
			let tx = SendCoinRawTransaction(nonce: nonce, to: to, value: value, coin: coin)
			let pkString = newPk.raw.toHexString()
			
			guard let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: pkString) else {
				return
			}
			
			MinterCore.TransactionManager.default.send(tx: signedTx) { (hash, status, err) in
				guard err == nil && nil != hash else {
					self?.notifiableError.value = NotifiableError(title: nil != status ? status : "TX Error", text: nil)
					return
				}
				
				self?.lastSentTransactionHash = hash
				
				self?.successfullySentViewModel.value = self!.sentViewModel(to: to)
				
				Session.shared.loadTransactions()
				SessionHelper.reloadAccounts()
			}
		}
	}
	
	//MARK: -
	
	func sendViewModel(to: String, amount: Double) -> SendPopupViewModel {
		
		let sendVM = SendPopupViewModel()
		sendVM.amount = amount
		sendVM.coin = selectedCoin
		sendVM.username = to
		sendVM.avatarImage = UIImage(named: "AvatarPlaceholderImage")
		sendVM.popupTitle = "You're Sending"
		sendVM.buttonTitle = "BIP!".localized()
		sendVM.cancelTitle = "CANCEL".localized()
		return sendVM
	}
	
	func sentViewModel(to: String) -> SentPopupViewModel {
		
		let vm = SentPopupViewModel()
		vm.actionButtonTitle = "VIEW TRANSACTION".localized()
		vm.avatarImage = UIImage(named: "AvatarPlaceholderImage")
		vm.secondButtonTitle = "CANCEL".localized()
		vm.username = to
		vm.title = "Success!".localized()
		return vm
	}
	
	//MARK: -
	
	func lastTransactionExplorerURL() -> URL? {
		guard nil != lastSentTransactionHash else {
			return nil
		}
		
		return URL(string: MinterExplorerBaseURL + "/transactions/" + (lastSentTransactionHash ?? ""))
	}

}
