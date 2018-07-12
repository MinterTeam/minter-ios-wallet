//
//  UsernameEditViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import NotificationBannerSwift


class UsernameEditViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, ValidatableCellDelegate {
	
	//MARK: - IBOutlets
	
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.tableFooterView = UIView()
			tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
		}
	}
	
	//MARK: -
	
	var viewModel = UsernameEditViewModel()
	
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
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	//MARK: - TableView
	
	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: "TextFieldTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil), forCellReuseIdentifier: "SeparatorTableViewCell")
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
		
		var textFieldCell = cell as? TextFieldTableViewCell
		textFieldCell?.validateDelegate = self
		
		if let button = cell as? ButtonTableViewCell {
			button.delegate = self
		}
		
		return cell
	}
	
	//MARK: -

	func showKeyboard() {
		
		if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
			cell.startEditing()
		}
	}
	
	func didValidateField(field: ValidatableCellProtocol?) {
		let value = field?.validationText
		
		viewModel.username.value = value
		
	}
	
	func validate(field: ValidatableCellProtocol?, completion: (() -> ())?) {
		
		viewModel.username.value = field?.validationText
		
		checkErrors()
	}
	
	//MARK: -
	
	func checkErrors() {
		if let errors = viewModel.validate(), let err = errors.first {
			if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
				cell.setInvalid(message: err)
			}
		}
		else {
			if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
				cell.setDefault()
			}
		}
	}
	
	//MARK: -

}

extension UsernameEditViewController : ButtonTableViewCellDelegate {
	
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell) {
		
		if let usernameCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell, let username = usernameCell.textField.text {
			
			self.viewModel.username.value = username
			
			checkErrors()
			
			if nil == viewModel.validate() {
				viewModel.update(username: username)
			}
		}
	}
	
}
