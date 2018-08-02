//
//  AddressTextViewTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 29/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import NextGrowingTextView


class AddressTextViewTableViewCellItem : TextViewTableViewCellItem {}

protocol AddressTextViewTableViewCellDelegate : class {
	func didTapScanButton(cell: AddressTextViewTableViewCell1?)
}


//class AddressTextViewTableViewCell: TextViewTableViewCell {
//
//	weak var addressDelegate: AddressTextViewTableViewCellDelegate?
//
//	required init?(coder aDecoder: NSCoder) {
//		super.init(coder: aDecoder)
//	}
//
//	override func awakeFromNib() {
//		super.awakeFromNib()
//
//		self.textView.contentInset = UIEdgeInsets(top: self.textView.contentInset.top, left: self.textView.contentInset.left, bottom: self.textView.contentInset.bottom, right: 52)
//	}
//
//	override func setSelected(_ selected: Bool, animated: Bool) {
//		super.setSelected(selected, animated: animated)
//	}
//
//	@IBOutlet weak var scanButton: UIButton!
//
//	@IBAction func scanButtonDidTap(_ sender: Any) {
//		addressDelegate?.didTapScanButton(cell: self)
//	}
//
//	//MARK: -
//
//	private var hasModifiedConstraints = false
//
//	override func layoutSubviews() {
//		super.layoutSubviews()
//
//		if !hasModifiedConstraints {
//
//			hasModifiedConstraints = true
//
//			self.constraints.forEach { (constraint) in
//
//				if let _ = constraint.secondItem as? UIActivityIndicatorView, constraint.firstAttribute == NSLayoutAttribute.trailing {
//					constraint.constant = 47
//				}
//			}
//		}
//	}
//}

class AddressTextViewTableViewCell1: TextViewTableViewCell {
	
	var maxLength = 110
	
	override var textView: UITextView! {
		get {
			return textViewScroll.textView
		}
		set {}
	}

	@IBOutlet weak var textViewScroll: NextGrowingTextView! {
		didSet {
			self.textViewScroll.isScrollEnabled = false
			self.textViewScroll.textView.layer.cornerRadius = 8.0
			self.textViewScroll.textView.layer.borderWidth = 2
			self.textViewScroll.textView.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
			
			self.textViewScroll.textView.showsVerticalScrollIndicator = false
			self.textViewScroll.textView.showsHorizontalScrollIndicator = false
			
			self.textViewScroll.minNumberOfLines = 1
			self.textViewScroll.maxNumberOfLines = 100
			self.textViewScroll.textView.font = UIFont.mediumFont(of: 16.0)
			self.textViewScroll.textView.textContainerInset = UIEdgeInsetsMake(16, 10, 14, 60)
			
			textViewScroll.delegates.willChangeHeight = { [weak self] height in
				guard let `self` = self else { return }
				
				`self`.delegate?.heightDidChange(cell: `self`)
			}
			
			textViewScroll.delegates.didChangeHeight = { [weak self] height in
				guard let `self` = self else { return }
				
				`self`.delegate?.heightDidChange(cell: `self`)
			}
		}
	}
	
	weak var addressDelegate: AddressTextViewTableViewCellDelegate?
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		activityIndicator?.backgroundColor = .clear
		
		textViewScroll.textView.delegate = self
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	@IBOutlet weak var scanButton: UIButton!
	
	@IBAction func scanButtonDidTap(_ sender: Any) {
		addressDelegate?.didTapScanButton(cell: self)
	}
	
	//MARK: -
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		
		if text != "" && text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "" {
			return false
		}
		
		var txtAfterUpdate = textView.text ?? ""
		txtAfterUpdate = (txtAfterUpdate as NSString).replacingCharacters(in: range, with: text).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		
		if text.contains(UIPasteboard.general.string ?? "") {
			textViewScroll.layoutSubviews()
			return true
		}
		
		return true
	}
	
	override func textViewDidEndEditing(_ textView: UITextView) {
		validateDelegate?.didValidateField(field: self)
	}
	
}
