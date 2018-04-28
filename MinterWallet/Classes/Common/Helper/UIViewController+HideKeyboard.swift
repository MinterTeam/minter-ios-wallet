//
//  UIViewController+HideKeyboard.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 28/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


extension UIViewController {
	func hideKeyboardWhenTappedAround() {
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
		tap.cancelsTouchesInView = false
		view.addGestureRecognizer(tap)
	}
	
	@objc func dismissKeyboard() {
		view.endEditing(true)
	}
}
