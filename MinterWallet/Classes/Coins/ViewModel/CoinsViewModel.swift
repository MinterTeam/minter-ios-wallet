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
	
	//MARK: -

	var title: String {
		get {
			return "Coins".localized()
		}
	}
	
	var basicCoinSymbol: String {
		return Coin.defaultCoin().symbol ?? "bip"
	}
	
	private var disposeBag = DisposeBag()
	
	private var sections = Variable([BaseTableSectionItem]())
	
	var sectionsObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}
	
	var totalBalanceObservable: Observable<Double> {
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
	
	//MARK: -

	override init() {
		super.init()
		
		Observable.combineLatest(Session.shared.transactions.asObservable(), Session.shared.balances.asObservable())
		.subscribe(onNext: { [weak self] (transactions) in
			self?.createSection()
		}).disposed(by: disposeBag)
		
	}
	
	func createSection() {
		
		var sctns = [BaseTableSectionItem]()
		
		var section = BaseTableSectionItem(header: "LATEST TRANSACTIONS".localized())
		section.identifier = "BaseTableSectionItem_1"
		
		Array(Session.shared.transactions.value[safe: 0..<5] ?? []).forEach { (transactionItem) in
			
			guard let transaction = transactionItem.transaction else {
				return
			}
			
			let user = transactionItem.user
			
			let sectionId = (transaction.hash  ?? String.random(length: 20))// + String(transaction.date?.timeIntervalSinceNow ?? 0)
			
			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_" + sectionId)
			
			var signMultiplier = 1.0
			let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
				account.address.stripMinterHexPrefix().lowercased() == transaction.from?.stripMinterHexPrefix().lowercased()
			})
			
			var title = ""
			if hasAddress {
				title = user?.username != nil ? "@" + user!.username! : (transaction.to ?? "")
				signMultiplier = -1.0
			}
			else {
				title = user?.username != nil ? "@" + user!.username! : (transaction.from ?? "")
			}
			
			let transactionCellItem = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_\(sectionId)")
			transactionCellItem.txHash = transaction.hash
			transactionCellItem.title = title
			transactionCellItem.image = MinterMyAPIURL.avatarAddress(address: ((signMultiplier > 0 ? transaction.from : transaction.to) ?? "")).url()
			transactionCellItem.date = transaction.date
			transactionCellItem.from = transaction.from
			transactionCellItem.to = transaction.to
			transactionCellItem.coin = transaction.coinSymbol
			transactionCellItem.amount = (transaction.value ?? 0) * signMultiplier
			
			section.items.append(transactionCellItem)
			section.items.append(separator)
		}
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell_Transactions")
		button.buttonPattern = "blank"
		button.title = "ALL TRANSACTIONS".localized()
		
		section.items.append(button)
		
		
		var section1 = BaseTableSectionItem(header: "MY COINS".localized())
		section1.identifier = "BaseTableSectionItem_2"

		Session.shared.balances.value.keys.forEach { (key) in
			
			let bal = Session.shared.balances.value
				
			let cellAdditionalId = "\(key)"
			
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
	
}
