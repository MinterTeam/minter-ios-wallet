//
//  LoginLoginViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import NotificationBannerSwift
import RxSwift

protocol LoginViewControllerDelegate: class {
	func didLogin()
}

class LoginViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource, ValidatableCellDelegate {

	// MARK: -

	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
		}
	}

	// MARK: -

	weak var delegate: LoginViewControllerDelegate?

	var viewModel = LoginViewModel()

	private var disposeBag = DisposeBag()

	// MARK: - Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		registerCells()

		self.title = viewModel.title

		self.viewModel.notifiableError.asObservable().subscribe(onNext: { (errorNotification) in
			guard nil != errorNotification else {
				return
			}

			let banner = NotificationBanner(title: errorNotification?.title ?? "",
																			subtitle: errorNotification?.text,
																			style: .danger)
			banner.show()
		}).disposed(by: disposeBag)

		if self.shouldShowTestnetToolbar {
			self.tableView.contentInset = UIEdgeInsets(top: 30,
																								 left: 0,
																								 bottom: 0,
																								 right: 0)
			self.view.addSubview(self.testnetToolbarView)
		}

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
			cell.textField?.becomeFirstResponder()
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}

	// MARK: - TableView

	func registerCells() {
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "TextFieldTableViewCell")
	}

	func didValidateField(field: ValidatableCellProtocol?) {

	}

	func validate(field: ValidatableCellProtocol?, completion: (() -> ())?) {

		if let cell = field as? UITableViewCell,
			let ip = tableView.indexPath(for: cell) {
			if ip.row == 0 {
				viewModel.username.value = field?.validationText
			} else if ip.row == 1 {
				viewModel.password.value = field?.validationText
			}
		}
	}

	// MARK: -

	func numberOfSections(in tableView: UITableView) -> Int {
		return viewModel.sectionsCount()
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		guard let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row),
			let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
			return UITableViewCell()
		}

		cell.configure(item: item)

		if var textFieldCell = cell as? ValidatableCellProtocol {
			textFieldCell.validateDelegate = self
		}

		if let buttonCell = cell as? ButtonTableViewCell {
			buttonCell.delegate = self
		}

		return cell
	}
}

extension LoginViewController: ButtonTableViewCellDelegate {

	func buttonTableViewCellDidTap(_ cell: ButtonTableViewCell) {

		let usernameCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell
		let passwordCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? TextFieldTableViewCell

		let username = usernameCell?.textField.text
		let password = passwordCell?.textField.text

		guard nil != username && nil != password else {
			//Show error
			return
		}

		viewModel.login(username: username!, password: password!)
	}
}
