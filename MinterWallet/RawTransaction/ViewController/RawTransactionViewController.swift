//
//  RawTransactionViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import NotificationBannerSwift

class RawTransactionViewController: BaseViewController, ControllerType {

	// MARK: -

	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.rowHeight = UITableViewAutomaticDimension
			tableView.estimatedRowHeight = 70.0
			tableView.tableFooterView = UIView()
			tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
		}
	}

	// MARK: -

	private var disposeBag = DisposeBag()
	private var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

	// MARK: - ControllerType

	typealias ViewModelType = RawTransactionViewModel

	var viewModel: ViewModelType!

	func configure(with viewModel: RawTransactionViewModel) {
		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
			configureCell: { [weak self] dataSource, tableView, indexPath, sm in
				guard let item = try? dataSource.model(at: indexPath) as! BaseCellItem,
					let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
					assert(true)
					return UITableViewCell()
				}
				cell.configure(item: item)
				return cell
		})

		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .top,
																																	reloadAnimation: .automatic,
																																	deleteAnimation: .automatic)

		viewModel.output.sections.asDriver(onErrorJustReturn: [])
			.drive(tableView.rx.items(dataSource: rxDataSource!))
			.disposed(by: disposeBag)

		viewModel.output.shouldClose.subscribe(onNext: { [weak self] (_) in
			self?.dismiss(animated: true, completion: nil)
		}).disposed(by: disposeBag)

		viewModel.output.errorNotification
			.asDriver(onErrorJustReturn: nil)
			.filter({ (notification) -> Bool in
				return nil != notification
		}).drive(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "",
																			subtitle: notification?.text,
																			style: .danger)
			banner.show()
		}).disposed(by: disposeBag)

		viewModel.output.successNotification.asObservable().filter({ (notification) -> Bool in
			return nil != notification
		}).subscribe(onNext: { (notification) in
			let banner = NotificationBanner(title: notification?.title ?? "",
																			subtitle: notification?.text,
																			style: .success)
			banner.show()
		}).disposed(by: disposeBag)
		
		viewModel.output
			.successNotification
			.asDriver(onErrorJustReturn: nil)
			.drive(onNext: { [weak self] (_) in
				SoundHelper.playSoundIfAllowed(type: .bip)
				self?.hardImpactFeedbackGenerator.prepare()
				self?.hardImpactFeedbackGenerator.impactOccurred()
		}).disposed(by: disposeBag)

		self.title = "Confirm Transaction"
	}

	// MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()

		configure(with: viewModel)

		registerCells()
	}

	// MARK: -

	private func registerCells() {
		tableView.register(UINib(nibName: "TextFieldTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "TextFieldTableViewCell")
		tableView.register(UINib(nibName: "TwoTitleTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "TwoTitleTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "ButtonTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "ButtonTableViewCell")
		tableView.register(UINib(nibName: "BlankTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "BlankTableViewCell")
		tableView.register(UINib(nibName: "RawTransactionFieldTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "RawTransactionFieldTableViewCell")
	}
}
