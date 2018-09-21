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
	
	var addresses: [String] = []
	
	init(addresses: [String]? = nil) {
		super.init()
		
		sectionTitleDateFormatter.dateFormat = "EEEE, dd MMM"
		
		sectionTitleDateFullFormatter.dateFormat = "EEEE, dd MMM YYYY"
		
		if nil == addresses {
			self.addresses = Session.shared.accounts.value.map { (acc) -> String in
				return "Mx" + acc.address
			}
		}
		else {
			self.addresses = addresses ?? []
		}
		
		loadData()
		
		createSections(with: [])
		
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
	
	private var isLoading = Variable(false)
	
	private var canLoadMore = true
	
	var noTransactionsObservable: Observable<Bool> {
		return Observable.combineLatest(self.isLoading.asObservable(), sections.asObservable()).map({ (val) -> Bool in
			return !self.isLoading.value && self.canLoadMore == false && self.transactions.count == 0
		})
	}
	
	
	func createSections(with transactions: [TransactionItem]?) {
		
		var newSections = [BaseTableSectionItem]()
		var items = [String : [BaseCellItem]]()
		
		self.transactions.forEach({ (item) in
			
			guard let transaction = item.transaction else {
				return
			}
			
			let sectionName = sectionTitle(for: transaction.date)
			let sectionCandidate = newSections.index(where: { (item) -> Bool in
				return item.header == sectionName
			})
			
			let txn = item.transaction?.txn
			
			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell", identifier: "SeparatorTableViewCell_" + (nil == txn ? String.random(length: 20) : String(txn!)))
			
			
			var section: BaseTableSectionItem?
			if let idx = sectionCandidate, let sctn = newSections[safe: idx] {
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
//			items[sectionName]?.append(transactionCellItem)
			
			if transaction.type == .send {
				if let transactionCellItem = self.sendTransactionItem(with: item) {
					items[sectionName]?.append(transactionCellItem)
					items[sectionName]?.append(separator)
				}
			}
			else if transaction.type == .buy || transaction.type == .sell {
				if let transactionCellItem = self.convertTransactionItem(with: item) {
					items[sectionName]?.append(transactionCellItem)
					items[sectionName]?.append(separator)
				}
			}
			else if transaction.type == .sellAllCoins {
				if let transactionCellItem = self.convertTransactionItem(with: item) {
					items[sectionName]?.append(transactionCellItem)
					items[sectionName]?.append(separator)
				}
			}
			else if transaction.type == .delegate || transaction.type == .unbond {
				if let transactionCellItem = self.delegateTransactionItem(with: item) {
					items[sectionName]?.append(transactionCellItem)
					items[sectionName]?.append(separator)
				}
			}
		})
		
		var sctns = newSections.map({ (item) -> BaseTableSectionItem in
			return BaseTableSectionItem(header: item.header, items: (items[item.header] ?? []))
		})
		
		let loadingItem = LoadingTableViewCellItem(reuseIdentifier: "LoadingTableViewCell", identifier: "LoadingTableViewCell")
		loadingItem.isLoadingObservable = isLoading.asObservable()
		
		if var lastSection = sctns.last {
			lastSection.items.append(loadingItem)
		}
		else {
			let section = BaseTableSectionItem(header: "", items: [loadingItem])
			sctns.append(section)
		}
		
		self.sections.value = sctns
	}
	
	
	func sendTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
		let user = transactionItem.user
		guard let transaction = transactionItem.transaction else {
			return nil
		}
		
		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))
		
		var signMultiplier = 1.0
		let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
			account.address.stripMinterHexPrefix().lowercased() == transaction.data?.from?.stripMinterHexPrefix().lowercased()
		})
		
		var title = ""
		if hasAddress {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.to ?? "")
			signMultiplier = -1.0
		}
		else {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.from ?? "")
		}
		
		let transactionCellItem = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		transactionCellItem.image = MinterMyAPIURL.avatarAddress(address: ((signMultiplier > 0 ? transaction.data?.from : transaction.data?.to) ?? "")).url()
		transactionCellItem.date = transaction.date
		transactionCellItem.from = transaction.data?.from
		transactionCellItem.to = transaction.data?.to
		if let data = transaction.data as? MinterExplorer.SendCoinTransactionData {
			transactionCellItem.coin = data.coin
			transactionCellItem.amount = (data.amount ?? 0) * Decimal(signMultiplier)
		}
		
		return transactionCellItem
	}
	
	func convertTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
		
		let user = transactionItem.user
		guard let transaction = transactionItem.transaction else {
			return nil
		}
		
		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash ?? String.random(length: 20))
		
		var signMultiplier = 1.0
		let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
			account.address.stripMinterHexPrefix().lowercased() == transaction.data?.from?.stripMinterHexPrefix().lowercased()
		})
		
		var title = ""
		if hasAddress {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.to ?? "")
			signMultiplier = -1.0
		}
		else {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.from ?? "")
		}
		
		
		let transactionCellItem = ConvertTransactionTableViewCellItem(reuseIdentifier: "ConvertTransactionTableViewCell", identifier: "ConvertTransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		transactionCellItem.date = transaction.date
		transactionCellItem.from = transaction.data?.from
		transactionCellItem.to = transaction.data?.to
		
		var arrowSign = " > "
		if #available(iOS 11.0, *) {
			arrowSign = "  ⟶  "
		}
		
		if let data = transaction.data as? MinterExplorer.ConvertTransactionData {
			transactionCellItem.toCoin = data.toCoin
			transactionCellItem.fromCoin = data.fromCoin
			transactionCellItem.amount = (data.valueToBuy ?? 0)
			transactionCellItem.title = (data.fromCoin ?? "") + arrowSign + (data.toCoin ?? "")
		}
		else if let data = transaction.data as? MinterExplorer.SellAllCoinsTransactionData {
			transactionCellItem.toCoin = data.toCoin
			transactionCellItem.fromCoin = data.fromCoin
			transactionCellItem.title = (data.fromCoin ?? "") + arrowSign + (data.toCoin ?? "")
			transactionCellItem.amount = (data.value ?? 0)
		}

		
		return transactionCellItem
		
	}
	
	func delegateTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
		
		guard let transaction = transactionItem.transaction else {
			return nil
		}
		
		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))
		
		let transactionCellItem = DelegateTransactionTableViewCellItem(reuseIdentifier: "DelegateTransactionTableViewCell", identifier: "DelegateTransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.date = transaction.date
		
		let signMultiplier = transaction.type == .unbond ? 1.0 : -1.0
		//TODO: move to common
		if let data = transaction.data as? MinterExplorer.DelegateTransactionData {
			transactionCellItem.coin = data.coin
			transactionCellItem.amount = Decimal(signMultiplier) * (data.stake ?? 0)
			transactionCellItem.title = data.coin ?? ""
			transactionCellItem.to = data.pubKey ?? ""
			transactionCellItem.from = data.from ?? ""
			transactionCellItem.type = transaction.type == .unbond ? "Unbond".localized() : "Delegate".localized()
			transactionCellItem.image = transaction.type == .unbond ? UIImage(named: "unbondImage") : UIImage(named: "delegateImage")
			
		}
		
		return transactionCellItem
		
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
	
	let manager = WalletTransactionManager()
	
	//MARK: -
	
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

				let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
					account.address.stripMinterHexPrefix().lowercased() == transaction.data?.from?.stripMinterHexPrefix().lowercased()
				})

				var key = transaction.data?.from?.lowercased()
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
		else if let item = self.cellItem(section: section, row: row) as? ConvertTransactionTableViewCellItem {
			return URL(string: MinterExplorerBaseURL + "/transactions/" + (item.txHash ?? ""))
		}
		else	if let item = self.cellItem(section: section, row: row) as? DelegateTransactionTableViewCellItem {
			return URL(string: MinterExplorerBaseURL + "/transactions/" + (item.txHash ?? ""))
		}
		return nil
	}
	
}
