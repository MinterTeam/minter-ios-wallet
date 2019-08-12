//
//  DelegatedViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 07/06/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import MinterCore
import MinterExplorer

class DelegatedViewModel: BaseViewModel, ViewModelProtocol {

	// MARK: -

	private var datasource = [String: [[String: Decimal]]]()
	private var source: [String] {
		let src = datasource.keys.sorted(by: { (del1, del2) -> Bool in
			return del1 > del2
		})
		return src
	}

	private var balances = (try? Session.shared.allDelegatedBalance.value()) ?? []

	private let coinFormatter = CurrencyNumberFormatter.coinFormatter

	// MARK: - ViewModelProtocol

	struct Input {
		var viewDidLoad: AnyObserver<Void>
		var willDisplayCell: AnyObserver<WillDisplayCellEvent>
	}

	struct Output {
		var sections: Observable<[BaseTableSectionItem]>
	}

	var input: DelegatedViewModel.Input!

	var output: DelegatedViewModel.Output!

	// MARK: -

	//start with second page because we already have first page results
	private var page = 2
	private var isLoading = false
	private var canLoadMore = true

	private var sections = PublishSubject<[BaseTableSectionItem]>()
	private var viewDidLoad = PublishSubject<Void>()
	private var willDisplayCell = PublishSubject<WillDisplayCellEvent>()

	override init() {
		super.init()

		self.input = Input(viewDidLoad: viewDidLoad.asObserver(),
											 willDisplayCell: willDisplayCell.asObserver())

		self.output = Output(sections: sections.asObservable())

		viewDidLoad.subscribe(onNext: { [weak self] (_) in
			self?.createSections()
			self?.loadDelegatedBalance()
		}).disposed(by: disposeBag)

		Observable.combineLatest(willDisplayCell.asObservable(), sections.asObservable())
			.subscribe(onNext: { [weak self] (val) in
				let indexPath = val.0.indexPath
				if false == self?.isLoading
					&& true == self?.canLoadMore
					&& indexPath.section >= val.1.count - 5 {

					//should reload now?
					self?.loadDelegatedBalance()
				}
		}).disposed(by: disposeBag)
	}

	func createSections() {
		var sections = [BaseTableSectionItem]()
		datasource = [:]

		balances.sorted(by: { (del1, del2) -> Bool in
			return (del1.publicKey ?? "") > (del2.publicKey ?? "")
		}).forEach { (del) in
			let newVal = [del.coin ?? "": del.value ?? 0]
			let publicKey = del.publicKey ?? ""

			if nil != datasource[publicKey] {
				datasource[publicKey]?.append(newVal)
			} else {
				datasource[publicKey] = [newVal]
			}
		}

		source.forEach { (publicKey) in
			var cells = [BaseCellItem]()
			let nodeCell = DelegatedTableViewCellItem(reuseIdentifier: "DelegatedTableViewCell",
																								identifier: "DelegatedTableViewCell_" + publicKey)

			nodeCell.publicKey = publicKey
			cells.append(nodeCell)

			(datasource[publicKey] ?? []).forEach({ (del) in
				del.keys.forEach({ (key) in

					let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
																										 identifier: "SeparatorTableViewCell_" + publicKey + key + String.random())

					cells.append(separator)

					let bal = del[key]
					let cell = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell",
																							 identifier: "TwoTitleTableViewCell_" + publicKey + key)
					cell.title = key
					cell.subtitle = coinFormatter.string(from: (bal ?? 0.0) as NSNumber)
					cells.append(cell)
				})
			})

			let separator1 = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
																									identifier: "SeparatorTableViewCell_1" + String.random())
			cells.append(separator1)
			let section = BaseTableSectionItem(header: nil, items: cells)
			sections.append(section)
		}
		self.sections.onNext(sections)
	}

	func loadDelegatedBalance() {
		let addresses = Session.shared.accounts.value.map({ (account) -> String in
			return "Mx" + account.address.stripMinterHexPrefix()
		})

		guard addresses.count > 0 else {
			return
		}

		ExplorerAddressManager.default
			.delegations(address: addresses.first!, page: page)
			.do(onNext: { [weak self] (val) in
				self?.isLoading = false
			}, onError: { [weak self] (error) in
				self?.isLoading = false
			}, onSubscribe: {

			}, onSubscribed: {
				self.isLoading = true
			}).subscribe(onNext: { [weak self] (delegation, total) in
				self?.page += 1

				if (delegation ?? []).count > 0 {
					self?.balances.append(contentsOf: delegation ?? [])
					self?.createSections()
				}

				if delegation?.count == 0 {
					self?.canLoadMore = false
				}
			}).disposed(by: disposeBag)
	}

	public func publicKey(for section: Int) -> String? {
		var ii = 0
		for i in source.sorted(by: { (del1, del2) -> Bool in
			return del1 > del2
		}) {
			if section == ii {
				return i
			}
			ii += 1
		}
		return nil
	}

}
