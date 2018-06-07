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
	
	private var disposeBag = DisposeBag()
	
	private var sections = Variable([BaseTableSectionItem]())
	
	var sectionsObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}
	
	//MARK: -

	override init() {
		super.init()
		
		Observable.combineLatest(Session.shared.transactions.asObservable(), Session.shared.balances.asObservable())
			.subscribe(onNext: { [weak self] (transactions) in
				self?.createSection()
		}).disposed(by: disposeBag)
		
		Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(updateBalance), userInfo: nil, repeats: true).fire()
		
		createSection()
	}
	
	func createSection() {
		
		var sctns = [BaseTableSectionItem]()
		
		var section = BaseTableSectionItem(header: "LATEST TRANSACTIONS".localized())
		section.identifier = "BaseTableSectionItem_1"
		
		Array(Session.shared.transactions.value[safe: 0..<5] ?? []).forEach { (transaction) in
			
			let sectionId = transaction.hash ?? String.random(length: 20)
			
			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_\(sectionId)")
			
			var signMultiplier = 1.0
			let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
				account.address == transaction.from?.stripMinterHexPrefix()
			})
			
			var title = ""
			if hasAddress {
				title = transaction.to ?? ""
				signMultiplier = -1.0
			}
			else {
				title = transaction.from ?? ""
			}
			
			let transactionCellItem = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_\(sectionId)")
			transactionCellItem.txHash = transaction.hash
			transactionCellItem.title = title
			transactionCellItem.image = MinterMyAPIURL.avatar(address: ((signMultiplier > 0 ? transaction.from : transaction.to) ?? "")).url()
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
