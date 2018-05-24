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



class TransactionsViewController: BaseTableViewController, UITableViewDataSource {
	
	//MARK: -
	
	var viewModel = TransactionsViewModel()
	
	//MARK: -
	
	var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

	// MARK: Life cycle
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.hidesBottomBarWhenPushed = true
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = viewModel.title
		
		self.tableView.tableFooterView = UIView()
		
		registerViews()
		
		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
			configureCell: { [weak self] dataSource, tableView, indexPath, sm in
				
				guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
					return UITableViewCell()
				}
				
				cell.configure(item: item)
				
				return cell
		})
		
		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .automatic, reloadAnimation: .automatic, deleteAnimation: .automatic)
		
		tableView.rx.setDelegate(self).disposed(by: disposeBag)
		
		viewModel.sectionsObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)
		
		
	}
	
	func registerViews() {
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: "TransactionTableViewCell")
	}
	
	//MARK: - Expandable
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
			return UITableViewCell()
		}
		
		cell.configure(item: item)
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		
		if (viewModel.cellItem(section: indexPath.section, row: indexPath.row) as? SeparatorTableViewCellItem) != nil {
			return 1
		}
		
		return expandedIndexPaths.contains(indexPath) ? 314 : 54
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		super.tableView(tableView, didSelectRowAt: indexPath)
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}
	}
	

}
