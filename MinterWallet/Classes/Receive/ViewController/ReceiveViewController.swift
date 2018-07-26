//
//  ReceiveReceiveViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources


class ReceiveViewController: BaseViewController, UITableViewDelegate {

	var viewModel = ReceiveViewModel()
	
	let disposeBag = DisposeBag()
	var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?
	
	//MARK: -
	
	@IBAction func shareButtonDidTap(_ sender: Any) {
		if let activities = viewModel.activities() {
			let vc = UIActivityViewController(activityItems: activities, applicationActivities: [])
			present(vc, animated: true)
		}
	}
	
	@IBOutlet var footerView: UIView!
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.tableFooterView = self.footerView
			tableView.contentInset = UIEdgeInsets(top: -40, left: 0, bottom: 0, right: 0)
		}
	}
	
	// MARK: Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()
		
		registerCells()
		
		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
			configureCell: { [weak self] dataSource, tableView, indexPath, sm in
				guard let item = self?.viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? BaseCell else {
					return UITableViewCell()
				}
				
				cell.configure(item: item)
				
				return cell
		})
		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .automatic, reloadAnimation: .automatic, deleteAnimation: .automatic)
		
		tableView.rx.setDelegate(self).disposed(by: disposeBag)
		
		viewModel.sectionsObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)
	}
	
	
	//MARK: - TableView
	
	private func registerCells() {
		
		tableView.register(UINib(nibName: "AddressTableViewCell", bundle: nil), forCellReuseIdentifier: "AddressTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "DefaultHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "DefaultHeader")
	}

	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 52
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
	

}
