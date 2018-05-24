//
//  TransactionsTransactionsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 10/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import MinterCore
import MinterExplorer


class TransactionsViewModel: BaseViewModel {

	//MARK: -
	
	var title: String {
		get {
			return "All Transactions".localized()
		}
	}
	
	override init() {
		super.init()
		
//		createSections()
	}
	
	private var sectionTitleDateFormatter = DateFormatter() {
		didSet {
			sectionTitleDateFormatter.dateFormat = "EEEE, dd MMM"
		}
	}

	
	//MARK: -
	
	private var disposeBag = DisposeBag()
	
	private var sections = Variable([BaseTableSectionItem]())
	
	var sectionsObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}
	
	private var page = 0
	
	private var transactions = [Transaction]()
	
	private var isLoading = false
	
	func createSections(transactions: [Transaction]?) {
		
		//		var sctns = [BaseTableSectionItem]()
		
		
		//		var section = BaseTableSectionItem(header: )
		//		section.items = [transaction, separator]
		
		
//		sections.value.append(sctns)
		
		transactions?.forEach({ (transaction) in
			
			
			let sectionName =
			
			
	
			
			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell")
			let transaction = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell")
			transaction.amount = 10
			transaction.title = "McDonalds"
			transaction.coin = "GRAM"
			transaction.from = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
			transaction.to = "Mx86d167ffe6c81dd83a20e3731ed66dddaac42488"
			transaction.date = sectionTitleDateFormatter.string(from: transaction.date)
			transaction.image = UIImage(named: "AvatarPlaceholderImage")
		})
	}
	
	private func sectionTitle(for date: Date) -> String {
		
		Date.isIn
		sectionTitleDateFormatter.string(from: transaction.date)
	}
	
	//MARK: -
	
	func loadData() {
		
		let addresses = Session.shared.accounts.value.map { (acc) -> String in
			return "Mx" + acc.address
		}
		
		isLoading = true
		
		MinterExplorer.TransactionManager.default.transactions(addresses: addresses, page: self.page) { [weak self] (transaction, error) in
			guard nil == error && nil != transaction && (transaction?.count ?? 0) > 0 else {
				//stop paging
				return
			}
			
			self?.transactions.append(contentsOf: transaction!)
			
			self?.isLoading = false
			
		}

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
	
}
