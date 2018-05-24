//
//  CoinsCoinsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import SafariServices



class CoinsViewController: BaseTableViewController, ScreenHeaderProtocol, UITableViewDataSource {
	

	//MARK: -
	
	@IBOutlet weak var usernameBarItem: UIBarButtonItem!
	
	@IBOutlet weak var usernameButton: UIButton!
	
	@IBOutlet var headerView: ScreenHeader? {
		didSet {
			headerView?.delegate = self
		}
	}
	
	@IBOutlet override weak var tableView: UITableView! {
		didSet {
			tableView.contentInset = UIEdgeInsetsMake(70, 0, 0, 0)
		}
	}
	
	var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?
	
	@IBOutlet var tableHeaderTopConstraint: NSLayoutConstraint?
	
	var tableHeaderTopPadding: Double {
		return -70
	}
	
	//MARK: -
	
	var viewModel = CoinsViewModel()
	
	private var disposeBag = DisposeBag()

	// MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.usernameButton.titleLabel?.font = UIFont.boldFont(of: 14.0)
		self.usernameButton.setTitleColor(.white, for: .normal)
		
		registerCells()
		
		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
			configureCell: { [weak self] dataSource, tableView, indexPath, sm in

				guard let item = self?.viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
					return UITableViewCell()
				}
				
				cell.configure(item: item)
				
				if let buttonCell = cell as? ButtonTableViewCell {
					buttonCell.delegate = self
				}
				
				if let transactionCell = cell as? TransactionTableViewCell {
					transactionCell.delegate = self
				}
				
				return cell
		})
		
		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .automatic, reloadAnimation: .automatic, deleteAnimation: .automatic)
		
		tableView.rx.setDelegate(self).disposed(by: disposeBag)
		
		viewModel.sectionsObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)
		
		shouldAnimateCellToggle = true
		
		hidesBottomBarWhenPushed = false
		
		if let rightView = self.navigationItem.rightBarButtonItem?.customView {
			Session.shared.isLoggedIn.asObservable().map({ (val) -> Bool in
				return !val
			}).bind(to: rightView.rx.isHidden).disposed(by: disposeBag)
		}

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		updateUsernameButton()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		updateUsernameButton()
	}
	
	//MARK: -
	
	private func updateUsernameButton() {
		//HACK: making the button's image to be at right
		(self.navigationItem.rightBarButtonItem?.customView as? UIButton)?.semanticContentAttribute = .forceRightToLeft
	}
	
	func registerCells() {
		
		tableView.register(UINib(nibName: "DefaultHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "DefaultHeader")
		tableView.register(UINib(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: "TransactionTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "CoinTableViewCell", bundle: nil), forCellReuseIdentifier: "CoinTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
	}
	
	//MARK: -
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return viewModel.sectionsCount()
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
			return UITableViewCell()
		}
		
		cell.configure(item: item)
		
		if let buttonCell = cell as? ButtonTableViewCell {
			buttonCell.delegate = self
		}
		
		return cell
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

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		super.tableView(tableView, didSelectRowAt: indexPath)
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}

		if item.identifier == "ButtonTableViewCell_Transactions" {
			//Move to router?
			performSegue(withIdentifier: "showTransactions", sender: nil)
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		
		if let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) {
			if item.reuseIdentifier == "ButtonTableViewCell" {
				return 70.0
			}
			else if item.reuseIdentifier == "SeparatorTableViewCell" {
				return 1.0
			}
		}
		
		return expandedIndexPaths.contains(indexPath) ? 314 : 54
	}
	
	//MARK: - ScreenHeaderProtocol
	
	func additionalUpdateHeaderViewFromScrollEvent(_ scrollView: UIScrollView) {
		
	}

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		headerView?.updateHeaderViewFromScrollEvent(scrollView)
	}

}

extension CoinsViewController : ButtonTableViewCellDelegate {
	
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		
		guard let indexPath = tableView.indexPath(for: cell), let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else { return }
		
		if item.identifier == "ButtonTableViewCell_Transactions" {
			performSegue(withIdentifier: "showTransactions", sender: nil)
		}
	}
}

extension CoinsViewController : TransactionTableViewCellDelegate {
	
	func didTapExpandedButton(cell: TransactionTableViewCell) {
		if let indexPath = tableView.indexPath(for: cell), let url = viewModel.explorerURL(section: indexPath.section, row: indexPath.row) {
			let vc = SFSafariViewController(url: url)
			
			self.present(vc, animated: true) {
				
			}
		}
	}
	
}

