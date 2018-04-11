//
//  CoinsCoinsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import ExpandableCell

class CoinsViewController: BaseViewController, ScreenHeaderProtocol, ExpandableDelegate, UIScrollViewDelegate {

	//MARK: -
	
	@IBOutlet weak var usernameBarItem: UIBarButtonItem!
	
	@IBOutlet weak var usernameButton: UIButton!
	
	@IBOutlet var headerView: ScreenHeader? {
		didSet {
			headerView?.delegate = self
		}
	}
	
	@IBOutlet weak var tableView: ExpandableTableView! {
		didSet {
			tableView.contentInset = UIEdgeInsetsMake(70, 0, 0, 0)
			tableView.expandableDelegate = self
			tableView.animation = .middle
		}
	}
	
	@IBOutlet var tableHeaderTopConstraint: NSLayoutConstraint?
	
	var tableHeaderTopPadding: Double {
		return 0
	}
	
	//MARK: -
	
	var viewModel = CoinsViewModel()

	// MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.usernameButton.titleLabel?.font = UIFont.boldFont(of: 14.0)
		self.usernameButton.setTitleColor(.white, for: .normal)
	
		tableView.register(UINib(nibName: "DefaultHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "DefaultHeader")
		tableView.register(UINib(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: "TransactionTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "TransactionExpandedTableViewCell", bundle: nil), forCellReuseIdentifier: "TransactionExpandedTableViewCell")
	}
	
	//MARK: -
	
//	func numberOfSections(in tableView: UITableView) -> Int {
//		return viewModel.sectionsCount()
//	}
	
//	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//		return viewModel.rowsCount(for: section)
//	}
	
//	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? BaseCell else {
//			return UITableViewCell()
//		}
//
//		cell.configure(item: item)
//		return cell
//	}
	
	func numberOfSections(in expandableTableView: ExpandableTableView) -> Int {
		return viewModel.sectionsCount()
	}
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		
		guard let section = viewModel.section(index: section) else {
			return UIView()
		}
		
		let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DefaultHeader")
		if let defaultHeader = header as? DefaultHeader {
			defaultHeader.titleLabel.text = section.title
		}
		
		return header
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 52
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}
		
		if item.identifier == "ButtonTableViewCell_Transactions" {
			performSegue(withIdentifier: "showTransactions", sender: nil)
		}
	}
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? BaseCell else {
			return UITableViewCell()
		}
		
		cell.configure(item: item)
		return cell
	}
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
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
//		print("didSelectRow:\(indexPath)")
		//		tableView.open(at: indexPath)
	}
	
	func expandableTableView(_ expandableTableView: ExpandableTableView, didSelectExpandedRowAt indexPath: IndexPath) {
//		print("didSelectExpandedRowAt:\(indexPath)")
	}
	
	//MARK: - ScreenHeaderProtocol
	
//	func scrollViewDidScroll(_ scrollView: UIScrollView) {
//		headerView?.updateHeaderViewFromScrollEvent(scrollView)
//	}
	
	func additionalUpdateHeaderViewFromScrollEvent(_ scrollView: UIScrollView) {
		
	}

}

extension ExpandableTableView : UIScrollViewDelegate {
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		print(scrollView.contentOffset)
	}
}

