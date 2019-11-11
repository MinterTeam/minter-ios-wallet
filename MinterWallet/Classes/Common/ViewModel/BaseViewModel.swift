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
	associatedtype Dependency

	var input: Input! { get }
	var output: Output! { get }
//	var dependency: Dependency! { get }
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

		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash ?? String.random(length: 20))

		var signMultiplier = 1.0
		let hasAddress = Session.shared.hasAddress(address: transaction.from ?? "")

		var title = ""
		if hasAddress {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.to ?? "")
			signMultiplier = -1.0
		} else {
			title = user?.username != nil ? "@" + user!.username! : (transaction.from ?? "")
		}

		let transactionCellItem = TransactionTableViewCellItem(reuseIdentifier: "TransactionTableViewCell",
																													 identifier: "TransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		let avatarAddress = ((signMultiplier > 0 ? transaction.from : transaction.data?.to) ?? "")
		transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: avatarAddress).url()
		transactionCellItem.date = transaction.date
		transactionCellItem.from = transaction.from
		transactionCellItem.to = transaction.data?.to
		if let data = transaction.data as? MinterExplorer.SendCoinTransactionData {
			transactionCellItem.coin = data.coin
			transactionCellItem.amount = (data.amount ?? 0) * Decimal(signMultiplier)
		}
		transactionCellItem.payload = transaction.payload?.base64Decoded()
		return transactionCellItem
	}

	func multisendTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {
		let user = transactionItem.user
		guard let transaction = transactionItem.transaction else {
			return nil
		}

		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))
		
		var signMultiplier = 1.0
		let hasAddress = Session.shared.hasAddress(address: transaction.from ?? "")

		var title = ""
		if hasAddress {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.to ?? "")
			signMultiplier = -1.0
		} else {
			title = user?.username != nil ? "@" + user!.username! : (transaction.from ?? "")
		}

		let transactionCellItem = MultisendTransactionTableViewCellItem(reuseIdentifier: "MultisendTransactionTableViewCell",
																																		identifier: "MultisendTransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		let address = ((signMultiplier > 0 ? transaction.from : transaction.data?.to) ?? "")
		transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: address).url()
		transactionCellItem.date = transaction.date
		transactionCellItem.from = transaction.from
		transactionCellItem.to = transaction.data?.to
		transactionCellItem.payload = transaction.payload?.base64Decoded()

		if let data = transactionItem.transaction?.data as? MultisendCoinTransactionData {
			if let val = data.values?.filter({ (val) -> Bool in
				return Session.shared.hasAddress(address: val.to)
			}), val.count == 1 {
				if let payload = val.first {
					transactionCellItem.to = payload.to
					transactionCellItem.amount = payload.value
					transactionCellItem.coin = payload.coin
					if hasAddress {
						transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: payload.to).url()
					} else {
						if let from = transaction.from {
							transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: from).url()
						}
					}
				}
			}

			if (transactionCellItem.title?.count ?? 0) == 0 {
				transactionCellItem.title = transactionItem.transaction?.from
				if let from = transactionItem.transaction?.from {
					transactionCellItem.imageURL = MinterMyAPIURL.avatarAddress(address: from).url()
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
		let hasAddress = Session.shared.hasAddress(address: transaction.from ?? "")

		var title = ""
		if hasAddress {
			title = user?.username != nil ? "@" + user!.username! : (transaction.data?.to ?? "")
		} else {
			title = user?.username != nil ? "@" + user!.username! : (transaction.from ?? "")
		}

		let transactionCellItem = ConvertTransactionTableViewCellItem(reuseIdentifier: "ConvertTransactionTableViewCell",
																																	identifier: "ConvertTransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = title
		transactionCellItem.date = transaction.date
		transactionCellItem.from = transaction.from
		transactionCellItem.to = transaction.from
		transactionCellItem.payload = transaction.payload?.base64Decoded()

		var arrowSign = " > "
		if #available(iOS 11.0, *) {
			arrowSign = "  ⟶  "
		}

		if let data = transaction.data as? MinterExplorer.ConvertTransactionData {
			transactionCellItem.toCoin = data.toCoin
			transactionCellItem.fromCoin = data.fromCoin
			transactionCellItem.toAmount = (data.valueToBuy ?? 0)
			transactionCellItem.fromAmount = (data.valueToSell ?? 0)
			transactionCellItem.title = (data.fromCoin ?? "") + arrowSign + (data.toCoin ?? "")
		} else if let data = transaction.data as? MinterExplorer.SellAllCoinsTransactionData {
			transactionCellItem.toCoin = data.toCoin
			transactionCellItem.fromCoin = data.fromCoin
			transactionCellItem.title = (data.fromCoin ?? "") + arrowSign + (data.toCoin ?? "")
			transactionCellItem.toAmount = (data.valueToBuy ?? 0)
			transactionCellItem.fromAmount = (data.valueToSell ?? 0)
			
		}
		return transactionCellItem
	}

	func delegateTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {

		guard let transaction = transactionItem.transaction else {
			return nil
		}

		let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash  ?? String.random(length: 20))

		let transactionCellItem = DelegateTransactionTableViewCellItem(reuseIdentifier: "DelegateTransactionTableViewCell",
																																	 identifier: "DelegateTransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.date = transaction.date
		transactionCellItem.payload = transaction.payload?.base64Decoded()

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

		var signMultiplier = 1.0
		let toAddress = "Mx" + (Session.shared.accounts.value.first?.address ?? "").stripMinterHexPrefix()
		let title = user?.username != nil ? "@" + user!.username! : toAddress

		let transactionCellItem = RedeemCheckTableViewCellItem(reuseIdentifier: "RedeemCheckTableViewCell",
																													 identifier: "RedeemCheckTableViewCell\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.title = (transactionItem.transaction?.hash ?? title)
		transactionCellItem.image = UIImage(named: "redeemCheckImage")
		transactionCellItem.date = transaction.date
		transactionCellItem.to = toAddress
		transactionCellItem.payload = transaction.payload?.base64Decoded()

		if let data = transaction.data as? MinterExplorer.RedeemCheckRawTransactionData {
			let hasAddress = Session.shared.hasAddress(address: transaction.from ?? "")
			if !hasAddress {
				signMultiplier = -1.0
			}
			transactionCellItem.coin = data.coin
			transactionCellItem.amount = (data.value ?? 0) * Decimal(signMultiplier)
			transactionCellItem.from = data.sender
			transactionCellItem.to = transaction.from
		}
		return transactionCellItem
	}

	func systemTransactionItem(with transactionItem: TransactionItem) -> BaseCellItem? {

		let dateFormatter = TransactionDateFormatter.transactionDateFormatter
		let timeFormatter = TransactionDateFormatter.transactionTimeFormatter

		guard let transaction = transactionItem.transaction else {
			return nil
		}

		let sectionId = transaction.hash ?? String.random()

		let transactionCellItem = SystemTransactionTableViewCellItem(reuseIdentifier: "SystemTransactionTableViewCell",
																																 identifier: "SystemTransactionTableViewCell_\(sectionId)")
		transactionCellItem.txHash = transaction.hash
		transactionCellItem.date = dateFormatter.string(from: transaction.date ?? Date())
		transactionCellItem.time = timeFormatter.string(from: transaction.date ?? Date())
//		transactionCellItem.payload = transaction.payload?.base64Decoded()
//		let signMultiplier = transaction.type == .unbond ? 1.0 : -1.0
//		if let data = transaction.data as? SystemTransactionTable {
////			transactionCellItem.coin = data.coin
////			transactionCellItem.amount = Decimal(signMultiplier) * (data.value ?? 0)
////			transactionCellItem.title = data.coin ?? ""
////			transactionCellItem.to = data.pubKey ?? ""
////			transactionCellItem.from = transaction.from ?? ""
//
//		}
		guard let txType = transaction.type else { return nil }

		switch txType {
		case .create:
			transactionCellItem.title = "Create Coin"
			break
		case .createMultisig:
			transactionCellItem.title = "Create Multisig"
			break
		case .declare:
			transactionCellItem.title = "Declare Candidate"
			break
		case .editCandidate:
			transactionCellItem.title = "Edit Candidate"
			break
		case .setCandidateOffline:
			transactionCellItem.title = "Set Candidate Offline"
			break
		case .setCandidateOnline:
			transactionCellItem.title = "Set Candidate Online"
			break
		default:
			break
		}
		transactionCellItem.type = ""
		transactionCellItem.image = UIImage(named: "systemTransactionImage")
		return transactionCellItem
	}

	func explorerURL(section: Int, row: Int) -> URL? {
		if let item = self.cellItem(section: section, row: row) as? TransactionCellItem {
			return URL(string: MinterExplorerBaseURL! + "/transactions/" + (item.txHash ?? ""))
		}
		return nil
	}

}
