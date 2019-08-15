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
import NotificationBannerSwift

class CoinsViewController: BaseTableViewController, ScreenHeaderProtocol, ControllerType {

	// MARK: - ControllerType

	typealias ViewModelType = CoinsViewModel

	func configure(with viewModel: CoinsViewModel) {

		refreshControl.rx.controlEvent([.valueChanged])
			.subscribe(viewModel.input.didRefresh).disposed(by: disposeBag)

		viewModel.output
			.totalDelegatedBalance
			.asDriver(onErrorJustReturn: "").drive(onNext: { [weak self] (val) in
				var shouldLayout = false
				if val == nil {
					if self?.delegatedHeaderTopConstraint.constant == -63.0 {
						shouldLayout = false
					} else {
						self?.delegatedHeaderTopConstraint.constant = -63.0
						shouldLayout = true
					}
					self?.delegatedBalanceLabel.text = "0.0"
				} else {
					if self?.delegatedHeaderTopConstraint.constant == 0.0 {
						shouldLayout = false
					} else {
						self?.delegatedHeaderTopConstraint.constant = 0.0
						shouldLayout = true
					}
					self?.delegatedBalanceLabel.text = val
				}

				let additionalTop = (self?.shouldShowTestnetToolbar ?? false) ? CGFloat(56) : CGFloat(0)
				if val == nil {
					let top = 60 + additionalTop
					if self?.tableView.contentInset.top != top {
						self?.tableView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0)
						shouldLayout = true
					}
				} else {
					let top = 100 + additionalTop
					if self?.tableView.contentInset.top != top {
						self?.tableView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0)
						shouldLayout = true
					}
				}

				UIView.animate(withDuration: 0.5, animations: {
					if shouldLayout {
						self?.view.layoutIfNeeded()
					}
				})

		}).disposed(by: disposeBag)
	}

	// MARK: -

	var refreshControl: UIRefreshControl! {
		didSet {
			refreshControl.translatesAutoresizingMaskIntoConstraints = false
			refreshControl.addTarget(self, action:
				#selector(CoinsViewController.handleRefresh(_:)),
															 for: UIControlEvents.valueChanged)
		}
	}
	@objc func handleRefresh(_ refreshControl: UIRefreshControl) {
		SoundHelper.playSoundIfAllowed(type: .refresh)
		refreshControl.endRefreshing()
	}
	@IBOutlet weak var balanceBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var balanceTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
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
			tableView.contentInset = UIEdgeInsetsMake(50, 0, 0, 0)
		}
	}
	@IBOutlet weak var dotCircle1ImageView: UIImageView!
	@IBOutlet weak var dotCircle2ImageView: UIImageView!
	@IBOutlet weak var robotImageView: UIImageView!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var delegatedHeaderTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var delegatedBalanceLabel: UILabel!
	@IBOutlet var tableHeaderTopConstraint: NSLayoutConstraint?

	// MARK: -

	var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

	var tableHeaderTopPadding: Double {
		if shouldShowTestnetToolbar {
			return -105
		}
		return -72
	}

	// MARK: -

	var viewModel = CoinsViewModel()

	private var disposeBag = DisposeBag()

	// MARK: Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		refreshControl = UIRefreshControl()

		configure(with: viewModel)

		registerCells()

		self.tableView.addSubview(self.refreshControl)

		self.tableView.addConstraints(NSLayoutConstraint
			.constraints(withVisualFormat: "V:|-(-10)-[refreshControl(30)]",
									 options: [],
									 metrics: nil,
									 views: ["refreshControl": refreshControl]))

		self.tableView.addConstraint(NSLayoutConstraint(item: refreshControl,
																										attribute: .centerX,
																										relatedBy: .equal,
																										toItem: tableView,
																										attribute: .centerX,
																										multiplier: 1.0,
																										constant: 0.0))

		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
			configureCell: { [weak self] dataSource, tableView, indexPath, sm in

				guard let item = self?.viewModel.cellItem(section: indexPath.section,
																									row: indexPath.row),
					let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
					return UITableViewCell()
				}

				cell.configure(item: item)

				if let buttonCell = cell as? ButtonTableViewCell {
					buttonCell.delegate = self
				}
				if let transactionCell = cell as? ExpandableCell {
					transactionCell.delegate = self
				}

				if let accordionCell = cell as? AccordionTableViewCell {
					let isExpanded = self?.expandedIdentifiers
						.contains(accordionCell.identifier) ?? false
					(cell as? ExpandableCell)?.toggle(isExpanded, animated: false)
				}
				return cell
		})

		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .top,
																																	reloadAnimation: .automatic,
																																	deleteAnimation: .automatic)

		tableView.rx.setDelegate(self).disposed(by: disposeBag)

		viewModel.sectionsObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)

		shouldAnimateCellToggle = true

		hidesBottomBarWhenPushed = false

		let username = UIBarButtonItem(customView: usernameView)
		username.width = 250

		self.navigationItem.rightBarButtonItems = [username]

		let usernameViewTapGesture = UITapGestureRecognizer(target: self,
																												action: #selector(didTapUsernameView))
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

		viewModel.errorObservable.distinctUntilChanged().subscribe(onNext: { [weak self] (val) in
			UIView.animate(withDuration: 0.25,animations: {
				if val {
					self?.showPlaceholderView()
				} else {
					self?.hidePlaceholderView()
				}
			})
		}).disposed(by: disposeBag)

		if self.shouldShowTestnetToolbar {
			headerViewHeightConstraint.constant = 73.0 + 56.0
			tableHeaderTopConstraint?.constant = 73.0 + 56.0

			self.view?.addSubview(self.testnetToolbarView)
			self.balanceTopConstraint.constant = 80
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		AnalyticsHelper.defaultAnalytics.track(event: .CoinsScreen,
																					 params: nil)
	}

	// MARK: -

	func registerCells() {
		tableView.register(UINib(nibName: "CoinsTableViewHeaderView", bundle: nil),
											 forHeaderFooterViewReuseIdentifier: "CoinsTableViewHeaderView")
		tableView.register(UINib(nibName: "TransactionTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "TransactionTableViewCell")
		tableView.register(UINib(nibName: "ConvertTransactionTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "ConvertTransactionTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "CoinTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "CoinTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "LoadingTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "LoadingTableViewCell")
		tableView.register(UINib(nibName: "DelegateTransactionTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "DelegateTransactionTableViewCell")
		tableView.register(UINib(nibName: "MultisendTransactionTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "MultisendTransactionTableViewCell")
		tableView.register(UINib(nibName: "RedeemCheckTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "RedeemCheckTableViewCell")
	}

	// MARK: -

	func updateUsernameView() {
		usernameView.set(username: viewModel.rightButtonTitle, imageURL: viewModel.rightButtonImage)
	}

	func hidePlaceholderView() {
		self.tableView.backgroundColor = .white
		self.dotCircle1ImageView.isHidden = true
		self.dotCircle2ImageView.isHidden = true
		self.robotImageView.isHidden = true
		self.errorLabel.isHidden = true
	}

	func showPlaceholderView() {
		self.tableView.backgroundColor = UIColor(hex: 0x4225A4)
		self.dotCircle1ImageView.isHidden = false
		self.dotCircle2ImageView.isHidden = false
		self.robotImageView.isHidden = false
		self.errorLabel.isHidden = false
	}

	// MARK: -

	@objc func didTapUsernameView() {
		self.tabBarController?.selectedIndex = 3
		AnalyticsHelper.defaultAnalytics.track(event: .CoinsUsernameButton, params: nil)
	}

	// MARK: -

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
		return 52
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		super.tableView(tableView, didSelectRowAt: indexPath)

		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}
		performSegue(for: item.identifier)
	}

	func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
		if let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) {
			if item.reuseIdentifier == "BlankTableViewCell" {
				return false
			}
		}
		return true
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

		if let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) {
			if item.reuseIdentifier == "BlankTableViewCell" {
				return 8
			}
			if item.reuseIdentifier == "ButtonTableViewCell" {
				return 70.0
			} else if item.reuseIdentifier == "SeparatorTableViewCell" {
				return 1.0
			}
		}

		if let cell = rxDataSource?.tableView(self.tableView, cellForRowAt: indexPath) as? AccordionTableViewCell {
			if nil != cell as? MultisendTransactionTableViewCell {
				return expandedIdentifiers.contains(cell.identifier) ? 315 : 55
			} else if nil != cell as? ConvertTransactionTableViewCell {
				return expandedIdentifiers.contains(cell.identifier) ? 295 : 55
			}
			return expandedIdentifiers.contains(cell.identifier) ? 444 : 55
		}
		return 55
	}

	// MARK: - ScreenHeaderProtocol

	func additionalUpdateHeaderViewFromScrollEvent(_ scrollView: UIScrollView) {}

	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		headerView?.updateHeaderViewFromScrollEvent(scrollView)
	}

	// MARK: - Segues

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

extension CoinsViewController: ButtonTableViewCellDelegate {

	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		guard let indexPath = tableView.indexPath(for: cell),
			let item = viewModel.cellItem(section: indexPath.section,
																		row: indexPath.row) else { return }

		self.performSegue(for: item.identifier)
	}
}

//TODO: refactor it to a one protocol
extension CoinsViewController: ExpandedTransactionTableViewCellDelegate {

	func didTapExplorerButton(cell: ExpandableCell) {
		performLightImpact()

		AnalyticsHelper.defaultAnalytics.track(event: .TransactionExplorerButton, params: nil)

		if let indexPath = tableView.indexPath(for: cell),
			let url = viewModel.explorerURL(section: indexPath.section, row: indexPath.row) {
			presentExplorerController(with: url)
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
