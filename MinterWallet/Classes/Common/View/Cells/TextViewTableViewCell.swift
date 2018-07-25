//
//  TextViewTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import SwiftValidator
import RxSwift


protocol TextViewTableViewCellDelegate: class {
	func heightDidChange(cell: TextViewTableViewCell)
}


class TextViewTableViewCellItem : BaseCellItem {
	
	var title: String?
	
	var rules: [Rule] = []
	
	var stateObservable: Observable<TextViewTableViewCell.State>?
	
	var isLoadingObservable: Observable<Bool>?
	
	var value: String?
	
	var keybordType: UIKeyboardType?
	
}


class TextViewTableViewCell : BaseCell, AutoGrowingTextViewDelegate {
	
	enum State {
		case `default`
		case valid
		case invalid(error: String)
	}
	
	//MARK: -
	
	weak var delegate: TextViewTableViewCellDelegate?
	
	weak var validateDelegate: ValidatableCellDelegate?

	//MARK: - IBOutlets
	
	@IBOutlet weak var title: UILabel!
	
	@IBOutlet weak var errorTitle: UILabel!
	
	@IBOutlet weak var textView: GrowingDefaultTextView! {
		didSet {
			textView.contentInset = UIEdgeInsets(top: 10, left: 16, bottom: 0, right: 20)
		}
	}
	
	var activityIndicator: UIActivityIndicatorView? {
		didSet {
			self.addSubview(activityIndicator!)
		}
	}
	
	var hasSetConstraints = false
	
	//MARK: -
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
		activityIndicator?.backgroundColor = .white
		activityIndicator?.translatesAutoresizingMaskIntoConstraints = false
		
//		textView.isScrollEnabled = false
		
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	//MARK: - BaseCell
	
	override func configure(item: BaseCellItem) {
		super.configure(item: item)
		
		if let item = item as? TextViewTableViewCellItem {
			self.title.text = item.title
			self.validatorRules = item.rules
			self.textView.text = item.value
			if let keyboard = item.keybordType {
				self.textView.keyboardType = keyboard
			}
			
			item.isLoadingObservable?.subscribe(onNext: { [weak self] (val) in
				if val {
					self?.activityIndicator?.startAnimating()
				}
				else {
					self?.activityIndicator?.stopAnimating()
				}
			}).disposed(by: disposeBag)
			
			item.stateObservable?.subscribe(onNext: { (stt) in
				
				switch stt {
				case .default:
					self.setDefault()
					break
					
				case .invalid(let err):
					self.setInvalid(message: err)
					break
					
				case .valid:
					self.setValid()
					break
				}
				
			}).disposed(by: disposeBag)
			
			textView?.rx.text.orEmpty.asObservable().subscribe(onNext: { (val) in
				self.validateDelegate?.validate(field: self, completion: {
					
				})
			}).disposed(by: disposeBag)
			
		}
	}
	
	func textViewDidChangeHeight(_ textView: AutoGrowingTextView, height: CGFloat) {
		delegate?.heightDidChange(cell: self)
	}
	
	//MARK: - Validate
	
	var validator = Validator()
	
	var validationText: String {
		return textView.text ?? ""
	}
	
	var validatorRules: [Rule] = [] {
		didSet {
			validator.registerField(self.textView, errorLabel: self.errorTitle, rules: validatorRules)
		}
	}
	
	//MARK: -
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if !hasSetConstraints {
			
			hasSetConstraints = true
			
			self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[activityIndicator(20)]-(20)-|", options: [], metrics: nil, views: ["activityIndicator" : activityIndicator!]))
			self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(37)-[activityIndicator(20)]", options: [], metrics: nil, views: ["activityIndicator" : activityIndicator!]))
			
			activityIndicator?.layoutIfNeeded()
			
		}
		
	}

}

extension TextViewTableViewCell : UITextViewDelegate {
	
	func textViewDidEndEditing(_ textView: UITextView) {
		

	}

}


extension TextViewTableViewCell : ValidatableCellProtocol {
	
	func setValid() {
		self.textView.layer.cornerRadius = 8.0
		self.textView.layer.borderWidth = 2
		self.textView.layer.borderColor = UIColor(hex: 0x4DAC4A)?.cgColor
		self.errorTitle.text = ""
	}
	
	func setInvalid(message: String?) {
		self.textView.layer.cornerRadius = 8.0
		self.textView.layer.borderWidth = 2
		self.textView.layer.borderColor = UIColor(hex: 0xEC373C)?.cgColor
		
		if nil != message {
			self.errorTitle.text = message
		}
	}
	
	func setDefault() {
		self.textView.layer.cornerRadius = 8.0
		self.textView.layer.borderWidth = 2
		self.textView.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		self.errorTitle.text = ""
	}
	
}
