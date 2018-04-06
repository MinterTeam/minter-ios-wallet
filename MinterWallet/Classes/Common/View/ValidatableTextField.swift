//
//  ValidatableTextField.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 05/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class ValidatableTextField: UITextField {

	//MARK: -
	
	private let topPadding = CGFloat(10.0)
	private let leftPadding = CGFloat(16.0)
	
	private let validImageView = UIImageView(image: UIImage(named: "ValidIcon"))
	private let invalidImageView = UIImageView(image: UIImage(named: "InvalidIcon"))
	
	var rightViewValid: UIView?
	
	var rightViewInvalid: UIView?
	
	var prefixView: UIView?
	
	var prefixText: String? {
		didSet {
			
			guard prefixText != nil else { return }
			
			let prefixTopPadding = topPadding + 3.0
			
			let label = UILabel(frame: CGRect(x: leftPadding, y: prefixTopPadding, width: 32.0, height: 46.0))
			label.translatesAutoresizingMaskIntoConstraints = false
			label.font = UIFont.mediumFont(of: 16.0)
			label.text = prefixText
			prefixView = label
			
			leftView = label
			leftViewMode = .always
		}
	}

	//MARK: -
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		rightViewInvalid = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 30.0, height: 46.0))
		rightViewInvalid?.translatesAutoresizingMaskIntoConstraints = false
		invalidImageView.translatesAutoresizingMaskIntoConstraints = false
		rightViewInvalid?.addSubview(invalidImageView)
		rightViewInvalid?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[image(10)]", options: [], metrics: nil, views: ["image" : invalidImageView]))
		rightViewInvalid?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-18-[image(10)]", options: [], metrics: nil, views: ["image" : invalidImageView]))
		
		rightViewValid = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 30.0, height: 46.0))
		rightViewValid?.translatesAutoresizingMaskIntoConstraints = false
		validImageView.translatesAutoresizingMaskIntoConstraints = false
		rightViewValid?.addSubview(validImageView)
		rightViewValid?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[image(13)]", options: [], metrics: nil, views: ["image" : validImageView]))
		rightViewValid?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-18-[image(10)]", options: [], metrics: nil, views: ["image" : validImageView]))
		
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	override func editingRect(forBounds bounds: CGRect) -> CGRect {
		let newLeftPadding = leftPadding + CGFloat(prefixView?.bounds.width ?? 0)
		
		return CGRect(x: newLeftPadding, y: topPadding, width: bounds.width - leftPadding - leftPadding, height: bounds.height - topPadding - topPadding)
	}
	
	override func textRect(forBounds bounds: CGRect) -> CGRect {
		let newLeftPadding = leftPadding + CGFloat(prefixView?.bounds.width ?? 0)
		
		return CGRect(x: newLeftPadding, y: topPadding, width: bounds.width - leftPadding - leftPadding, height: bounds.height - topPadding - topPadding)
	}
	
	override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
		return CGRect(x: bounds.width - 30.0, y: 0, width: 30.0, height: bounds.height)
	}
	
	override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
		return CGRect(x: leftPadding, y: 0, width: prefixView?.bounds.width ?? 0, height: bounds.height)
	}
	
}

extension ValidatableTextField : UITextFieldDelegate {
	
	//MARK: - UITextField Delegate
	

	
}


