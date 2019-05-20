//
//  AddressAddressViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 20/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources


class AddressViewController: BaseViewController, UITableViewDelegate {
	
	let disposeBag = DisposeBag()
	
	var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.hidesBottomBarWhenPushed = true
	}
	
	//MARK: - IBOutlet
	
	@IBOutlet var headerView: UIView!
	
	@IBOutlet weak var headerViewWrapper: UIView!
	@IBOutlet weak var tableHeaderTitle: UILabel!
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView?.tableFooterView = UIView()
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 54.0
			tableView.tableHeaderView = UIView()
		}
	}
	
	@IBAction func didTapAddNewButton(_ sender: Any) {
		
		guard let advancedMode = Storyboards.AdvancedMode.storyboard.instantiateInitialViewController() as? AdvancedModeViewController else {
			return
		}
		advancedMode.delegate = self
		
		self.navigationController?.pushViewController(advancedMode, animated: true)
	}
	
	//MARK: -
	
	var viewModel = AddressViewModel()

	//MARK: Life cycle
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = viewModel.title
		
		registerCells()
		
		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
			configureCell: { [weak self] dataSource, tableView, indexPath, sm in
			guard
				let item = self?.viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
					return UITableViewCell()
			}
			
			guard let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? BaseCell else {
				if let cll = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) {
					return cll
				}
				
				return UITableViewCell()
			}

			cell.configure(item: item)
			
			if let switchCell = cell as? SwitchTableViewCell {
				switchCell.delegate = self
			}
			
			return cell
		})
		
		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .automatic, reloadAnimation: .automatic, deleteAnimation: .automatic)
		
		tableView.rx.setDelegate(self).disposed(by: disposeBag)
		
		viewModel.accountObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)
		
		self.navigationController?.navigationItem.rightBarButtonItem = nil
		
		tableView.contentInset = UIEdgeInsetsMake(-15, 0, 0, 0)
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		AnalyticsHelper.defaultAnalytics.track(event: .AddressesScreen, params: nil)
	}
	
	//MARK: -
	
	private func registerCells() {
		
		tableView.register(UINib(nibName: "AddressTableViewCell", bundle: nil), forCellReuseIdentifier: "AddressTableViewCell")
		tableView.register(UINib(nibName: "SettingsSwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SettingsSwitchTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "DisclosureTableViewCell", bundle: nil), forCellReuseIdentifier: "DisclosureTableViewCell")
		tableView.register(UINib(nibName: "DefaultHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "DefaultHeader")
	}
	
	//MARK: -
//
//	func numberOfSections(in tableView: UITableView) -> Int {
//		return viewModel.sectionsCount()
//	}
//
//	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//		return viewModel.rowsCount(for: section)
//	}
	
//	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//		guard
//			let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
//				return UITableViewCell()
//		}
//
//		guard let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? BaseCell else {
//			if let cll = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) {
//				return cll
//			}
//
//			return UITableViewCell()
//		}
//
//		cell.configure(item: item)
//
//		return cell
//	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		
		if section == 0 {
			return nil
		}
		
		let sectionNum = section + 1
		
		guard let section = viewModel.section(index: section) else {
			return UIView()
		}
		
		let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DefaultHeader")
		if let defaultHeader = header as? DefaultHeader {
			defaultHeader.titleLabel.text = "MAIN ADDRESS".localized()
			if sectionNum > 1 {
				defaultHeader.titleLabel.text = "ADDRESS #\(sectionNum)".localized()
			}
		}
		return header
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		
		
		if section == 0 {
			return
		}
		
		let sectionNum = section
		if let defaultHeader = view as? DefaultHeader {
			defaultHeader.titleLabel.text = "MAIN ADDRESS".localized()
			if sectionNum > 1 {
				defaultHeader.titleLabel.text = "ADDRESS #\(sectionNum)".localized()
			}
		}
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 0 {
			return 0.1
		}
		return 52
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0.1
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}
		
		if item.identifier.hasPrefix("DisclosureTableViewCell_Balance") {
			self.performSegue(withIdentifier: AddressViewController.Segue.showBalance.rawValue, sender: indexPath)
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if let switchCell = cell as? SettingsSwitchTableViewCell {

			guard let item = self.viewModel.cellItem(section: indexPath.section, row: indexPath.row) as? SwitchTableViewCellItem else {
				return
			}
			switchCell.switch.setOn(item.isOn.value, animated: true)
		}
	}
	
	//MARK: -
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		
		if segue.identifier == AddressViewController.Segue.showBalance.rawValue {
			
			guard let indexPath = sender as? IndexPath else {
				return
			}
			
			guard let account = viewModel.account(for: indexPath.section) else {
				return
			}
			
			let address = account.address.stripMinterHexPrefix()
			
			let vm = TransactionsViewModel(addresses: ["Mx" + address])
			if let vc = segue.destination as? TransactionsViewController {
				vc.viewModel = vm
			}
			
		}
	}
	
}

extension AddressViewController : SwitchTableViewCellDelegate {
	
	func didSwitch(isOn: Bool, cell: SwitchTableViewCell) {
		if let ip = tableView.indexPath(for: cell), let cellItem = viewModel.cellItem(section: ip.section, row: ip.row) {
			if isOn {
				viewModel.setMainAccount(isMain: isOn, cellItem: cellItem)
				
				UIView.animate(withDuration: 0.3, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseInOut], animations: { [weak self] in
					self?.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
				}) { (completed) in
					
				}
			}
		}
	}
	
//
//	func turnOffSwitches() {
//		tableView.visibleCells.forEach { (cell) in
//
//			if let switchCell = cell as? SettingsSwitchTableViewCell, let indexPath = tableView.indexPath(for: switchCell), let item = self.viewModel.cellItem(section: indexPath.section, row: indexPath.row) as? SwitchTableViewCellItem {
//
//				switchCell.switch.setOn(item.isOn.value, animated: false)
//			}
//		}
//	}

}

extension AddressViewController : AdvancedModeViewControllerDelegate {
	
	func AdvancedModeViewControllerDidAddAccount() {
		self.navigationController?.popToViewController(self, animated: true)
	}

}

