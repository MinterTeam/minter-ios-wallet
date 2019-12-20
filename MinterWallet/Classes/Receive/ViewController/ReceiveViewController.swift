//
//  ReceiveReceiveViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import RxCocoa
import NotificationBannerSwift

class ReceiveViewController: BaseViewController, UITableViewDelegate, ControllerType {

  // MARK: - ControllerType

  typealias ViewModelType = ReceiveViewModel

  var viewModel: ReceiveViewModel! = ReceiveViewModel()

  func configure(with viewModel: ReceiveViewController.ViewModelType) {

    addToWalletButton.rx.tap.asDriver().drive(viewModel.input.didTapAddPass).disposed(by: disposeBag)

    viewModel
      .output
      .showViewController
      .asDriver(onErrorJustReturn: nil)
      .drive(onNext: { [weak self] (viewController) in
        guard let viewController = viewController else { return }
        self?.tabBarController?.present(viewController, animated: true, completion: nil)
      }).disposed(by: disposeBag)

    viewModel.output.isLoadingPass.asDriver(onErrorJustReturn: false).drive(onNext: { [weak self] (val) in
      self?.addToWalletButton.isEnabled = !val
      self?.addWalletActivityIndicator.alpha = val ? 1.0 : 0.0
      if val {
        self?.addWalletActivityIndicator.startAnimating()
      } else {
        self?.addWalletActivityIndicator.stopAnimating()
      }
      }).disposed(by: disposeBag)
  }

	// MARK: -

	let disposeBag = DisposeBag()
	var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?

	// MARK: -

  @IBOutlet weak var addWalletActivityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var addToWalletButton: DefaultButton!
  @IBAction func shareButtonDidTap(_ sender: UIButton) {

		hardImpactFeedbackGenerator.prepare()
		hardImpactFeedbackGenerator.impactOccurred()

		AnalyticsHelper.defaultAnalytics.track(event: .receiveShareButton)

		if let activities = viewModel.activities() {
			let vc = ReceiveRouter.activityViewController(activities: activities,
																										sourceView: sender)
			present(vc, animated: true)
		}
	}

	@IBOutlet var footerView: UIView!

	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.tableFooterView = self.footerView
			tableView.contentInset = UIEdgeInsets(top: -40,
																						left: 0,
																						bottom: 0,
																						right: 0)
		}
	}

	// MARK: Life cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		registerCells()

    configure(with: viewModel)

    rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
      configureCell: { dataSource, tableView, indexPath, sm in
        guard
          let datasourceItem = try? dataSource.model(at: indexPath) as? BaseCellItem,
          let item = datasourceItem,
          let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
            return UITableViewCell()
        }
        cell.configure(item: item)

        if let qrCell = cell as? QRTableViewCell {
          qrCell.delegate = self
        }
        return cell
    })

		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .automatic,
																																	reloadAnimation: .automatic,
																																	deleteAnimation: .automatic)

		tableView.rx.setDelegate(self).disposed(by: disposeBag)

		viewModel.sectionsObservable.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)

		if self.shouldShowTestnetToolbar {
			self.tableView.contentInset = UIEdgeInsets(top: 8,
																								 left: 0,
																								 bottom: 0,
																								 right: 0)
			self.view.addSubview(self.testnetToolbarView)
		}

	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

    setNeedsStatusBarAppearanceUpdate()

		AnalyticsHelper.defaultAnalytics.track(event: .receiveScreen, params: nil)
	}

	// MARK: - TableView

	private func registerCells() {
		tableView.register(UINib(nibName: "AddressTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "AddressTableViewCell")
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SeparatorTableViewCell")
		tableView.register(UINib(nibName: "DefaultHeader", bundle: nil),
											 forHeaderFooterViewReuseIdentifier: "DefaultHeader")
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 52
	}

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

		guard let section = viewModel.section(index: section) else {
			return UIView()
		}

		let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DefaultHeader")
		if let defaultHeader = header as? DefaultHeader {
			defaultHeader.titleLabel.text = section.header
		}

		return header
	}
}

extension ReceiveViewController: QRTableViewCellDelegate {

	func QRTableViewCellDidTapCopy(cell: QRTableViewCell) {
		if let indexPath = tableView.indexPath(for: cell),
			let item = viewModel.cellItem(section: indexPath.section,
																		row: indexPath.row),
			let qrItem = item as? QRTableViewCellItem {

			self.lightImpactFeedbackGenerator.prepare()
			self.lightImpactFeedbackGenerator.impactOccurred()

			guard let str = qrItem.string, let img = QRCode(str)?.image else {
				return
			}

			SoundHelper.playSoundIfAllowed(type: .click)

			UIPasteboard.general.image = img
			let banner = NotificationBanner(title: "Copied".localized(), subtitle: nil, style: .info)
			banner.show()
		}
	}
}
