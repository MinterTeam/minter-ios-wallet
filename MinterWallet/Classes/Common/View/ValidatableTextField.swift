//
//  ValidatableTextField.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 05/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import SwiftValidator


class ValidatableTextField: UITextField {

	//MARK: -
	
	var rightPadding = CGFloat(0)
	
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
		
		self.font = UIFont.mediumFont(of: 16.0)
		
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
	
	//MARK: -
	
	override func editingRect(forBounds bounds: CGRect) -> CGRect {
		let newLeftPadding = leftPadding + CGFloat(prefixView?.bounds.width ?? 0)
		
		return CGRect(x: newLeftPadding, y: topPadding, width: bounds.width - 2*leftPadding - rightPadding, height: bounds.height - 2*topPadding)
	}
	
	override func textRect(forBounds bounds: CGRect) -> CGRect {
		let newLeftPadding = leftPadding + CGFloat(prefixView?.bounds.width ?? 0)
		
		return CGRect(x: newLeftPadding, y: topPadding, width: bounds.width - 2*leftPadding - rightPadding, height: bounds.height - 2*topPadding)
	}
	
	override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
		return CGRect(x: bounds.width - 30.0, y: 0, width: 30.0, height: bounds.height)
	}
	
	override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
		return CGRect(x: leftPadding, y: 0, width: prefixView?.bounds.width ?? 0, height: bounds.height)
	}
	
	//MARK: -
	
	func setValid() {
		self.layer.cornerRadius = 8.0
		self.layer.borderWidth = 2
		self.layer.borderColor = UIColor(hex: 0x4DAC4A)?.cgColor
		self.rightViewMode = .always
	}
	
	func setInvalid() {
		self.layer.cornerRadius = 8.0
		self.layer.borderWidth = 2
		self.layer.borderColor = UIColor(hex: 0xEC373C)?.cgColor
		self.rightView = self.rightViewInvalid
		self.rightViewMode = .always
	}
	
	func setDefault() {
		self.layer.cornerRadius = 8.0
		self.layer.borderWidth = 2
		self.layer.borderColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		self.rightView = UIView()
		self.rightViewMode = .never
	}
	
	override func resignFirstResponder() -> Bool {
		let r = super.resignFirstResponder()
		self.layoutIfNeeded()
		return r
	}

}

extension ValidatableTextField : UITextFieldDelegate {
	
	//MARK: - UITextField Delegate
	
}


