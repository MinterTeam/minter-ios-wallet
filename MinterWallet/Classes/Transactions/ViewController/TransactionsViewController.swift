//
//  TransactionsTransactionsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 10/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import SafariServices
import NotificationBannerSwift

class TransactionsViewController: BaseTableViewController {

	// MARK: -

	@IBOutlet var noTransactionsLabel: UILabel!

	// MARK: -

	var viewModel = TransactionsViewModel()

	// MARK: -

	var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

	var disposeBag = DisposeBag()

	// MARK: Life cycle

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		self.hidesBottomBarWhenPushed = true
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = viewModel.title

		self.tableView.tableFooterView = UIView()
		self.tableView.contentInset = UIEdgeInsets(top: -37, left: 0, bottom: 0, right: 0)
		self.automaticallyAdjustsScrollViewInsets = true

		registerViews()

		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
			configureCell: { [weak self] dataSource, tableView, indexPath, sm in

				guard let item = self?.viewModel.cellItem(section: indexPath.section,
																									row: indexPath.row),
					let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
					return UITableViewCell()
				}

				cell.configure(item: item)

				if let transactionCell = cell as? ExpandableCell {
					transactionCell.delegate = self
				}

				return cell
		})

		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .top,
																																	reloadAnimation: .automatic,
																																	deleteAnimation: .top)

		tableView.rx.setDelegate(self).disposed(by: disposeBag)

		viewModel.sectionsObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)

		viewModel.noTransactionsObservable.asObservable().subscribe(onNext: { (val) in
			if val {
				self.tableView.backgroundView = self.noTransactionsLabel
			} else {
				self.tableView.backgroundView = nil
			}
		}).disposed(by: disposeBag)

		if self.shouldShowTestnetToolbar {
			self.view.addSubview(self.testnetToolbarView)
			self.tableView.contentInset = UIEdgeInsets(top: 0,
																								 left: 0,
																								 bottom: 0,
																								 right: 0)
		}

	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		AnalyticsHelper.defaultAnalytics.track(event: .TransactionsScreen)
	}

	func registerViews() {
		tableView.register(UINib(nibName: "DefaultHeader", bundle: nil),
											 forHeaderFooterViewReuseIdentifier: "DefaultHeader")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "TransactionTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "TransactionTableViewCell")
		tableView.register(UINib(nibName: "LoadingTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "LoadingTableViewCell")
		tableView.register(UINib(nibName: "ConvertTransactionTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "ConvertTransactionTableViewCell")
		tableView.register(UINib(nibName: "DelegateTransactionTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "DelegateTransactionTableViewCell")
		tableView.register(UINib(nibName: "MultisendTransactionTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "MultisendTransactionTableViewCell")
		tableView.register(UINib(nibName: "RedeemCheckTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "RedeemCheckTableViewCell")
	}

	// MARK: - Expandable

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

		if (viewModel.cellItem(section: indexPath.section,
													 row: indexPath.row) as? SeparatorTableViewCellItem) != nil {
			return 1
		}

		if let cell = rxDataSource?.tableView(self.tableView, cellForRowAt: indexPath) as? AccordionTableViewCell {
			if nil != cell as? MultisendTransactionTableViewCell {
				return expandedIdentifiers.contains(cell.identifier) ? 315 : 55
			} else if nil != cell as? ConvertTransactionTableViewCell {
				return expandedIdentifiers.contains(cell.identifier) ? 295 : 55
			}
			return expandedIdentifiers.contains(cell.identifier) ? 444 : 55
		}

		if (viewModel.cellItem(section: indexPath.section,
													 row: indexPath.row) as? LoadingTableViewCellItem) != nil {
			return 52
		}

		return 0.1
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		super.tableView(tableView, didSelectRowAt: indexPath)

		guard viewModel.cellItem(section: indexPath.section,
														 row: indexPath.row) != nil else {
			return
		}
	}

	override func tableView(_ tableView: UITableView,
													willDisplay cell: UITableViewCell,
													forRowAt indexPath: IndexPath) {
		super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)

		if viewModel.shouldLoadMore(indexPath) {
			viewModel.loadData()
		}
	}

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

		guard let section = viewModel.section(index: section) else {
			return UIView()
		}

		if section.header == "" {
			return UIView()
		}

		let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DefaultHeader")
		if let defaultHeader = header as? DefaultHeader {
			defaultHeader.titleLabel.text = section.header
		}

		return header
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		guard let section = viewModel.section(index: section) else {
			return 0.1
		}

		if section.header == nil || section.header == "" {
			return 0.1
		}

		return 52.0
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0.1
	}

}

extension TransactionsViewController: ExpandedTransactionTableViewCellDelegate {

	func didTapExplorerButton(cell: ExpandableCell) {
		performLightImpact()

		AnalyticsHelper.defaultAnalytics.track(event: .TransactionExplorerButton)
		if let indexPath = tableView.indexPath(for: cell),
			let url = viewModel.explorerURL(section: indexPath.section,
																			row: indexPath.row) {

			let vc = BaseSafariViewController(url: url)
			self.present(vc, animated: true) {}
		}
	}

	func didTapFromButton(cell: ExpandableCell) {
		SoundHelper.playSoundIfAllowed(type: .click)

		if let indexPath = tableView.indexPath(for: cell),
			let cellItem = viewModel.cellItem(section: indexPath.section,
																				row: indexPath.row) as? TransactionCellItem,
			let from = cellItem.from {

			UIPasteboard.general.string = from

			BannerHelper.performCopiedNotification()
		}
	}

	func didTapToButton(cell: ExpandableCell) {
		SoundHelper.playSoundIfAllowed(type: .click)

		if let indexPath = tableView.indexPath(for: cell),
			let cellItem = viewModel.cellItem(section: indexPath.section,
																				row: indexPath.row) as? TransactionCellItem,
			let to = cellItem.to {
			UIPasteboard.general.string = to

			BannerHelper.performCopiedNotification()
		}
	}

}
