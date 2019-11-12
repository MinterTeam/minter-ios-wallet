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

	var popupViewController: PopupViewController?

	// MARK: - IBOutlet

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
			configureCell: { dataSource, tableView, indexPath, sm in
				guard let item = try? dataSource.model(at: indexPath) as! BaseCellItem, // swiftlint:disable:this force_cast
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

		viewModel
			.output
			.shouldClose
			.subscribe(onNext: { [weak self] (_) in
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

		viewModel
			.output
			.successNotification
			.asObservable()
			.filter({ (notification) -> Bool in
				return nil != notification
			}).subscribe(onNext: { (notification) in
				let banner = NotificationBanner(title: notification?.title ?? "",
																				subtitle: notification?.text,
																				style: .success)
				banner.show()
			}).disposed(by: disposeBag)

		viewModel
			.output
			.vibrate
			.asDriver(onErrorJustReturn: ())
			.drive(onNext: { [weak self] _ in
				SoundHelper.playSoundIfAllowed(type: .bip)
				self?.hardImpactFeedbackGenerator.prepare()
				self?.hardImpactFeedbackGenerator.impactOccurred()
		}).disposed(by: disposeBag)

		viewModel
			.output
			.popup
			.asDriver(onErrorJustReturn: nil)
			.drive(onNext: { [weak self] (popup) in
				if popup == nil {
					self?.popupViewController?.dismiss(animated: true, completion: nil)
					self?.popupViewController = nil
					return
				}

				if let popupVC = popup as? SentPopupViewController {
					popupVC.delegate = self
					popup?.popupViewControllerDelegate = self
				}
				if let popupVC = popup as? ConfirmPopupViewController {
					self?.popupViewController = nil
					popupVC.delegate = self
				}

				if self?.popupViewController == nil {
					self?.showPopup(viewController: popup!, inTabbar: false)
					self?.popupViewController = popup
				} else {
					self?.showPopup(viewController: popup!,
													inPopupViewController: self!.popupViewController,
													inTabbar: false)
				}
		}).disposed(by: disposeBag)

		self.title = "Confirm Transaction".localized()
	}

	// MARK: - ViewController

	override func viewDidLoad() {
		super.viewDidLoad()

		configure(with: viewModel)
		registerCells()
	}
}

extension RawTransactionViewController: SentPopupViewControllerDelegate, ConfirmPopupViewControllerDelegate {

	// MARK: - ConfirmPopupViewController Delegate

	func didTapActionButton(viewController: ConfirmPopupViewController) {
		SoundHelper.playSoundIfAllowed(type: .click)
		hardImpactFeedbackGenerator.prepare()
		hardImpactFeedbackGenerator.impactOccurred()
		AnalyticsHelper.defaultAnalytics.track(event: .rawTransactionPopupViewTransactionButton)
	}

	func didTapSecondButton(viewController: ConfirmPopupViewController) {
		SoundHelper.playSoundIfAllowed(type: .cancel)
		lightImpactFeedbackGenerator.prepare()
		AnalyticsHelper.defaultAnalytics.track(event: .rawTransactionPopupCloseButton)
		viewController.dismiss(animated: true, completion: nil)
	}

	// MARK: - SentPopupViewControllerDelegate

	func didTapActionButton(viewController: SentPopupViewController) {
		SoundHelper.playSoundIfAllowed(type: .click)
		hardImpactFeedbackGenerator.prepare()
		hardImpactFeedbackGenerator.impactOccurred()
		AnalyticsHelper.defaultAnalytics.track(event: .rawTransactionPopupViewTransactionButton)
		let presentingVC = self.presentingViewController
		viewController.dismiss(animated: true) { [weak self] in
			self?.dismiss(animated: true) {
				if let url = self?.viewModel.lastTransactionExplorerURL() {
					let vc = BaseSafariViewController(url: url)
					presentingVC?.present(vc, animated: true) {}
				}
			}
		}
	}

	func didTapSecondActionButton(viewController: SentPopupViewController) {
		SoundHelper.playSoundIfAllowed(type: .click)
		lightImpactFeedbackGenerator.prepare()
		lightImpactFeedbackGenerator.impactOccurred()
		AnalyticsHelper.defaultAnalytics.track(event: .rawTransactionPopupShareTransactionButton)
		let presentingVC = self.presentingViewController
		viewController.dismiss(animated: true) { [weak self] in
			self?.dismiss(animated: true) {
				if let url = self?.viewModel.output.lastTransactionExplorerURL() {
					let vc = ActivityRouter.activityViewController(activities: [url], sourceView: self!.view)
					presentingVC?.present(vc, animated: true, completion: nil)
				}
			}
		}
	}

	func didTapSecondButton(viewController: SentPopupViewController) {
		SoundHelper.playSoundIfAllowed(type: .cancel)
		lightImpactFeedbackGenerator.prepare()
		AnalyticsHelper.defaultAnalytics.track(event: .rawTransactionPopupCloseButton)
		viewController.dismiss(animated: true) { [weak self] in
			self?.dismiss(animated: true) {}
		}
	}
}

extension RawTransactionViewController {
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

extension RawTransactionViewController: PopupViewControllerDelegate {
	func didDismissPopup(viewController: PopupViewController?) {
		if let viewController = viewController as? SentPopupViewController {
			viewController.dismiss(animated: true) { [weak self] in
				self?.dismiss(animated: true, completion: {

				})
			}
		}
	}
}
