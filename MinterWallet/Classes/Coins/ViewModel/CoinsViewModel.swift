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
		
		let button1 = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell", identifier: "ButtonTableViewCell_Convert")
		button1.title = "CONVERT".localized()
		
		section1.cells = [coin1, coin2, coin3, button1]
		
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
