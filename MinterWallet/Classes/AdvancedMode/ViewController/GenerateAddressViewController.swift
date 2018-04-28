//
//  GenerateAddressViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class GenerateAddressViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, ButtonTableViewCellDelegate {
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 75.0
		}
	}
	
	//MARK: -
	
	var viewModel = GenerateAddressViewModel()
	
	//MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = viewModel.title
		
		registerCells()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	//MARK: - TableView

	private func registerCells() {
		
		tableView.register(UINib(nibName: "GenerateAddressSeedTableViewCell", bundle: nil), forCellReuseIdentifier: "GenerateAddressSeedTableViewCell")
		tableView.register(UINib(nibName: "GenerateAddressLabelTableViewCell", bundle: nil), forCellReuseIdentifier: "GenerateAddressLabelTableViewCell")
		tableView.register(UINib(nibName: "SettingsSwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SettingsSwitchTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "BlankTableViewCell", bundle: nil), forCellReuseIdentifier: "BlankTableViewCell")
		
		
	}

	//MARK: -

	func numberOfSections(in tableView: UITableView) -> Int {
		return viewModel.sectionsCount()
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? BaseCell else {
			return UITableViewCell()
		}
		
		cell.configure(item: item)
		
		if let buttonCell = cell as? ButtonTableViewCell {
			buttonCell.delegate = self
		}
		
		return cell
	}

//	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//
//		guard let section = viewModel.section(index: section) else {
//			return UIView()
//		}
//
//		let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DefaultHeader")
//		if let defaultHeader = header as? DefaultHeader {
//			defaultHeader.titleLabel.text = section.title
//		}
//
//		return header
//	}
//
//	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//		return 52
//	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}

	}

	//MARK: - ButtonTableViewCellDelegate
	
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		if let rootVC = UIViewController.stars_topMostController() as? RootViewController {
			let vc = Storyboards.Main.instantiateInitialViewController()
			
			rootVC.showViewControllerWith(vc, usingAnimation: .up) {
				
			}
		}
	}

}
