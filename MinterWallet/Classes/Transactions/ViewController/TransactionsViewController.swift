//
//  TransactionsTransactionsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 10/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import ExpandableCell
import RxDataSources
import RxSwift
import SafariServices


class TransactionsViewController: BaseTableViewController {
	
	//MARK: -
	
	var viewModel = TransactionsViewModel()
	
	//MARK: -
	
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
		
		registerViews()
		
		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
			configureCell: { [weak self] dataSource, tableView, indexPath, sm in
				
				guard let item = self?.viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
					return UITableViewCell()
				}
				
				cell.configure(item: item)
				
				if let transactionCell = cell as? TransactionTableViewCell {
					transactionCell.delegate = self
				}
				
				return cell
		})
		
		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .top, reloadAnimation: .automatic, deleteAnimation: .top)
		
		tableView.rx.setDelegate(self).disposed(by: disposeBag)
		
		viewModel.sectionsObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)
	}
	
	func registerViews() {
		tableView.register(UINib(nibName: "DefaultHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "DefaultHeader")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: "TransactionTableViewCell")
		tableView.register(UINib(nibName: "LoadingTableViewCell", bundle: nil), forCellReuseIdentifier: "LoadingTableViewCell")
		tableView.register(UINib(nibName: "ConvertTransactionTableViewCell", bundle: nil), forCellReuseIdentifier: "ConvertTransactionTableViewCell")
	}
	
	//MARK: - Expandable
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		
		if (viewModel.cellItem(section: indexPath.section, row: indexPath.row) as? SeparatorTableViewCellItem) != nil {
			return 1
		}
		
		return expandedIndexPaths.contains(indexPath) ? 378 : 54
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		super.tableView(tableView, didSelectRowAt: indexPath)
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		super.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
		
		if viewModel.shouldLoadMore(indexPath) {
			viewModel.loadData()
		}
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

		guard let section = viewModel.section(index: section) else {
			return UIView()
		}
		
		let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DefaultHeader")
		if let defaultHeader = header as? DefaultHeader {
			defaultHeader.titleLabel.text = section.header
		}
		
		return header
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 52
	}

}

extension TransactionsViewController : TransactionTableViewCellDelegate, ConvertTransactionTableViewCellDelegate {
	
	func didTapExpandedButton(cell: TransactionTableViewCell) {
		if let indexPath = tableView.indexPath(for: cell), let url = viewModel.explorerURL(section: indexPath.section, row: indexPath.row) {
			let vc = SFSafariViewController(url: url)
			self.present(vc, animated: true) {}
		}
	}
	
	func didTapExpandedButton(cell: ConvertTransactionTableViewCell) {
		if let indexPath = tableView.indexPath(for: cell), let url = viewModel.explorerURL(section: indexPath.section, row: indexPath.row) {
			let vc = SFSafariViewController(url: url)
			self.present(vc, animated: true) {}
		}
	}
	
}
