//
//  TransactionsTransactionsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 10/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift


class TransactionsViewModel: BaseViewModel {

	var sections: [BaseTableSectionItem] = []
	
	var title: String {
		get {
			return "Transactions".localized()
		}
	}

	override init() {
		super.init()
		
		createSections()
	}
	
	func createSections() {
		
		let transaction = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell")
		transaction.amount = 10
		transaction.title = "McDonalds"
		transaction.coin = "GRAM"
		transaction.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction.date = Date()
		transaction.image = UIImage(named: "AvatarPlaceholderImage")
		
		let section = BaseTableSectionItem()
		section.title = "TODAY"
		
		section.cells = [transaction, transaction, transaction, transaction, transaction, transaction, transaction]
		
		sections.append(section)
	}
	
	//MARK: -
	
	func section(index: Int) -> BaseTableSectionItem? {
		return sections[safe: index]
	}
	
	func sectionsCount() -> Int {
		return sections.count
	}
	
	func rowsCount(for section: Int) -> Int {
		return sections[safe: section]?.cells.count ?? 0
	}
	
	func cellItem(section: Int, row: Int) -> BaseCellItem? {
		return sections[safe: section]?.cells[safe: row]
	}
	
}
