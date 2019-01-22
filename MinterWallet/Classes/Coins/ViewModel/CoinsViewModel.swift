//
//  CoinsCoinsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import MinterExplorer
import MinterCore
import MinterMy


class CoinsViewModel: BaseViewModel {
	
	enum cellIdentifierPrefix : String {
	 case transactions = "ButtonTableViewCell_Transactions"
	 case convert = "ButtonTableViewCell_Convert"
	}
	
	
	//MARK: -

	var title: String {
		get {
			return "Coins".localized()
		}
	}
	
	var basicCoinSymbol: String {
		return Coin.baseCoin().symbol ?? "bip"
	}
	
	private var disposeBag = DisposeBag()
	
	private var sections = Variable([BaseTableSectionItem]())
	
	var sectionsObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}
	
	var totalBalanceObservable: Observable<Decimal> {
		return Session.shared.mainCoinBalance.asObservable()
	}
	
	var usernameViewObservable: Observable<User?> {
		return Session.shared.user.asObservable()
	}
	
	var rightButtonTitle: String {
		return "@" + (Session.shared.user.value?.username ?? "")
	}
	
	var rightButtonImage: URL? {
		var url: URL?
		if let id = Session.shared.user.value?.id {
			url = MinterMyAPIURL.avatarUserId(id: id).url()
		}
		if let avatarURLString = Session.shared.user.value?.avatar, let avatarURL = URL(string: avatarURLString) {
			url = avatarURL
		}
		
		return url
	}
	
	let formatter = CurrencyNumberFormatter.decimalFormatter
	
	//MARK: -

	override init() {
		super.init()
		
		Observable.combineLatest(Session.shared.transactions.asObservable(), Session.shared.balances.asObservable(), Session.shared.allBalances.asObservable(), Session.shared.isLoggedIn.asObservable().distinctUntilChanged())
		.subscribe(onNext: { [weak self] (transactions) in
			self?.createSection()
		}).disposed(by: disposeBag)
	}
	
	func createSection() {
		
		var sctns = [BaseTableSectionItem]()
		
		var section = BaseTableSectionItem(header: "Latest Transactions".localized())
		section.identifier = "BaseTableSectionItem_1"
		
		let trans = Array(Session.shared.transactions.value[safe: 0..<5] ?? [])
		if trans.count == 0 {
			section.items = []
		}
		
		trans.forEach { (transactionItem) in
			
			guard let transaction = transactionItem.transaction else {
				return
			}
			
			let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash ?? String.random(length: 20))

			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_" + sectionId)
			
			if transaction.type == .send {
				if let transactionCellItem = self.sendTransactionItem(with: transactionItem) {
					section.items.append(transactionCellItem)
					section.items.append(separator)
				}
			}
			else if transaction.type == .buy || transaction.type == .sell {
				if let transactionCellItem = self.convertTransactionItem(with: transactionItem) {
					section.items.append(transactionCellItem)
					section.items.append(separator)
				}
			}
			else if transaction.type == .sellAllCoins {
				if let transactionCellItem = self.convertTransactionItem(with: transactionItem) {
					section.items.append(transactionCellItem)
					section.items.append(separator)
				}
			}
			else if transaction.type == .delegate || transaction.type == .unbond {
				if let transactionCellItem = self.delegateTransactionItem(with: transactionItem) {
					section.items.append(transactionCellItem)
					section.items.append(separator)
				}
			}
		}
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell_Transactions")
		button.buttonPattern = "blank"
		button.title = "ALL TRANSACTIONS".localized()
		
		section.items.append(button)
		
		
		var section1 = BaseTableSectionItem(header: "My Coins".localized())
		section1.identifier = "BaseTableSectionItem_2"

		Session.shared.balances.value.keys.sorted(by: { (key1, key2) -> Bool in
			return key1 < key2
		}).forEach { (key) in
			
			let bal = Session.shared.balances.value
			
			let balanceKey = CurrencyNumberFormatter.decimalShortFormatter.string(from: (bal[key] ?? 0) as NSNumber)
			let cellAdditionalId = "\(key)_\(balanceKey ?? "")"
			
			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_\(cellAdditionalId)")
			
			let coin = CoinTableViewCellItem(reuseIdentifier: "CoinTableViewCell", identifier: "CoinTableViewCell_\(cellAdditionalId)")
			coin.title = key
			coin.image = UIImage(named: "AvatarPlaceholderImage")
			coin.imageURL = MinterMyAPIURL.avatarByCoin(coin: key).url()
			coin.coin = key
			coin.amount = bal[key]
			
			section1.items.append(coin)
			section1.items.append(separator)
		}
		
		let convertButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell_Convert")
		convertButton.buttonPattern = "blank"
		convertButton.title = "CONVERT".localized()
		
		section1.items.append(convertButton)
		
		if section.items.count > 1 {
			sctns.append(section)
		}
		
		if section1.items.count > 1 {
			sctns.append(section1)
		}
		
		if sctns.count == 0 {
			let loadingItem = LoadingTableViewCellItem(reuseIdentifier: "LoadingTableViewCell", identifier: "LoadingTableViewCell")
			loadingItem.isLoadingObservable = Session.shared.isLoading.asObservable()
			let sctn = BaseTableSectionItem(header: "", items: [loadingItem])
			sctns.append(sctn)
		}
		
		self.sections.value = sctns
		
	}
	
	func sendTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
		let user = transactionItem.user
		guard let transaction = transactionItem.transaction else {
			return nil
		}
		
		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))
		
		var signMultiplier = 1.0
		let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
			account.address.stripMinterHexPrefix().lowercased() == transaction.from?.stripMinterHexPrefix().lowercased()
		})
		
		var title = ""
		if hasAddress {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.to ?? "")
			signMultiplier = -1.0
		}
		else {
			title = user?.username != nil ? "@" + user!.username! : (transaction.from ?? "")
		}
		
		let transactionCellItem = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		transactionCellItem.image = MinterMyAPIURL.avatarAddress(address: ((signMultiplier > 0 ? transaction.from : transaction.data?.to) ?? "")).url()
		transactionCellItem.date = transaction.date
		transactionCellItem.from = transaction.from
		transactionCellItem.to = transaction.data?.to
		if let data = transaction.data as? MinterExplorer.SendCoinTransactionData {
			transactionCellItem.coin = data.coin
			transactionCellItem.amount = (data.amount ?? 0) * Decimal(signMultiplier)
		}

		return transactionCellItem
	}
	
	func convertTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
		
		let user = transactionItem.user
		guard let transaction = transactionItem.transaction else {
			return nil
		}
		
		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))
		
		var signMultiplier = 1.0
		let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
			account.address.stripMinterHexPrefix().lowercased() == transaction.from?.stripMinterHexPrefix().lowercased()
		})
		
		var title = ""
		if hasAddress {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.to ?? "")
			signMultiplier = -1.0
		}
		else {
			title = user?.username != nil ? "@" + user!.username! : (transaction.from ?? "")
		}
		
		
		let transactionCellItem = ConvertTransactionTableViewCellItem(reuseIdentifier: "ConvertTransactionTableViewCell", identifier: "ConvertTransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		transactionCellItem.date = transaction.date
		transactionCellItem.from = transaction.from
		transactionCellItem.to = transaction.data?.to
		
		
		var arrowSign = " > "
		if #available(iOS 11.0, *) {
			arrowSign = "  ⟶  "
		}
		
		//TODO: move to common
		if let data = transaction.data as? MinterExplorer.ConvertTransactionData {
			transactionCellItem.toCoin = data.toCoin
			transactionCellItem.fromCoin = data.fromCoin
			transactionCellItem.amount = (data.valueToBuy ?? 0)
			transactionCellItem.title = (data.fromCoin ?? "") + arrowSign + (data.toCoin ?? "")
		}
		else if let data = transaction.data as? MinterExplorer.SellAllCoinsTransactionData {
			transactionCellItem.toCoin = data.toCoin
			transactionCellItem.fromCoin = data.fromCoin
			transactionCellItem.title = (data.fromCoin ?? "") + arrowSign + (data.toCoin ?? "")
			transactionCellItem.amount = (data.value ?? 0)
		}
		
		return transactionCellItem

	}
	
	func delegateTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
		
		guard let transaction = transactionItem.transaction else {
			return nil
		}
		
		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))
		
		let transactionCellItem = DelegateTransactionTableViewCellItem(reuseIdentifier: "DelegateTransactionTableViewCell", identifier: "DelegateTransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.date = transaction.date
		
		let signMultiplier = transaction.type == .unbond ? 1.0 : -1.0
		//TODO: move to common
		if let data = transaction.data as? MinterExplorer.DelegateTransactionData {
			transactionCellItem.coin = data.coin
			transactionCellItem.amount = Decimal(signMultiplier) * (data.stake ?? 0)
			transactionCellItem.title = data.coin ?? ""
			transactionCellItem.to = data.pubKey ?? ""
			transactionCellItem.from = transaction.from ?? ""
			transactionCellItem.type = transaction.type == .unbond ? "Unbond".localized() : "Delegate".localized()
			transactionCellItem.image = transaction.type == .unbond ? UIImage(named: "unbondImage") : UIImage(named: "delegateImage")
			
		}
		
		return transactionCellItem
		
	}
	
	//MARK: -
	
	func section(index: Int) -> BaseTableSectionItem? {
		return sections.value[safe: index]
	}
	
	func sectionsCount() -> Int {
		return sections.value.count
	}
	
	func rowsCount(for section: Int) -> Int {
		return sections.value[safe: section]?.items.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections.value[safe: section]?.items[safe: row]
	}
	
	//MARK: -
	
	func explorerURL(section: Int, row: Int) -> URL? {
		if let item = self.cellItem(section: section, row: row) as? TransactionTableViewCellItem {
			return URL(string: MinterExplorerBaseURL + "/transactions/" + (item.txHash ?? ""))
		}
		else	if let item = self.cellItem(section: section, row: row) as? ConvertTransactionTableViewCellItem {
			return URL(string: MinterExplorerBaseURL + "/transactions/" + (item.txHash ?? ""))
		}
		else	if let item = self.cellItem(section: section, row: row) as? DelegateTransactionTableViewCellItem {
			return URL(string: MinterExplorerBaseURL + "/transactions/" + (item.txHash ?? ""))
		}
		return nil
	}
	
	//MARK: -
	
	func updateData() {
		Session.shared.loadTransactions()
	}
	
	@objc func updateBalance() {
		Session.shared.loadAccounts()
		Session.shared.loadTransactions()
	}
	
	//MARK: -
	
	func headerViewTitleText(with balance: Decimal) -> NSAttributedString {
		
		let formatter = CurrencyNumberFormatter.coinFormatter
		let balanceString = Array((formatter.string(from: balance as NSNumber) ?? "").split(separator: "."))
		
		let string = NSMutableAttributedString()
		string.append(NSAttributedString(string: String(balanceString[0]), attributes: [.foregroundColor : UIColor.white, .font : UIFont.boldFont(of: 32.0)]))
		string.append(NSAttributedString(string: ".", attributes: [.foregroundColor : UIColor.white, .font : UIFont.boldFont(of: 18.0)]))
		string.append(NSAttributedString(string: String(balanceString[1]), attributes: [.foregroundColor : UIColor.white, .font : UIFont.boldFont(of: 20.0)]))
		string.append(NSAttributedString(string: " " + self.basicCoinSymbol, attributes: [.foregroundColor : UIColor.white, .font : UIFont.boldFont(of: 18.0)]))
		
		return string
	}

}
