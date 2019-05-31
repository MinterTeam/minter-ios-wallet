//
//  GenerateAddressViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift

protocol GenerateAddressViewControllerDelegate : class {
	func GenerateAddressViewControllerDelegateDidAddAccount()
}

class GenerateAddressViewController: BaseViewController,
UITableViewDataSource,
UITableViewDelegate,
ButtonTableViewCellDelegate,
SwitchTableViewCellDelegate {

	// MARK: - IBOutlet

	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 75.0
		}
	}

	// MARK: -

	var viewModel = GenerateAddressViewModel()

	private var disposeBag = DisposeBag()

	weak var delegate: GenerateAddressViewControllerDelegate?

	// MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = viewModel.title

		registerCells()

		viewModel.proceedAvailable.asObservable().subscribe(onNext: { [weak self] (val) in
			if let cell = self?.tableView.cellForRow(at: IndexPath(row: 7, section: 0)) as? ButtonTableViewCell {
				cell.button.isEnabled = val
			}
		}).disposed(by: disposeBag)

		if self.shouldShowTestnetToolbar {
			self.tableView.contentInset = UIEdgeInsets(top: 50,
																								 left: 0,
																								 bottom: 0,
																								 right: 0)
			self.view.addSubview(self.testnetToolbarView)
		}

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - TableView

	private func registerCells() {
		tableView.register(UINib(nibName: "GenerateAddressSeedTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "GenerateAddressSeedTableViewCell")
		tableView.register(UINib(nibName: "GenerateAddressLabelTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "GenerateAddressLabelTableViewCell")
		tableView.register(UINib(nibName: "SettingsSwitchTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SettingsSwitchTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "BlankTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "BlankTableViewCell")
	}

	// MARK: -

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
		if let switchCell = cell as? SwitchTableViewCell {
			switchCell.delegate = self
		}

		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}
	}

	// MARK: - ButtonTableViewCellDelegate

	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {

		SoundHelper.playSoundIfAllowed(type: .click)

		viewModel.activate()

		delegate?.GenerateAddressViewControllerDelegateDidAddAccount()
	}

	// MARK: - SwitchTableViewCellDelegate

	func didSwitch(isOn: Bool, cell: SwitchTableViewCell) {
		viewModel.setMnemonicChecked(isChecked: isOn)
	}

}
