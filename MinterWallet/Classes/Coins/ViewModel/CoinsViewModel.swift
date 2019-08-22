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

	typealias BalanceHeaderItem = (title: String?, text: NSAttributedString?, animated: Bool)

	// MARK: - ViewModelProtocol

	var input: CoinsViewModel.Input!
	var output: CoinsViewModel.Output!

	struct Input {
		var didRefresh: AnyObserver<Void>
		var didTapBalance: AnyObserver<Void>
	}

	struct Output {
		var totalDelegatedBalance: Observable<String?>
		var balanceInUSD: Observable<String?>
		var balanceText: Observable<BalanceHeaderItem>
	}

	// MARK: - I/O Subjects

	private var totalDelegatedBalanceSubject = ReplaySubject<String?>.create(bufferSize: 1)
	private var balanceInUSDSubject = ReplaySubject<String?>.create(bufferSize: 1)
	private var balanceTextSubject = ReplaySubject<BalanceHeaderItem>.create(bufferSize: 1)

	private var didRefreshSubject = PublishSubject<Void>()
	private var didTapBalanceSubject = PublishSubject<Void>()

	// MARK: -

	enum cellIdentifierPrefix: String {
	 case transactions = "ButtonTableViewCell_Transactions"
	 case convert = "ButtonTableViewCell_Convert"
	}

	// MARK: -

	enum BalanceType: String {
		case balanceBIP
		case totalBalanceBIP
		case totalBalanceUSD
	}

	var changedBalanceTypeSubject =
		BehaviorSubject<BalanceType>(value: BalanceType(rawValue: AppSettingsManager.shared.balanceType ?? "") ?? .balanceBIP)

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
		if let avatarURLString = Session.shared.user.value?.avatar,
			let avatarURL = URL(string: avatarURLString) {
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

		self.input = Input(didRefresh: didRefreshSubject.asObserver(),
											 didTapBalance: didTapBalanceSubject.asObserver())

		self.output = Output(totalDelegatedBalance: totalDelegatedBalanceSubject.asObservable(),
												 balanceInUSD: balanceInUSDSubject.asObservable(),
												 balanceText: balanceTextSubject.asObservable())

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

		didTapBalanceSubject.skip(1)
			.withLatestFrom(Observable.combineLatest(totalBalanceObservable,
																							 Session.shared.USDRate.asObservable(),
																							 changedBalanceTypeSubject.asObservable()))
			.subscribe(onNext: { [weak self] (val) in

				let (balance, usdRate, balanceType) = val
				var newBalanceType: BalanceType

				switch balanceType {
				case .totalBalanceUSD:
					newBalanceType = .totalBalanceBIP
					break
				case .balanceBIP:
					newBalanceType = .totalBalanceUSD
					break
				case .totalBalanceBIP:
					newBalanceType = .balanceBIP
					break
				}

				self?.changedBalanceTypeSubject.onNext(newBalanceType)

				AppSettingsManager.shared.balanceType = newBalanceType.rawValue
				AppSettingsManager.shared.save()

				if let headerItem = self?.balanceHeaderItem(balanceType: balanceType,
																					 balance: balance,
																					 usdRate: usdRate) {
					self?.balanceTextSubject.onNext(headerItem)
				}
		}).disposed(by: disposeBag)

		Observable.combineLatest(totalBalanceObservable,
														 Session.shared.USDRate.asObservable())
			.subscribe(onNext: { [weak self] (val) in
				let (balance, usdRate) = val
				var balanceType = BalanceType(rawValue: AppSettingsManager.shared.balanceType ?? "") ?? .balanceBIP
				if let headerItem = self?.balanceHeaderItem(balanceType: balanceType,
																										balance: balance,
																										usdRate: usdRate) {
					self?.balanceTextSubject.onNext(headerItem)
				}
		}).disposed(by: disposeBag)
	}

	private func balanceHeaderItem(balanceType: BalanceType,
																 balance: Decimal,
																 usdRate: Decimal) -> BalanceHeaderItem {

		var text: NSAttributedString?
		var title: String?

		switch balanceType {
		case .balanceBIP:
			title = "Total Balance".localized()
			text = headerViewTitleText(with: balance, isUSD: false)
			break

		case .totalBalanceBIP:
			title = "Total Balance".localized()
			text = headerViewTitleText(with: balance * usdRate, isUSD: true)
			break

		case .totalBalanceUSD:
			title = "Available Balance".localized()
			text = headerViewTitleText(with: balance, isUSD: false)
			break
		}
		return BalanceHeaderItem(title: title, text: text, animated: false)
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

	func headerViewTitleText(with balance: Decimal, isUSD: Bool = false) -> NSAttributedString {
		let formatter = isUSD ? CurrencyNumberFormatter.USDFormatter : coinFormatter
		let balanceString = Array((formatter.string(from: balance as NSNumber) ?? "").split(separator: "."))

		let string = NSMutableAttributedString()
		if isUSD {
			string.append(NSAttributedString(string: "$",
																			 attributes: [.foregroundColor: UIColor.white,
																										.font: UIFont.boldFont(of: 32.0)]))
		}
		string.append(NSAttributedString(string: String(balanceString[0]),
																		 attributes: [.foregroundColor: UIColor.white,
																									.font: UIFont.boldFont(of: 32.0)]))
		string.append(NSAttributedString(string: ".",
																		 attributes: [.foregroundColor: UIColor.white,
																									.font: UIFont.boldFont(of: 18.0)]))

		string.append(NSAttributedString(string: String(balanceString[1]),
																		 attributes: [.foregroundColor: UIColor.white,
																									.font: UIFont.boldFont(of: 20.0)]))
		if !isUSD {
			string.append(NSAttributedString(string: " " + self.basicCoinSymbol,
																			 attributes: [.foregroundColor: UIColor.white,
																										.font: UIFont.boldFont(of: 18.0)]))
		}
		return string
	}

}
