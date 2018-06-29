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
import MinterMy
import AFDateHelper


class TransactionsViewModel: BaseViewModel {

	//MARK: -
	
	var title: String {
		get {
			return "All Transactions".localized()
		}
	}
	
	override init() {
		super.init()
		
		loadData()
		
		sectionTitleDateFormatter.dateFormat = "EEEE, dd MMM"
		
		sectionTitleDateFullFormatter.dateFormat = "EEEE, dd MMM YYYY"
	}
	
	private var sectionTitleDateFormatter = DateFormatter()
	
	private var sectionTitleDateFullFormatter = DateFormatter()

	
	//MARK: -
	
	private var disposeBag = DisposeBag()
	
	private var sections = Variable([BaseTableSectionItem]())
	
	var sectionsObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}
	
	private var page = 1
	
	private var transactions = [TransactionItem]()
	
	private var isLoading = false
	
	private var canLoadMore = true
	
	
	func createSections(with transactions: [TransactionItem]?) {
		
		var newSections = [BaseTableSectionItem]()
		var items = [String : [BaseCellItem]]()
		
		self.transactions.forEach({ (item) in
			
			guard let transaction = item.transaction else {
				return
			}
			
			let user = item.user
			
			let sectionName = sectionTitle(for: transaction.date)
			let sectionCandidate = newSections.index(where: { (item) -> Bool in
				return item.header == sectionName
			})
			
			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_\(String.random(length: 20))")
			
			var signMultiplier = 1.0
			let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
				account.address.stripMinterHexPrefix().lowercased() == transaction.from?.stripMinterHexPrefix().lowercased()
			})
			
			var title = ""
			if hasAddress {
				title = user?.username ?? (transaction.to ?? "")
				signMultiplier = -1.0
			}
			else {
				title = user?.username ?? (transaction.from ?? "")
			}
			
			let transactionCellItem = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_\(transaction.hash ?? String.random(length: 20))")
			transactionCellItem.txHash = transaction.hash
			transactionCellItem.title = title
			transactionCellItem.image = MinterMyAPIURL.avatarAddress(address: ((signMultiplier > 0 ? transaction.from : transaction.to) ?? "")).url()
			transactionCellItem.date = transaction.date
			transactionCellItem.from = transaction.from
			transactionCellItem.to = transaction.to
			transactionCellItem.coin = transaction.coinSymbol
			transactionCellItem.amount = (transaction.value ?? 0) * signMultiplier
			
			
			var section: BaseTableSectionItem?
			if let idx = sectionCandidate, var sctn = newSections[safe: idx] {
				section = sctn
			}
			else {
				section = BaseTableSectionItem(header: sectionName)
				section?.identifier = sectionName
				newSections.append(section!)
			}
			if nil == items[sectionName] {
				items[sectionName] = []
			}
			items[sectionName]?.append(transactionCellItem)
			items[sectionName]?.append(separator)

		})
		
		let sctns = newSections.map({ (item) -> BaseTableSectionItem in
			return BaseTableSectionItem(header: item.header, items: (items[item.header] ?? []))
		})
		
		self.sections.value = sctns
		
	}
	
	private func sectionTitle(for date: Date?) -> String {
		
		guard nil != date else {
			return " "
		}
		
		if date!.compare(.isToday) {
			return "TODAY".localized()
		}
		else if date!.compare(.isYesterday) {
			return "YESTERDAY".localized()
		}
		else if date!.compare(.isThisYear) {
			return sectionTitleDateFormatter.string(from: date!).uppercased()
		}
		else {
			return sectionTitleDateFullFormatter.string(from: date!).uppercased()
		}
	}
	
	//MARK: -
	
	func loadData() {

		if isLoading || !canLoadMore { return }
		isLoading = true
		
		let addresses = Session.shared.accounts.value.map { (acc) -> String in
			return "Mx" + acc.address
		}
		
		TransactionManager().transactions(page: self.page) { [weak self] (transactions, users, error) in
			
			self?.page += 1
			
			guard nil == error && nil != transactions && (transactions?.count ?? 0) > 0 else {
				//stop paging
				self?.canLoadMore = false
				return
			}
			
			let items = transactions?.map({ (transaction) -> TransactionItem in
				let item = TransactionItem()
				item.transaction = transaction
				
				let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
					account.address.stripMinterHexPrefix().lowercased() == transaction.from?.stripMinterHexPrefix().lowercased()
				})
				
				var key = transaction.from?.lowercased()
				if hasAddress, let to = transaction.to {
					key = to.lowercased()
				}
				if let key = key, let usr = users?[key] {
					item.user = usr
				}
				return item
			}) ?? []
			
			self?.transactions.append(contentsOf: items)
			
			self?.isLoading = false
			
			self?.createSections(with: items)
			
		}
	}
	
	func shouldLoadMore(_ indexPath: IndexPath) -> Bool {
		guard canLoadMore && isLoading == false else {
			return false
		}
		
		let cellItemsLoadedTotal = totalNumberOfItems()
		let fromBottomConstant = 10
		if cellItemsLoadedTotal <= fromBottomConstant {
			return false
		}
		
		var itemsCountFromPrevSections = 0
		let endSection = indexPath.section - 1
		if endSection >= 0 {
			for i in 0...endSection {
				itemsCountFromPrevSections = itemsCountFromPrevSections + rowsCount(for: i)
			}
		}
		let cellTotalIndex = (indexPath.row + 1) + itemsCountFromPrevSections
		if cellTotalIndex > cellItemsLoadedTotal - fromBottomConstant {
			return true
		}
		return false
	}
	
	fileprivate func totalNumberOfItems() -> Int {
		return sections.value.reduce(0) { $0 +  $1.items.count }
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
	
}
