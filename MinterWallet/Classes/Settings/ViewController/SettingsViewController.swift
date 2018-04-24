//
//  SettingsSettingsViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class SettingsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

	//MARK: - IBOutput
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView?.tableFooterView = UIView()
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 54.0
		}
	}
	
	//MARK: -
	
	var viewModel = SettingsViewModel()

	// MARK: Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = viewModel.title
		
		registerCells()
	}
	
	private func registerCells() {
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "DisclosureTableViewCell", bundle: nil), forCellReuseIdentifier: "DisclosureTableViewCell")
		tableView.register(UINib(nibName: "DefaultHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "DefaultHeader")
	}
	
	//MARK: - TableView
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return viewModel.sectionsCount()
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard let item = self.viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier, for: indexPath) as? BaseCell else {
			return UITableViewCell()
		}
		
		cell.configure(item: item)
		
		return cell
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
		
		guard let section = viewModel.section(index: section), section.title != "" else {
			return 0.1
		}
		
		return 20
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}
		
		if item.identifier == "DisclosureTableViewCell_Addresses" {
			self.performSegue(withIdentifier: SettingsViewController.Segue.showAddress.rawValue, sender: self)
		}
	}
	
	//MARK: - Segues
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
	}

}
