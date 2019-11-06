//
//  EmailEditViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 27/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import NotificationBannerSwift
import RxSwift

class EmailEditViewController: BaseViewController,
UITableViewDelegate,
UITableViewDataSource {

	// MARK: - IBOutlet

	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.tableFooterView = UIView()
			tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
		}
	}

	// MARK: -

	var viewModel = EmailEditViewModel()

	private var disposeBag = DisposeBag()

	// MARK: - ViewController

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

		viewModel.emailErrors.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (err) in
			if let cell = self?.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
				if err != nil {
					cell.setInvalid(message: err)
				} else {
					cell.setDefault()
				}
			}
		}).disposed(by: disposeBag)

		if self.shouldShowTestnetToolbar {
			self.tableView.contentInset = UIEdgeInsets(top: 65, left: 0, bottom: 0, right: 0)
			self.view.addSubview(self.testnetToolbarView)
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		showKeyboard()
		AnalyticsHelper.defaultAnalytics.track(event: .emailEditScreen, params: nil)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - TableView

	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "TextFieldTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "ButtonTableViewCell")
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let item = self.viewModel.cellItem(section: indexPath.section, row: indexPath.row),
			let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier, for: indexPath) as? BaseCell else {
			return UITableViewCell()
		}

		cell.configure(item: item)

		let validationCell = cell as? ValidatableCellProtocol
		validationCell?.validateDelegate = self

		if let textFieldCell = cell as? TextFieldTableViewCell {
			textFieldCell.textField.rx.text.orEmpty.bind(to: viewModel.email).disposed(by: disposeBag)
		}

		let buttonCell = cell as? ButtonTableViewCell
		buttonCell?.delegate = self

		buttonCell?.button.rx.tap.asObservable().subscribe(viewModel.saveInDidTap).disposed(by: disposeBag)
		return cell
	}

	// MARK: -

	func showKeyboard() {
		if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
			cell.startEditing()
		}
	}
}

extension EmailEditViewController: ButtonTableViewCellDelegate {

	func buttonTableViewCellDidTap(_ cell: ButtonTableViewCell) {

		SoundHelper.playSoundIfAllowed(type: .click)

		hardImpactFeedbackGenerator.prepare()
		hardImpactFeedbackGenerator.impactOccurred()

		tableView.endEditing(true)
	}
}

extension EmailEditViewController: ValidatableCellDelegate {

	func validate(field: ValidatableCellProtocol?, completion: (() -> ())?) {
		completion?()
	}

	func didValidateField(field: ValidatableCellProtocol?) {

	}

}
