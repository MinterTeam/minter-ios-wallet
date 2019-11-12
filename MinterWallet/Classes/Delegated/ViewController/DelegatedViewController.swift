//
//  DelegatedViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 07/06/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

class DelegatedViewController: BaseViewController, ControllerType {

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	// MARK: -

	@IBOutlet weak var tableView: UITableView!

	// MARK: - ControllerType

	var viewModel: DelegatedViewModel!
	typealias ViewModelType = DelegatedViewModel

	func configure(with viewModel: DelegatedViewModel) {
		//Input
		self.rx.viewDidLoad.bind(to: viewModel.input.viewDidLoad).disposed(by: disposeBag)
	}

	// MARK: -

	var rxDataSource: RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>?
	var disposeBag = DisposeBag()

	override func viewDidLoad() {
		super.viewDidLoad()

		configure(with: viewModel)

		registerCells()

		rxDataSource = RxTableViewSectionedAnimatedDataSource<BaseTableSectionItem>(
			configureCell: { [weak self] dataSource, tableView, indexPath, sm in

				guard
					let item = try! dataSource.model(at: indexPath) as? BaseCellItem, // swiftlint:disable:this force_try
					let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier) as? ConfigurableCell else {
						return UITableViewCell()
				}

				cell.configure(item: item)

				if let delegatedCell = cell as? DelegatedTableViewCell {
					delegatedCell.delegate = self
				}
				return cell
			})

		rxDataSource?.animationConfiguration = AnimationConfiguration(insertAnimation: .top,
																																	reloadAnimation: .automatic,
																																	deleteAnimation: .automatic)
		//Output
		viewModel.output.sections.bind(to: tableView.rx.items(dataSource: rxDataSource!)).disposed(by: disposeBag)
		tableView.rx.setDelegate(self).disposed(by: disposeBag)
		tableView.rx.willDisplayCell.subscribe(viewModel.input.willDisplayCell).disposed(by: disposeBag)

		viewModel.input.viewDidLoad.onNext(())
	}

	func registerCells() {
		tableView.register(UINib(nibName: "SeparatorTableViewCell", bundle: nil),
											 forCellReuseIdentifier: "SeparatorTableViewCell")
	}
}

extension DelegatedViewController: DelegatedTableViewCellDelegate, UITableViewDelegate {

	func delegatedTableViewCellDidTapCopy(cell: DelegatedTableViewCell) {
		guard let indexPath = tableView.indexPath(for: cell),
			let key = viewModel.publicKey(for: indexPath.section) else {
			return
		}

		UIPasteboard.general.string = key
		BannerHelper.performCopiedNotification()
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 0 {
			return 20
		}
		return 24
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0.1
	}
}
