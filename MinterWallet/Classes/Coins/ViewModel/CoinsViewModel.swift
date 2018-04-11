//
//  CoinsCoinsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift


class CoinsViewModel: BaseViewModel {
	
	//MARK: -

	var title: String {
		get {
			return "Coins".localized()
		}
	}
	
	private var sections: [BaseTableSectionItem] = []
	
	//MARK: -

	override init() {
		super.init()
		
		createSection()
	}
	
	func createSection() {
		let section = BaseTableSectionItem()
		section.title = "LATEST TRANSACTIONS".localized()
		
		let transaction1 = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell")
		transaction1.title = "Starbucks"
		transaction1.image = UIImage(named: "AvatarPlaceholderImage")
		transaction1.date = Date()
		transaction1.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction1.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction1.coin = "MCD"
		transaction1.amount = 1000000
		
		let transaction2 = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell")
		transaction2.title = "Starbucks"
		transaction2.image = UIImage(named: "AvatarPlaceholderImage")
		transaction2.date = Date()
		transaction2.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction2.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction2.coin = "MCD"
		transaction2.amount = 100000
		
		let transaction3 = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell")
		transaction3.title = "McDonalds"
		transaction3.image = UIImage(named: "AvatarPlaceholderImage")
		transaction3.date = Date()
		transaction3.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction3.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction3.coin = "MCD"
		transaction3.amount = 10000
		
		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell_Transactions")
		button.title = "ALL TRANSACTIONS".localized()
		
		section.cells = [transaction1, transaction2, transaction3, button]
		
		let section1 = BaseTableSectionItem()
		section1.title = "MY COINS".localized()
		
		let transaction11 = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_11")
		transaction11.title = "Starbucks"
		transaction11.image = UIImage(named: "AvatarPlaceholderImage")
		transaction11.date = Date()
		transaction11.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction11.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction11.coin = "MCD"
		transaction11.amount = 1000000
		
		let transaction12 = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_12")
		transaction12.title = "Starbucks"
		transaction12.image = UIImage(named: "AvatarPlaceholderImage")
		transaction12.date = Date()
		transaction12.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction12.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction12.coin = "MCD"
		transaction12.amount = 100000
		
		let transaction13 = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_13")
		transaction13.title = "McDonalds"
		transaction13.image = UIImage(named: "AvatarPlaceholderImage")
		transaction13.date = Date()
		transaction13.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction13.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
		transaction13.coin = "MCD"
		transaction13.amount = 10000
		
		let button1 = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell_Convert")
		button1.title = "CONVERT".localized()
		
		section1.cells = [transaction11, transaction12, transaction13, button1]
		
		self.sections.append(section)
		self.sections.append(section1)
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
