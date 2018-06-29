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


class CreateWalletViewController: BaseViewController, UITableViewDelegate {

	//MARK: - IBOutlets

	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 70.0
			tableView.contentInset = UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)
		}
	}
	@IBOutlet var footerView: UIView!
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var createWalletButton: DefaultButton!
	
	@IBAction func createWalletDidTap(_ sender: Any) {
		
		tableView.endEditing(true)
		
		//validate all?
		
		viewModel.register()
	}
	
	//MARK: -
	
	var viewModel = CreateWalletViewModel()
	
	private var disposeBag = DisposeBag()
	private var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

	//MARK: Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = viewModel.title
		self.tableView.tableFooterView = footerView
		
		//TableView
		initializeTableView()
		
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
				
			}
			else {
				self?.activityIndicator.stopAnimating()
			}
		}.disposed(by: disposeBag)
		//activityIndicator
		
	}

	//MARK: -
	
	func initializeTableView() {
		registerCells()
		
		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(configureCell: { [weak self] (dataSource, tableView, IndexPath, itm) -> UITableViewCell in
			guard let item = self?.viewModel.cellItem(section: IndexPath.section, row: IndexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? BaseCell else {
				return UITableViewCell()
			}
			
			cell.configure(item: item)
			
			var validatableCell = cell as? ValidatableCellProtocol
			validatableCell?.validateDelegate = self
			
			return cell
		})
		
		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .automatic, reloadAnimation: .automatic, deleteAnimation: .automatic)
		
		tableView.rx.setDelegate(self).disposed(by: disposeBag)
		
		viewModel.sectionsObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)
	}
	
	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil), forCellReuseIdentifier: "TextFieldTableViewCell")
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return viewModel.rowsCount(for: section)
	}
	
//	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//		guard let item = self.viewModel.cellItem(section: indexPath.section, row: indexPath.row), let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier, for: indexPath) as? BaseCell else {
//			return UITableViewCell()
//		}
//
//		cell.configure(item: item)
//
//		if let validatableCell = cell as? ValidatableCellProtocol {
//			validatableCell.validateDelegate = self
//		}
//
//		if let textFieldCell = cell as? TextFieldTableViewCell {
//			textFieldCell.textField.rx.controlEvent([.editingDidEnd]).asObservable().subscribe(onNext: { (_) in
//			self.viewModel.checkField(identifier: item.identifier, value: textFieldCell.textField.text ?? "")
//			}).disposed(by: disposeBag)
//		}
//
//		return cell
//	}
	
	//MARK: -

}

extension CreateWalletViewController : ValidatableCellDelegate {
	
	
	func validate(field: ValidatableCellProtocol?, completion: (() -> ())?) {
		
		defer {
			completion?()
		}
		
		guard let cell = field as? TextFieldTableViewCell, let indexPath = tableView.indexPath(for: cell), let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) else {
			return
		}
		
		let value = cell.textField.text ?? ""
		
		viewModel.validate(item: item, value: value) { [weak self] (isValid, err) in
			
			guard nil != isValid else {
				cell.setDefault()
				return
			}
			
			if isValid! {
				cell.setValid()
			}
			else {
				var errorMessage: String?
				if let err = err {
					errorMessage = self?.viewModel.errorMessage(for: err)
				}
				cell.setInvalid(message: errorMessage)
			}
			
		}
	}
	
	
	func didValidateField(field: ValidatableCellProtocol?) {
		if let cell = field as? TextFieldTableViewCell, let indexPath = tableView.indexPath(for: cell), let item = viewModel.cellItem(section: indexPath.section, row: indexPath.row) {
//			if let username = cell.textField.text, item.identifier.hasPrefix("TextFieldTableViewCell_Username") {
//				viewModel.username.value = username
//			}
		}
	}
	
}
