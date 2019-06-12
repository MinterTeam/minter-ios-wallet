//
//  CoinsCoinsViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import RxSwift
import MinterExplorer
import MinterCore
import MinterMy

class CoinsViewModel: BaseViewModel, TransactionViewableViewModel, ViewModelProtocol {

	// MARK: - ViewModelProtocol

	var input: CoinsViewModel.Input!

	var output: CoinsViewModel.Output!

	struct Input {
		var didRefresh: AnyObserver<Void>
	}

	struct Output {
		var totalDelegatedBalance: Observable<String?>
	}

	// MARK: -

	enum cellIdentifierPrefix : String {
	 case transactions = "ButtonTableViewCell_Transactions"
	 case convert = "ButtonTableViewCell_Convert"
	}

	// MARK: -

	var title: String {
		get {
			return "Coins".localized()
		}
	}

	var basicCoinSymbol: String {
		return Coin.baseCoin().symbol ?? "bip"
	}

	private var sections = Variable([BaseTableSectionItem]())

	var sectionsObservable: Observable<[BaseTableSectionItem]> {
		return self.sections.asObservable()
	}

	var totalBalanceObservable: Observable<Decimal> {
		return Session.shared.mainCoinBalance.asObservable()
	}

	var totalDelegatedBalanceSubject = ReplaySubject<String?>.create(bufferSize: 1)
	var didRefreshSubject = PublishSubject<Void>()

	var usernameViewObservable: Observable<User?> {
		return Session.shared.user.asObservable()
	}

	var errorObservable: Observable<Bool> {
		return sections.asObservable().map({ (items) -> Bool in
			return false//!(items.count > 0)
		})
	}

	var rightButtonTitle: String {
		return "@" + (Session.shared.user.value?.username ?? "")
	}

	var rightButtonImage: URL? {
		var url: URL?
		if let id = Session.shared.user.value?.id {
			url = MinterMyAPIURL.avatarUserId(id: id).url()
		}
		if let avatarURLString = Session.shared.user.value?.avatar, let avatarURL = URL(string: avatarURLString) {
			url = avatarURL
		}
		return url
	}

	let formatter = CurrencyNumberFormatter.decimalFormatter
	let coinFormatter = CurrencyNumberFormatter.coinFormatter

	private var coinObservables = [String: PublishSubject<Decimal?>]()

	// MARK: -

	override init() {
		super.init()

		self.input = Input(didRefresh: didRefreshSubject.asObserver())

		self.output = Output(totalDelegatedBalance: totalDelegatedBalanceSubject.asObservable())

		Observable.combineLatest(Session.shared.transactions.asObservable(),
														 Session.shared.balances.asObservable(),
														 Session.shared.allBalances.asObservable(),
														 Session.shared.isLoggedIn.asObservable().distinctUntilChanged())
		.subscribe(onNext: { [weak self] (transactions) in
			self?.createSection()

			let bal = Session.shared.balances.value
			bal.keys.sorted(by: { (key1, key2) -> Bool in
				return key1 < key2
			}).forEach { (key) in
				if self?.coinObservables[key] == nil {
					self?.coinObservables[key] = PublishSubject<Decimal?>()
				}
				self?.coinObservables[key]?.onNext(bal[key] ?? 0.0)
			}

		}).disposed(by: disposeBag)

		Session.shared.delegatedBalance.subscribe(onNext: { [weak self] (val) in
			if val > 0 {
				let str = self?.coinFormatter.string(from: val as NSNumber) ?? ""
				self?.totalDelegatedBalanceSubject.onNext(str + " " + (Coin.baseCoin().symbol ?? ""))
			} else {
				self?.totalDelegatedBalanceSubject.onNext(nil)
			}
		}).disposed(by: disposeBag)

		didRefreshSubject.subscribe(onNext: { (_) in
			Session.shared.loadBalances()
			Session.shared.loadTransactions()
			Session.shared.loadDelegatedBalance()
		}).disposed(by: disposeBag)
	}

	func createSection() {
		var sctns = [BaseTableSectionItem]()

		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																			 identifier: "BlankTableViewCell_1")
		let blank1 = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																			 identifier: "BlankTableViewCell_2")

		var section = BaseTableSectionItem(header: "Latest Transactions".localized())
		section.identifier = "BaseTableSectionItem_1"
		section.items.append(blank)

		let trans = Array(Session.shared.transactions.value[safe: 0..<5] ?? [])
		if trans.count == 0 {
			section.items = []
		}

		trans.forEach { (transactionItem) in

			guard let transaction = transactionItem.transaction else {
				return
			}

			let sectionId = nil != transaction.txn ? String(transaction.txn!) : (transaction.hash ?? String.random(length: 20))

			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
																								 identifier: "SeparatorTableViewCell_" + sectionId)

			if transaction.type == .send {
				if let transactionCellItem = self.sendTransactionItem(with: transactionItem) {
					section.items.append(transactionCellItem)
					section.items.append(separator)
				}
			} else if transaction.type == .multisend {
				if let transactionCellItem = self.multisendTransactionItem(with: transactionItem) {
					section.items.append(transactionCellItem)
					section.items.append(separator)
				}
			} else if transaction.type == .buy || transaction.type == .sell {
				if let transactionCellItem = self.convertTransactionItem(with: transactionItem) {
					section.items.append(transactionCellItem)
					section.items.append(separator)
				}
			} else if transaction.type == .sellAll {
				if let transactionCellItem = self.convertTransactionItem(with: transactionItem) {
					section.items.append(transactionCellItem)
					section.items.append(separator)
				}
			} else if transaction.type == .delegate || transaction.type == .unbond {
				if let transactionCellItem = self.delegateTransactionItem(with: transactionItem) {
					section.items.append(transactionCellItem)
					section.items.append(separator)
				}
			} else if transaction.type == .redeemCheck {
				if let transactionCellItem = self.redeemCheckTransactionItem(with: transactionItem) {
					section.items.append(transactionCellItem)
					section.items.append(separator)
				}
			}
		}

		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																				 identifier: "ButtonTableViewCell_Transactions")
		button.buttonPattern = "blank"
		button.title = "ALL TRANSACTIONS".localized()

		section.items.append(button)

		var section1 = BaseTableSectionItem(header: "My Coins".localized())
		section1.identifier = "BaseTableSectionItem_2"

		Session.shared.balances.value.keys.sorted(by: { (key1, key2) -> Bool in
			return key1 < key2
		}).forEach { (key) in

			let bal = Session.shared.balances.value
			let balanceKey = CurrencyNumberFormatter.decimalShortFormatter.string(from: (bal[key] ?? 0) as NSNumber)
//			let cellAdditionalId = "\(key)_\(balanceKey ?? "")"

			let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
																								 identifier: "SeparatorTableViewCell_\(key)")

			let coin = CoinTableViewCellItem(reuseIdentifier: "CoinTableViewCell",
																			 identifier: "CoinTableViewCell_\(key)")
			coin.title = key
			coin.image = UIImage(named: "AvatarPlaceholderImage")
			coin.imageURL = MinterMyAPIURL.avatarByCoin(coin: key).url()
			coin.coin = key
			coin.amount = bal[key]
			coin.amountObservable = coinObservables[key]?.asObservable()

			section1.items.append(coin)
			section1.items.append(separator)
		}

		let convertButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																								identifier: "ButtonTableViewCell_Convert")
		convertButton.buttonPattern = "blank"
		convertButton.title = "CONVERT".localized()

		section1.items.append(convertButton)

		if section.items.count > 1 {
			sctns.append(section)
		}

		if section1.items.count > 1 {
			section1.items.insert(blank1, at: 0)
			sctns.append(section1)
		}

		if sctns.count == 0 && (Session.shared.isLoadingTransaction || Session.shared.isLoading.value) {
			let loadingItem = LoadingTableViewCellItem(reuseIdentifier: "LoadingTableViewCell",
																								 identifier: "LoadingTableViewCell")
			loadingItem.isLoadingObservable = Session.shared.isLoading.asObservable()
			let sctn = BaseTableSectionItem(header: "", items: [loadingItem])
			sctns.append(sctn)
		}
		self.sections.value = sctns
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

	func headerViewTitleText(with balance: Decimal) -> NSAttributedString {
		let formatter = coinFormatter
		let balanceString = Array((formatter.string(from: balance as NSNumber) ?? "").split(separator: "."))

		let string = NSMutableAttributedString()
		string.append(NSAttributedString(string: String(balanceString[0]),
																		 attributes: [.foregroundColor: UIColor.white,
																									.font: UIFont.boldFont(of: 32.0)]))
		string.append(NSAttributedString(string: ".",
																		 attributes: [.foregroundColor: UIColor.white,
																									.font: UIFont.boldFont(of: 18.0)]))

		string.append(NSAttributedString(string: String(balanceString[1]),
																		 attributes: [.foregroundColor: UIColor.white,
																									.font: UIFont.boldFont(of: 20.0)]))
		string.append(NSAttributedString(string: " " + self.basicCoinSymbol,
																		 attributes: [.foregroundColor: UIColor.white,
																									.font: UIFont.boldFont(of: 18.0)]))
		return string
	}

}
