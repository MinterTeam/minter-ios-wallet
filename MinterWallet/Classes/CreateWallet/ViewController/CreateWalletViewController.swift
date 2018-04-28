//
//  CreateWalletCreateWalletViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


class CreateWalletViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

	//MARK: - IBOutlets

	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 70.0
			tableView.contentInset = UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)
		}
	}
	@IBOutlet var footerView: UIView!
	
	@IBAction func createWalletDidTap(_ sender: Any) {
		showCoins()
	}
	
	//MARK: -
	
	var viewModel = CreateWalletViewModel()

	//MARK: Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = viewModel.title
		self.tableView.tableFooterView = footerView
		
		registerCells()
	}

	//MARK: -
	
	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: "TextFieldTableViewCell")
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
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
	
	//MARK: -
	
	private func showCoins() {
		if let rootVC = UIViewController.stars_topMostController() as? RootViewController {
			let vc = Storyboards.Main.instantiateInitialViewController()
			
			rootVC.showViewControllerWith(vc, usingAnimation: .up) {
				
			}
		}
	}
}
