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

class TransactionsViewModel: BaseViewModel, TransactionViewableViewModel {

	// MARK: -

	var title: String {
		get {
			return "All Transactions".localized()
		}
	}

	var addresses: [String] = []

	init(addresses: [String]? = nil) {
		super.init()

		sectionTitleDateFormatter.dateFormat = "EEEE, dd MMM"
		sectionTitleDateFullFormatter.dateFormat = "EEEE, dd MMM YYYY"

		if nil == addresses {
			self.addresses = Session.shared.accounts.value.map { (acc) -> String in
				return "Mx" + acc.address
			}
		} else {
			self.addresses = addresses ?? []
		}

		let loadingItem = LoadingTableViewCellItem(reuseIdentifier: "LoadingTableViewCell",
																							 identifier: "LoadingTableViewCell")
		loadingItem.isLoadingObservable = isLoading.asObservable()
		var section = BaseTableSectionItem(header: "", items: [loadingItem])
		section.identifier = "LoadingTableViewSection"
		self.sections.value.append(section)

		loadData()

		createSections(with: [])
	}

	private var sectionTitleDateFormatter = DateFormatter()
	private var sectionTitleDateFullFormatter = DateFormatter()
	private let manager = WalletTransactionManager()

	// MARK: -

	private var sections = Variable([BaseTableSectionItem]())

	var sectionsObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}
	private var page = 1
	private var transactions = [TransactionItem]()
	private var isLoading = Variable(false)
	private var canLoadMore = true

	var noTransactionsObservable: Observable<Bool> {
		return Observable.combineLatest(self.isLoading.asObservable(),
																		sections.asObservable()).map({ (val) -> Bool in
			return !self.isLoading.value
				&& self.canLoadMore == false
				&& self.transactions.count == 0
		})
	}

	func createSections(with transactions: [TransactionItem]?) {
		var newSections = [BaseTableSectionItem]()
		var items = [String : [BaseCellItem]]()

		transactions?.forEach({ (item) in
			guard let transaction = item.transaction else {
				return
			}

			let existingSections = self.sections.value.filter({ (section) -> Bool in
				return section.header == self.sectionTitle(for: transaction.date)
			})

			let sectionName = existingSections.count > 0 ? "" : sectionTitle(for: transaction.date)
			let sectionIdentifier: String!
			let sectionCandidate = newSections.index(where: { (item) -> Bool in
				return item.header == sectionName
			})

			let txn = item.transaction?.txn
			let cellId = (nil == txn ? String.random(length: 20) : String(txn!))
			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
																								 identifier: "SeparatorTableViewCell_" + cellId)

			var section: BaseTableSectionItem?
			if let idx = sectionCandidate, let sctn = newSections[safe: idx] {
				section = sctn
				sectionIdentifier = sctn.identifier
			} else {
				sectionIdentifier = String.random(length: 20)
				section = BaseTableSectionItem(header: sectionName)
				section?.identifier = sectionIdentifier
				newSections.append(section!)
			}

			if nil == items[sectionIdentifier] {
				items[sectionIdentifier] = []
			}

			guard let txType = transaction.type else { return }

			var transactionCellItem: BaseCellItem?
			switch txType {
			case .send:
				transactionCellItem = self.sendTransactionItem(with: item)
				break
			case .multisend:
				transactionCellItem = self.multisendTransactionItem(with: item)
				break
			case .buy, .sell, .sellAll:
				transactionCellItem = self.convertTransactionItem(with: item)
				break
			case .delegate, .unbond:
				transactionCellItem = self.delegateTransactionItem(with: item)
				break
			case .redeemCheck:
				transactionCellItem = self.redeemCheckTransactionItem(with: item)
				break
			case .create, .declare, .setCandidateOnline,
					 .setCandidateOffline, .createMultisig, .editCandidate:
				transactionCellItem = self.systemTransactionItem(with: item)
				break
			}
			if let transactionCellItem = transactionCellItem {
				items[sectionIdentifier]?.append(transactionCellItem)
				items[sectionIdentifier]?.append(separator)
			}
		})

		let sctns = newSections.map({ (item) -> BaseTableSectionItem in
			return BaseTableSectionItem(header: item.header, items: (items[item.identifier] ?? []))
		})

		//Should be loading section
		if let loadingIndex = self.sections.value.firstIndex(where: { (item) -> Bool in
			return item.identifier == "LoadingTableViewSection"
		}) {
			let loadingSection = self.sections.value[safe: loadingIndex]
			self.sections.value.remove(at: loadingIndex)
			self.sections.value += sctns
			if nil != loadingSection {
				self.sections.value.append(loadingSection!)
			}
		}
	}

	private func sectionTitle(for date: Date?) -> String {
		guard nil != date else {
			return " "
		}

		if date!.compare(.isToday) {
			return "TODAY".localized()
		} else if date!.compare(.isYesterday) {
			return "YESTERDAY".localized()
		} else if date!.compare(.isThisYear) {
			return sectionTitleDateFormatter.string(from: date!).uppercased()
		} else {
			return sectionTitleDateFullFormatter.string(from: date!).uppercased()
		}
	}

	// MARK: -

	func loadData() {

		if isLoading.value || !canLoadMore { return }
		isLoading.value = true

		manager.transactions(addresses: addresses, page: self.page) { [weak self] (transactions, users, error) in
			self?.page += 1
			guard nil == error && nil != transactions && (transactions?.count ?? 0) > 0 else {
				//stop paging
				self?.canLoadMore = false
				self?.isLoading.value = false
				return
			}

			let items = transactions?.map({ (transaction) -> TransactionItem in
				let item = TransactionItem()
				item.transaction = transaction

				let hasAddress = Session.shared.hasAddress(address: transaction.from ?? "")
				var key = transaction.from?.lowercased()
				if hasAddress, let to = transaction.data?.to {
					key = to.lowercased()
				}
				if let key = key, let usr = users?[key] {
					item.user = usr
				}
				return item
			}) ?? []

			self?.transactions.append(contentsOf: items)
			self?.isLoading.value = false
			self?.createSections(with: items)
		}
	}

	func shouldLoadMore(_ indexPath: IndexPath) -> Bool {
		guard canLoadMore && isLoading.value == false else {
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
			for index in 0...endSection {
				itemsCountFromPrevSections += rowsCount(for: index)
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

	// MARK: -

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

	// MARK: -

}
