//
//  ConfirmPopupViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 11/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import AlamofireImage
import RxSwift
import RxCocoa

protocol ConfirmPopupViewControllerDelegate : class {
	func didTapActionButton(viewController: ConfirmPopupViewController)
	func didTapSecondButton(viewController: ConfirmPopupViewController)
}

class ConfirmPopupViewController: PopupViewController, ControllerType {

	// MARK: -

	typealias ViewModelType = ConfirmPopupViewModel

	func configure(with viewModel: ConfirmPopupViewModel) {
		descLabel.text = viewModel.output.description

		viewModel
			.output
			.isActivityIndicatorAnimating
			.asDriver(onErrorJustReturn: false)
			.drive(onNext: { [weak self] (val) in
				self?.actionButton.isEnabled = !val
				self?.actionButtonActivityIndicator.alpha = val ? 1.0 : 0.0
				if val {
					self?.actionButtonActivityIndicator.startAnimating()
				} else {
					self?.actionButtonActivityIndicator.stopAnimating()
				}
		}).disposed(by: disposeBag)

		// Input
		actionButton
			.rx
			.tap
			.asDriver(onErrorJustReturn: ())
			.drive(viewModel.input.didTapAction)
			.disposed(by: disposeBag)

		secondButton
			.rx
			.tap
			.asDriver(onErrorJustReturn: ())
			.drive(viewModel.input.didTapCancel)
			.disposed(by: disposeBag)

	}

	weak var delegate: ConfirmPopupViewControllerDelegate?

	// MARK: - IBOutlet

	@IBOutlet weak var descLabel: UILabel!
	@IBOutlet weak var actionButtonActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var actionButton: DefaultButton!
	@IBOutlet weak var secondButton: DefaultButton!

	@IBAction func actionBtnDidTap(_ sender: Any) {
		delegate?.didTapActionButton(viewController: self)
	}

	@IBAction func secondButtonDidTap(_ sender: Any) {
		delegate?.didTapSecondButton(viewController: self)
	}

	// MARK: -

	var shadowLayer = CAShapeLayer()

	// MARK: -

	override func viewDidLoad() {
		super.viewDidLoad()
		if let confirmViewModel = viewModel as? ConfirmPopupViewModel {
			configure(with: confirmViewModel)
		}

		updateUI()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: -

	private func updateUI() {
		guard let vm = viewModel as? ConfirmPopupViewModel else {
			return
		}
		self.actionButton.setTitle(vm.buttonTitle, for: .normal)
		self.secondButton.setTitle(vm.cancelTitle, for: .normal)
	}
}
