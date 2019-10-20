//
//  AmountTextFieldTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 25/07/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift

class AmountTextFieldTableViewCellItem: TextFieldTableViewCellItem {

	// MARK: - I/O

	struct Input {
		var didTapUseMax: AnyObserver<Void>
	}
	struct Output {
		var didTapUseMax: Observable<Void>
	}
	var input: Input?
	var output: Output?

	// MARK: - Subjects

	private var didTapButtonSubject = PublishSubject<Void>()

	override init(reuseIdentifier: String, identifier: String) {
		super.init(reuseIdentifier: reuseIdentifier, identifier: identifier)

		input = Input(didTapUseMax: didTapButtonSubject.asObserver())
		output = Output(didTapUseMax: didTapButtonSubject.asObservable())
	}
}

protocol AmountTextFieldTableViewCellDelegate: class {
	func didTapUseMax()
}

class AmountTextFieldTableViewCell: TextFieldTableViewCell {

	// MARK: - IBOutlets

	@IBOutlet weak var useMaxButton: UIButton!
	@IBAction func didTapUseMax(_ sender: Any) {
		amountDelegate?.didTapUseMax()
	}

	// MARK: -

	weak var amountDelegate: AmountTextFieldTableViewCellDelegate?

	// MARK: - States

	override var state: State {
		didSet {
			switch state {

			case .valid:
				textField.layer.cornerRadius = 8.0
				textField.layer.borderWidth = 2
				textField.layer.borderColor = UIColor(hex: 0x4DAC4A)?.cgColor
				textField.rightView = textField.rightViewValid
				errorTitle.text = ""
				break

			case .invalid(let error):
				textField.layer.cornerRadius = 8.0
				textField.layer.borderWidth = 2
				textField.layer.borderColor = UIColor.mainRedColor().cgColor
				textField.rightView = textField.rightViewInvalid
				if nil != error {
					self.errorTitle.text = error
				}
				break

			default:
				textField.layer.cornerRadius = 8.0
				textField.layer.borderWidth = 2
				textField.layer.borderColor = UIColor.mainGreyColor(alpha: 0.4).cgColor
				textField.rightView = UIView()
				textField.rightViewMode = .never
				errorTitle.text = ""
				break
			}
		}
	}

	override func setInvalid(message: String?) {
		self.state = .invalid(error: message)

		if nil != message {
			self.errorTitle.text = message
		}
		self.textField.rightViewMode = .never
	}

	// MARK: - UITableViewCell

	override func awakeFromNib() {
		super.awakeFromNib()

		self.textField.rightPadding = CGFloat(self.useMaxButton.bounds.width)
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	// MARK: -

	override func configure(item: BaseCellItem) {
		super.configure(item: item)

		if let item = item as? AmountTextFieldTableViewCellItem {
			if let didTapUseMax = item.input?.didTapUseMax {
				useMaxButton
					.rx
					.tap
					.asDriver(onErrorJustReturn: ())
					.drive(didTapUseMax)
					.disposed(by: disposeBag)
			}

		}
	}
}
