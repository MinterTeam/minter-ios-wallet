//
//  AddressTextViewTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 29/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


class AddressTextViewTableViewCellItem : TextViewTableViewCellItem {}

protocol AddressTextViewTableViewCellDelegate : class {
	func didTapScanButton()
}


class AddressTextViewTableViewCell: TextViewTableViewCell {
	
	weak var addressDelegate: AddressTextViewTableViewCellDelegate?
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.textView.contentInset = UIEdgeInsets(top: self.textView.contentInset.top, left: self.textView.contentInset.left, bottom: self.textView.contentInset.bottom, right: 52)
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
    
	@IBOutlet weak var scanButton: UIButton!
	
	@IBAction func scanButtonDidTap(_ sender: Any) {
		addressDelegate?.didTapScanButton()
	}
	
	//MARK: -
	
	private var hasModifiedConstraints = false
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if !hasModifiedConstraints {
			
			hasModifiedConstraints = true
			
			self.constraints.forEach { (constraint) in
				
				if let _ = constraint.secondItem as? UIActivityIndicatorView, constraint.firstAttribute == NSLayoutAttribute.trailing {
					constraint.constant = 47
				}
			}
		}
	}
}
