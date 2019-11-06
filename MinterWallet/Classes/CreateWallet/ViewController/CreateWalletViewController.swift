//
//  CreateWalletCreateWalletViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import NotificationBannerSwift

class CreateWalletViewController: BaseViewController, ControllerType, UITableViewDelegate {

	// MARK: - ControllerType

	typealias ViewModelType = CreateWalletViewModel

	func configure(with viewModel: CreateWalletViewModel) {

		//Input

		createWalletButton.rx.tap.asObservable().subscribe(viewModel.input.createButtonDidTap).disposed(by: disposeBag)

		//Output

		viewModel.isButtonEnabled.asDriver(onErrorJustReturn: true).drive(createWalletButton.rx.isEnabled).disposed(by: disposeBag)
		
		self.viewModel = viewModel
	}

	// MARK: - IBOutlets

	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 70.0
		}
	}
	@IBOutlet var footerView: UIView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var createWalletButton: DefaultButton!
	@IBAction func createWalletDidTap(_ sender: Any) {
		tableView.endEditing(true)
	}
	
	//MARK: -
	//TODO: remove
	var viewModel: CreateWalletViewModel!

	private var disposeBag = DisposeBag()
	private var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

	// MARK: - Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		//TODO: move to Router
		self.configure(with: CreateWalletViewModel())

		self.title = viewModel.title
		self.tableView.tableFooterView = footerView

		//TableView
		initializeTableView()

		if #available(iOS 11.0, *) {
			tableView.contentInset = UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)
		} else {
			// Fallback on earlier versions
			tableView.contentInset = UIEdgeInsetsMake(-20.0, 0.0, 0.0, 0.0)
		}

		//Errors
		self.viewModel.notifiableError.asObservable().subscribe(onNext: { (errorNotification) in
			guard nil != errorNotification else {
				return
			}
			
			let banner = NotificationBanner(title: errorNotification?.title ?? "", subtitle: errorNotification?.text, style: .danger)
			banner.show()
		}).disposed(by: disposeBag)

		viewModel.isLoading.asObservable().bind { [weak self] (val) in
			
			self?.createWalletButton.isEnabled = !val
			self?.activityIndicator.isHidden = !val
			
			if val {
				self?.activityIndicator.startAnimating()
			} else {
				self?.activityIndicator.stopAnimating()
			}
		}.disposed(by: disposeBag)

		if self.shouldShowTestnetToolbar {
			self.tableView.contentInset = UIEdgeInsets(top: 90,
																								 left: 0,
																								 bottom: 0,
																								 right: 0)
			self.view.addSubview(self.testnetToolbarView)
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextFieldTableViewCell {
			cell.textField?.becomeFirstResponder()
		}
	}

	// MARK: -

	func initializeTableView() {
		registerCells()

		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(configureCell: { [weak self] (dataSource, tableView, indexPath, _) -> UITableViewCell in
			guard let item = self?.viewModel.cellItem(section: indexPath.section, row: indexPath.row),
				let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? BaseCell else {
				return UITableViewCell()
			}

			cell.configure(item: item)

			let validatableCell = cell as? ValidatableCellProtocol
			validatableCell?.validateDelegate = self

			return cell
		})

		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .automatic,
																																	reloadAnimation: .automatic,
																																	deleteAnimation: .automatic)

		tableView.rx.setDelegate(self).disposed(by: disposeBag)

		viewModel.sectionsObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)
	}

	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "TextFieldTableViewCell")
	}
}

extension CreateWalletViewController: ValidatableCellDelegate {

	func validate(field: ValidatableCellProtocol?, completion: (() -> ())?) {

		defer {
			completion?()
		}

		guard let cell = field as? TextFieldTableViewCell,
			let indexPath = tableView.indexPath(for: cell),
			let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}

		let value = cell.textField.text ?? ""

		cell.setDefault()
		viewModel.validate(item: item, value: value) { [weak self] (isValid, err) in

			guard nil != isValid else {
				cell.setDefault()
				return
			}

			if isValid! {
				cell.setValid()
			} else {
				var errorMessage: String?
				if let err = err {
					errorMessage = self?.viewModel.errorMessage(for: err)
				}
				cell.setInvalid(message: errorMessage)
			}
		}
	}

	func didValidateField(field: ValidatableCellProtocol?) {}

}
