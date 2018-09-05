//
//  PasswordEditViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import NotificationBannerSwift
import RxSwift


class PasswordEditViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
	
	//MARK: - IBOutlets
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.tableFooterView = UIView()
			tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
		}
	}
	
	//MARK: -
	
	var viewModel = PasswordEditViewModel()
	
	private var disposeBag = DisposeBag()
	
	//MARK: - ViewController
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = viewModel.title
		
		registerCells()
		
		
		viewModel.errorNotification.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .danger)
			banner.show()
		}).disposed(by: disposeBag)
		
		viewModel.successMessage.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "", subtitle: notification?.text, style: .success)
			banner.show()
		}).disposed(by: disposeBag)
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		showKeyboard()
		
		AnalyticsHelper.defaultAnalytics.track(event: .PasswordEditScreen, params: nil)
	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	//MARK: - TableView
	
	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: "TextFieldTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil), forCellReuseIdentifier: "ButtonTableViewCell")
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
		
		if let buttonCell = (cell as? ButtonTableViewCell) {
			buttonCell.delegate = self
		}
		
		if var textFieldCell = cell as? ValidatableCellProtocol {
			textFieldCell.validateDelegate = self
		}
		
		
		return cell
	}
	
	//MARK: -
	
	func showKeyboard() {
		
		if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
			cell.startEditing()
		}
		
	}
	
}

extension PasswordEditViewController : ButtonTableViewCellDelegate, ValidatableCellDelegate {
	
	//MARK: -
	
	func didValidateField(field: ValidatableCellProtocol?) {
		if let ip = tableView.indexPath(for: field as! UITableViewCell) {
			if ip.row == 0 {
				viewModel.password.value = field?.validationText
			}
			else if ip.row == 1 {
				viewModel.confirmPassword.value = field?.validationText
			}
		}
	}
	
	func validate(field: ValidatableCellProtocol?, completion: (() -> ())?) {
		if let ip = tableView.indexPath(for: field as! UITableViewCell) {
			if ip.row == 0 {
				viewModel.password.value = field?.validationText
			}
			else if ip.row == 1 {
				viewModel.confirmPassword.value = field?.validationText
			}
			if let item = viewModel.cellItem(section: ip.section, row: ip.row) {
				let errors = viewModel.validate(item: item)
				if let err = errors?.first {
					(field as? TextFieldTableViewCell)?.setInvalid(message: err)
				}
				else {
					(field as? TextFieldTableViewCell)?.setDefault()
				}
			}
		}

	}
	
	//MARK: -
	
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		viewModel.changePassword()
	}

}
