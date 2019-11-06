//
//  PINViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/06/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit
import RxSwift

protocol PINViewControllerDelegate: class {
	func PINViewControllerDidSucceed(controller: PINViewController, withPIN: String)
	func PINViewControllerDidSucceedWithBiometrics(controller: PINViewController)
}

class PINViewController: BaseViewController, ControllerType {

	typealias ViewModelType = PINViewModel
	var viewModel: PINViewModel!

	var disposeBag = DisposeBag()

	weak var delegate: PINViewControllerDelegate?

	// MARK: -

	func configure(with viewModel: PINViewModel) {
		viewModel.output.title.asDriver(onErrorJustReturn: "")
			.drive(onNext: { [weak self] (title) in
				self?.title = title
		}).disposed(by: disposeBag)

		viewModel.output.desc.asDriver(onErrorJustReturn: "")
			.drive(onNext: { [weak self] (desc) in
				self?.descTitle.text = desc
		}).disposed(by: disposeBag)

		self.rx.viewDidAppear.asDriver(onErrorJustReturn: false)
			.drive(viewModel.input.viewDidAppear).disposed(by: disposeBag)
	}

	// MARK: -

	@IBOutlet weak var descTitle: UILabel!
	@IBOutlet weak var pinView: CBPinEntryView! {
		didSet {
			pinView.delegate = self
		}
	}
	@IBOutlet weak var button1: UIButton!
	@IBOutlet weak var button2: UIButton!
	@IBOutlet weak var button3: UIButton!
	@IBOutlet weak var button4: UIButton!
	@IBOutlet weak var button5: UIButton!
	@IBOutlet weak var button6: UIButton!
	@IBOutlet weak var button7: UIButton!
	@IBOutlet weak var button8: UIButton!
	@IBOutlet weak var button9: UIButton!
	@IBOutlet weak var button0: UIButton!
	@IBAction func buttonTap(sender: UIButton) {
		let string = sender.title(for: .normal) ?? ""
		let range = NSRange(location: (pinView.textField.text ?? "").count, length: 1)
		if true == pinView.textField.delegate?.textField?(pinView.textField,
																											shouldChangeCharactersIn: range,
																											replacementString: string) {
			if #available(iOS 11.0, *) {
				pinView.textField.insertText(string)
			} else {
				pinView.textField.text = (pinView.textField.text ?? "") + string
				pinView.textField.sendActions(for: .editingChanged)
			}
		}
	}
	@IBAction func backspaceTap(_ sender: UIButton) {
		let string = sender.title(for: .normal) ?? ""
		let range = NSRange(location: max(0, (pinView.textField.text ?? "").count-1), length: 1)
		if true == pinView.textField.delegate?.textField?(pinView.textField,
																											shouldChangeCharactersIn: range,
																											replacementString: string) {
			if #available(iOS 11.0, *) {
				pinView.textField.deleteBackward()
			} else {
				let txt = (pinView.textField.text ?? "")
				pinView.textField.text = String(txt.dropLast())
				pinView.textField.sendActions(for: .editingChanged)
			}
		}
	}

	// MARK: -

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.title = "Set PIN-code".localized()

		configure(with: viewModel)

		viewModel.input.viewDidLoad.onNext(())

		pinView.becomeFirstResponder()
		pinView.textField.inputView = button0
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}

	func shakeError() {
		let animation = CABasicAnimation(keyPath: "position")
		animation.duration = 0.07
		animation.repeatCount = 4
		animation.autoreverses = true
		animation.fromValue = NSValue(cgPoint: CGPoint(x: pinView.center.x - 10,
																									 y: pinView.center.y))
		animation.toValue = NSValue(cgPoint: CGPoint(x: pinView.center.x + 10,
																								 y: pinView.center.y))
		pinView.layer.add(animation, forKey: "position")

		pinView.clearEntry()

		self.performHardImpact()
	}
}

extension PINViewController: CBPinEntryViewDelegate {

	func entryChanged(_ completed: Bool) {}

	func entryCompleted(with entry: String?) {
		delegate?.PINViewControllerDidSucceed(controller: self, withPIN: pinView.getPinAsString())
	}

}
