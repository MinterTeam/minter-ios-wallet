//
//  CoinsCoinsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import MinterExplorer


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
		
		Session.shared.transactions.asObservable().subscribe(onNext: { [weak self] (transactions) in
			self?.createSection()
		}).disposed(by: disposeBag)
		
		createSection()
	}
	
	func createSection() {
		
		var sctns = [BaseTableSectionItem]()
		
		var section = BaseTableSectionItem(header: "LATEST TRANSACTIONS".localized())
		section.identifier = "BaseTableSectionItem_1"
		
		Array(Session.shared.transactions.value[safe: 0..<5] ?? []).forEach { (transaction) in
			
			let sectionId = transaction.hash ?? String.random(length: 20)
			
			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_\(sectionId)")
			
			var title = ""
			var signMultiplier = 1.0
			let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
				account.address == transaction.to
			})
			
			if hasAddress {
				title = transaction.from ?? ""
				signMultiplier = -1.0
			}
			else {
				title = transaction.to ?? ""
			}
			
			let transactionCellItem = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_\(sectionId)")
			transactionCellItem.txHash = transaction.hash
			transactionCellItem.title = title
			transactionCellItem.image = UIImage(named: "AvatarPlaceholderImage")
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
		
		let coin1 = CoinTableViewCellItem(reuseIdentifier: "CoinTableViewCell", identifier: "CoinTableViewCell_11")
		coin1.title = "Starbucks"
		coin1.image = UIImage(named: "AvatarPlaceholderImage")
		coin1.date = Date()
		coin1.coin = "MCD"
		coin1.amount = 1
		
		let coin2 = CoinTableViewCellItem(reuseIdentifier: "CoinTableViewCell", identifier: "CoinTableViewCell_12")
		coin2.title = "Tesla"
		coin2.image = UIImage(named: "AvatarPlaceholderImage")
		coin2.date = Date()
		coin2.coin = "TSL"
		coin2.amount = 0.245654
		
		let coin3 = CoinTableViewCellItem(reuseIdentifier: "CoinTableViewCell", identifier: "CoinTableViewCell_13")
		coin3.title = "McDonalds"
		coin3.image = UIImage(named: "AvatarPlaceholderImage")
		coin3.date = Date()
		coin3.coin = "MCD"
		coin3.amount = 22.2234
		
		let convertButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell_Convert")
		convertButton.buttonPattern = "blank"
		convertButton.title = "CONVERT".localized()
		
		let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_\(String.random(length: 20))")
		let separator2 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_\(String.random(length: 20))")
		
		section1.items = [coin1, separator1, coin2, separator2, coin3, convertButton]
		
		sctns.append(section)
		sctns.append(section1)
		
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
			return URL(string: MinterExplorerBaseURL + "transactions/\(item.txHash ?? "")")
		}
		return nil
	}
	
}
