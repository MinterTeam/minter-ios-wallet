//
//  BaseViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer
import MinterMy
import RxSwift

protocol ViewModelProtocol {
	associatedtype Input
	associatedtype Output

	var input: Input! { get }
	var output: Output! { get }
}

class BaseViewModel {
	var disposeBag = DisposeBag()
}

protocol TransactionViewableViewModel: class {
	func section(index: Int) -> BaseTableSectionItem?
	func sectionsCount() -> Int
	func rowsCount(for section: Int) -> Int
	func cellItem(section: Int, row: Int) -> BaseCellItem?
}

extension TransactionViewableViewModel {

	func sendTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
		let user = transactionItem.user
		guard let transaction = transactionItem.transaction else {
			return nil
		}

		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))
		
		var signMultiplier = 1.0
		let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
			account.address.stripMinterHexPrefix().lowercased() == transaction.from?.stripMinterHexPrefix().lowercased()
		})

		var title = ""
		if hasAddress {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.to ?? "")
			signMultiplier = -1.0
		} else {
			title = user?.username != nil ? "@" + user!.username! : (transaction.from ?? "")
		}

		let transactionCellItem = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		transactionCellItem.image = MinterMyAPIURL.avatarAddress(address: ((signMultiplier > 0 ? transaction.from : transaction.data?.to) ?? "")).url()
		transactionCellItem.date = transaction.date
		transactionCellItem.from = transaction.from
		transactionCellItem.to = transaction.data?.to
		if let data = transaction.data as? MinterExplorer.SendCoinTransactionData {
			transactionCellItem.coin = data.coin
			transactionCellItem.amount = (data.amount ?? 0) * Decimal(signMultiplier)
		}
		return transactionCellItem
	}

	func multisendTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
		let user = transactionItem.user
		guard let transaction = transactionItem.transaction else {
			return nil
		}
		
		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))
		
		var signMultiplier = 1.0
		let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
			account.address.stripMinterHexPrefix().lowercased() == transaction.from?.stripMinterHexPrefix().lowercased()
		})

		var title = ""
		if hasAddress {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.to ?? "")
			signMultiplier = -1.0
		} else {
			title = user?.username != nil ? "@" + user!.username! : (transaction.from ?? "")
		}

		let transactionCellItem = MultisendTransactionTableViewCellItem(reuseIdentifier: "MultisendTransactionTableViewCell", identifier: "MultisendTransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		transactionCellItem.image = MinterMyAPIURL.avatarAddress(address: ((signMultiplier > 0 ? transaction.from : transaction.data?.to) ?? "")).url()
		transactionCellItem.date = transaction.date
		transactionCellItem.from = transaction.from
		transactionCellItem.to = transaction.data?.to

		if let data = transactionItem.transaction?.data as? MultisendCoinTransactionData {
			if let val = data.values?.filter({ (val) -> Bool in
				let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
					account.address.stripMinterHexPrefix().lowercased() == val.to.stripMinterHexPrefix().lowercased()
				})
				return hasAddress
			}), val.count == 1 {
				if let payload = val.first {
					transactionCellItem.to = payload.to
					transactionCellItem.amount = payload.value
					transactionCellItem.coin = payload.coin
					if hasAddress {
						transactionCellItem.image = MinterMyAPIURL.avatarAddress(address: payload.to).url()
					} else {
						if let from = transaction.from {
							transactionCellItem.image = MinterMyAPIURL.avatarAddress(address: from).url()
						}
					}
				}
			}

			if (transactionCellItem.title?.count ?? 0) == 0 {
				transactionCellItem.title = transactionItem.transaction?.from
				if let from = transactionItem.transaction?.from {
					transactionCellItem.image = MinterMyAPIURL.avatarAddress(address: from).url()
				}
			}
		}
		return transactionCellItem
	}

	func convertTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {

		let user = transactionItem.user
		guard let transaction = transactionItem.transaction else {
			return nil
		}

		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash ?? String.random(length: 20))
		let hasAddress = Session.shared.accounts.value.contains(where: { (account) -> Bool in
			account.address.stripMinterHexPrefix().lowercased() == transaction.from?.stripMinterHexPrefix().lowercased()
		})

		var title = ""
		if hasAddress {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.to ?? "")
		} else {
			title = user?.username != nil ? "@" + user!.username! : (transaction.from ?? "")
		}

		let transactionCellItem = ConvertTransactionTableViewCellItem(reuseIdentifier: "ConvertTransactionTableViewCell", identifier: "ConvertTransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		transactionCellItem.date = transaction.date
		transactionCellItem.from = transaction.from
		transactionCellItem.to = transaction.from

		var arrowSign = " > "
		if #available(iOS 11.0, *) {
			arrowSign = "  ⟶  "
		}

		if let data = transaction.data as? MinterExplorer.ConvertTransactionData {
			transactionCellItem.toCoin = data.toCoin
			transactionCellItem.fromCoin = data.fromCoin
			transactionCellItem.amount = (data.valueToBuy ?? 0)
			transactionCellItem.title = (data.fromCoin ?? "") + arrowSign + (data.toCoin ?? "")
		} else if let data = transaction.data as? MinterExplorer.SellAllCoinsTransactionData {
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
		if let data = transaction.data as? DelegatableUnbondableTransactionData {
			transactionCellItem.coin = data.coin
			transactionCellItem.amount = Decimal(signMultiplier) * (data.value ?? 0)
			transactionCellItem.title = data.coin ?? ""
			transactionCellItem.to = data.pubKey ?? ""
			transactionCellItem.from = transaction.from ?? ""
			transactionCellItem.type = transaction.type == .unbond ? "Unbond".localized() : "Delegate".localized()
			transactionCellItem.image = transaction.type == .unbond ? UIImage(named: "unbondImage") : UIImage(named: "delegateImage")
		}
		return transactionCellItem
	}

	func redeemCheckTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
		let user = transactionItem.user
		guard let transaction = transactionItem.transaction else {
			return nil
		}

		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))

		let signMultiplier = 1.0
		let toAddress = "Mx" + (Session.shared.accounts.value.first?.address ?? "").stripMinterHexPrefix()
		let title = user?.username != nil ? "@" + user!.username! : toAddress

		let transactionCellItem = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell", identifier: "TransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		transactionCellItem.image = MinterMyAPIURL.avatarAddress(address: ((signMultiplier > 0 ? transaction.from : transaction.data?.to) ?? "")).url()
		transactionCellItem.date = transaction.date
		transactionCellItem.to = toAddress
		if let data = transaction.data as? MinterExplorer.RedeemCheckRawTransactionData {
			transactionCellItem.coin = data.coin
			transactionCellItem.amount = (data.value ?? 0) * Decimal(signMultiplier)
			transactionCellItem.from = data.sender
		}
		return transactionCellItem
	}

	func explorerURL(section: Int, row: Int) -> URL? {
		if let item = self.cellItem(section: section, row: row) as? TransactionTableViewCellItem {
			return URL(string: MinterExplorerBaseURL! + "/transactions/" + (item.txHash ?? ""))
		} else if let item = self.cellItem(section: section, row: row) as? ConvertTransactionTableViewCellItem {
			return URL(string: MinterExplorerBaseURL! + "/transactions/" + (item.txHash ?? ""))
		} else if let item = self.cellItem(section: section, row: row) as? DelegateTransactionTableViewCellItem {
			return URL(string: MinterExplorerBaseURL! + "/transactions/" + (item.txHash ?? ""))
		} else if let item = self.cellItem(section: section, row: row) as? MultisendTransactionTableViewCellItem {
			return URL(string: MinterExplorerBaseURL! + "/transactions/" + (item.txHash ?? ""))
		}
		return nil
	}

}
