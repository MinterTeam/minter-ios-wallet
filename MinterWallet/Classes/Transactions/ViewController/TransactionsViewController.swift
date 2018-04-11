//
//  TransactionsTransactionsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 10/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import ExpandableCell



class TransactionsViewController: UIViewController, ExpandableDelegate {
	
	//MARK: -
	
	@IBOutlet weak var tableView: ExpandableTableView! {
		didSet {
			tableView.expandableDelegate = self
			tableView.animation = .middle
		}
	}
	
	//MARK: -
	
	var viewModel = TransactionsViewModel()

	// MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = viewModel.title
		
		registerViews()
	}
	
	func registerViews() {
		tableView.register(UINib(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: "TransactionTableViewCell")
		tableView.register(UINib(nibName: "TransactionExpandedTableViewCell", bundle: nil), forCellReuseIdentifier: "TransactionExpandedTableViewCell")
	}
	
	//MARK: -
	
//	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//		return viewModel.rowsCount(for: section)
//	}
//
//	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionTableViewCell") as? BaseCell else {
//			return UITableViewCell()
//		}
//
//		cell.configure(item: item)
//		return cell
//	}
//
//	func numberOfSections(in tableView: UITableView) -> Int {
//		return viewModel.sectionsCount()
//	}
	
	//MARK: - Expandable
	
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionTableViewCell") as? BaseCell else {
			return UITableViewCell()
		}
		
		cell.configure(item: item)
		return cell
	}
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 54
	}
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, expandedCellsForRowAt indexPath: IndexPath) -> [UITableViewCell]? {
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionExpandedTableViewCell") as? BaseCell else {
			return []
		}
		
		cell.configure(item: item)
		
		return [cell]
	}
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, heightsForExpandedRowAt indexPath: IndexPath) -> [CGFloat]? {
		return [260]
	}
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, didSelectRowAt indexPath: IndexPath) {
		print("didSelectRow:\(indexPath)")
//		tableView.open(at: indexPath)
	}
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, didSelectExpandedRowAt indexPath: IndexPath) {
		print("didSelectExpandedRowAt:\(indexPath)")
	}
	

}
