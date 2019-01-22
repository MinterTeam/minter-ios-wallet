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
import AlamofireImage



class CoinsViewController: BaseTableViewController, ScreenHeaderProtocol {
	
	//MARK: -
	
	lazy var refreshControl: UIRefreshControl = {
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action:
			#selector(CoinsViewController.handleRefresh(_:)),
														 for: UIControlEvents.valueChanged)
		
		return refreshControl
	}()
	
	@objc func handleRefresh(_ refreshControl: UIRefreshControl) {
		
		SoundHelper.playSoundIfAllowed(type: .refresh)
		
		//TODO: move to VM
		Session.shared.loadBalances()
		Session.shared.loadTransactions()
		
		refreshControl.endRefreshing()
	}
	
	@IBOutlet weak var usernameBarItem: UIBarButtonItem!
	
	@IBOutlet weak var usernameButton: UIButton!
	
	@IBOutlet var headerView: ScreenHeader? {
		didSet {
			headerView?.delegate = self
		}
	}
	
	@IBOutlet var usernameView: UsernameView!
	
	@IBOutlet weak var headerViewTitleLabel: UILabel!
	
	@IBOutlet override weak var tableView: UITableView! {
		didSet {
			tableView.contentInset = UIEdgeInsetsMake(95, 0, 0, 0)
		}
	}
	
	var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?
	
	@IBOutlet var tableHeaderTopConstraint: NSLayoutConstraint?
	
	var tableHeaderTopPadding: Double {
		return -95
	}
	
	//MARK: -
	
	var viewModel = CoinsViewModel()
	
	private var disposeBag = DisposeBag()

	// MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		registerCells()
		
		self.tableView.addSubview(self.refreshControl)
		
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
				
				if let convertCell = cell as? ConvertTransactionTableViewCell {
					convertCell.delegate = self
				}
				
				if let delegateCell = cell as? DelegateTransactionTableViewCell {
					delegateCell.delegate = self
				}
				
				return cell
		})
		
		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .top, reloadAnimation: .automatic, deleteAnimation: .automatic)
		
		tableView.rx.setDelegate(self).disposed(by: disposeBag)
		
		viewModel.sectionsObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)
		
		shouldAnimateCellToggle = true
		
		hidesBottomBarWhenPushed = false
		
		let username = UIBarButtonItem(customView: usernameView)
		username.width = 250
		
		self.navigationItem.rightBarButtonItems = [username]
		
		let usernameViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapUsernameView))
		usernameView?.addGestureRecognizer(usernameViewTapGesture)
		
		//Move to viewModel
		Session.shared.isLoggedIn.asObservable().map({ (val) -> Bool in
			return !val
		}).bind(to: usernameView.rx.isHidden).disposed(by: disposeBag)
		
		viewModel.usernameViewObservable.asObservable().subscribe(onNext: { [weak self] (user) in
			self?.updateUsernameView()
		}).disposed(by: disposeBag)
		
		
		viewModel.totalBalanceObservable.subscribe(onNext: { [weak self] (balance) in
			self?.headerViewTitleLabel.attributedText = self?.viewModel.headerViewTitleText(with: balance)
		}).disposed(by: disposeBag)
	
	}

	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		tableView.reloadData()
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.tableView.reloadData()
		
		AnalyticsHelper.defaultAnalytics.track(event: .CoinsScreen, params: nil)
		
		updateUsernameView()
		
	}
	
	//MARK: -
	
	func registerCells() {
		
		tableView.register(UINib(nibName: "CoinsTableViewHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "CoinsTableViewHeaderView")
		tableView.register(UINib(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: "TransactionTableViewCell")
		tableView.register(UINib(nibName: "ConvertTransactionTableViewCell", bundle: nil), forCellReuseIdentifier: "ConvertTransactionTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "CoinTableViewCell", bundle: nil), forCellReuseIdentifier: "CoinTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "LoadingTableViewCell", bundle: nil), forCellReuseIdentifier: "LoadingTableViewCell")
		tableView.register(UINib(nibName: "DelegateTransactionTableViewCell", bundle: nil), forCellReuseIdentifier: "DelegateTransactionTableViewCell")
	}
	
	//MARK: -
	
	func updateUsernameView() {
		usernameView.set(username: viewModel.rightButtonTitle, imageURL: viewModel.rightButtonImage)
	}
	
	@objc func didTapUsernameView() {
		self.tabBarController?.selectedIndex = 3
		
		AnalyticsHelper.defaultAnalytics.track(event: .CoinsUsernameButton, params: nil)
		
	}
	
	//MARK: -
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

		guard let section = viewModel.section(index: section) else {
			return UIView()
		}

		let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CoinsTableViewHeaderView")
		if let defaultHeader = header as? CoinsTableViewHeaderView {
			defaultHeader.titleLabel.text = section.header
		}

		return header
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 62
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		super.tableView(tableView, didSelectRowAt: indexPath)
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}

		performSegue(for: item.identifier)
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
		
		if let cell = rxDataSource?.tableView(self.tableView, cellForRowAt: indexPath) as? AccordionTableViewCell {
			return expandedIdentifiers.contains(cell.identifier) ? 430 : 55
		}
		return 55
	}
	
	//MARK: - ScreenHeaderProtocol
	
	func additionalUpdateHeaderViewFromScrollEvent(_ scrollView: UIScrollView) {
		
	}

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		headerView?.updateHeaderViewFromScrollEvent(scrollView)
	}
	
	//MARK: - Segues
	
	func performSegue(for cellIdentifier: String) {
		
		let vm = type(of: self.viewModel)
		
		//Move to router?
		switch cellIdentifier {
		case vm.cellIdentifierPrefix.convert.rawValue:
			perform(segue: CoinsViewController.Segue.showConvert)
			break
			
		case vm.cellIdentifierPrefix.transactions.rawValue:
			perform(segue: CoinsViewController.Segue.showTransactions)
			break
			
		default:
			break
		}
	}
	
	func presentExplorerController(with url: URL) {
		self.present(CoinsRouter.explorerViewController(url: url), animated: true) {}
	}

}

extension CoinsViewController : ButtonTableViewCellDelegate {
	
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		
		guard let indexPath = tableView.indexPath(for: cell), let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else { return }
		
		self.performSegue(for: item.identifier)
	}
}

extension CoinsViewController : TransactionTableViewCellDelegate, ConvertTransactionTableViewCellDelegate, DelegateTransactionTableViewCellDelegate {
	
	func didTapExpandedButton(cell: TransactionTableViewCell) {
		
		lightImpactFeedbackGenerator.prepare()
		lightImpactFeedbackGenerator.impactOccurred()
		
		AnalyticsHelper.defaultAnalytics.track(event: .TransactionExplorerButton, params: nil)
		
		if let indexPath = tableView.indexPath(for: cell), let url = viewModel.explorerURL(section: indexPath.section, row: indexPath.row) {
			presentExplorerController(with: url)
		}
	}
	
	func didTapExpandedButton(cell: ConvertTransactionTableViewCell) {
		
		lightImpactFeedbackGenerator.prepare()
		lightImpactFeedbackGenerator.impactOccurred()
		
		AnalyticsHelper.defaultAnalytics.track(event: .TransactionExplorerButton, params: nil)
		
		if let indexPath = tableView.indexPath(for: cell), let url = viewModel.explorerURL(section: indexPath.section, row: indexPath.row) {
			presentExplorerController(with: url)
		}
	}
	
	func didTapExpandedButton(cell: DelegateTransactionTableViewCell) {
		
		lightImpactFeedbackGenerator.prepare()
		lightImpactFeedbackGenerator.impactOccurred()
		
		AnalyticsHelper.defaultAnalytics.track(event: .TransactionExplorerButton, params: nil)
		
		if let indexPath = tableView.indexPath(for: cell), let url = viewModel.explorerURL(section: indexPath.section, row: indexPath.row) {
			presentExplorerController(with: url)
		}
	}
	
}

