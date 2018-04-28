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
			return "All Transactions".localized()
		}
	}

	override init() {
		super.init()
		
		createSections()
	}
	
	func createSections() {
		
		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
		
		let transaction = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell")
		transaction.amount = 10
		transaction.title = "McDonalds"
		transaction.coin = "GRAM"
		transaction.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction.date = Date()
		transaction.image = UIImage(named: "AvatarPlaceholderImage")
		
		let transaction1 = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell")
		transaction1.title = "Starbucks"
		transaction1.image = UIImage(named: "AvatarPlaceholderImage")
		transaction1.date = Date()
		transaction1.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction1.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction1.coin = "STBCKS"
		transaction1.amount = 10.01
		
		let transaction2 = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell")
		transaction2.title = "Tesla"
		transaction2.image = UIImage(named: "AvatarPlaceholderImage")
		transaction2.date = Date()
		transaction2.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction2.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction2.coin = "TSL"
		transaction2.amount = 270000000000
		
		let transaction3 = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell")
		transaction3.title = "McDonalds"
		transaction3.image = UIImage(named: "AvatarPlaceholderImage")
		transaction3.date = Date()
		transaction3.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction3.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction3.coin = "MCD"
		transaction3.amount = -10000.42
		
		let section = BaseTableSectionItem()
		section.title = "TODAY"
		
		section.cells = [transaction, separator, transaction2, separator, transaction3, separator, transaction1, separator, transaction3, separator, transaction1, separator, transaction2, separator]
		
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
