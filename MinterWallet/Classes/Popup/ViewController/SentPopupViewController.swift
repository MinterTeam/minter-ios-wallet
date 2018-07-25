//
//  SentViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 30/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import AlamofireImage


protocol SentPopupViewControllerDelegate : class {
	func didTapActionButton(viewController: SentPopupViewController)
	func didTapSecondButton(viewController: SentPopupViewController)
}


class SentPopupViewController: PopupViewController {

	weak var delegate: SentPopupViewControllerDelegate?
	
	//MARK: -
	
	@IBOutlet weak var receiverLabel: UILabel!
	@IBOutlet weak var avatarImageView: UIImageView! {
		didSet {
			avatarImageView?.backgroundColor = .white
//			avatarImageView?.layer.cornerRadius = 25.0
			
			avatarImageView?.makeBorderWithCornerRadius(radius: 25, borderColor: .clear, borderWidth: 4)
			
		}
	}
	@IBOutlet weak var actionButton: DefaultButton!
	@IBOutlet weak var secondButton: DefaultButton!
	@IBOutlet weak var avatarWrapper: UIView! {
		didSet {
			avatarWrapper?.layer.cornerRadius = 25.0
			avatarWrapper?.layer.applySketchShadow(color: UIColor(hex: 0x000000, alpha: 0.2)!, alpha: 1, x: 0, y: 2, blur: 18, spread: 0)
		}
	}
	
	@IBAction func actionBtnDidTap(_ sender: Any) {
		delegate?.didTapActionButton(viewController: self)
	}
	
	@IBAction func secondButtonDidTap(_ sender: Any) {
		delegate?.didTapSecondButton(viewController: self)
	}
	
	//MARK: -
	
	var shadowLayer = CAShapeLayer()
	
	//MARK: -
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		updateUI()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	//MARK: -
	
	private func updateUI() {
		
		guard let vm = viewModel as? SentPopupViewModel else {
			return
		}
		
		self.receiverLabel.text = vm.username
		self.avatarImageView.image = UIImage(named: "AvatarPlaceholderImage")
		if let url = vm.avatarImage {
			self.avatarImageView.af_setImage(withURL: url, filter: RoundedCornersFilter(radius: 25.0))
		}
		self.actionButton.setTitle(vm.actionButtonTitle, for: .normal)
		self.secondButton.setTitle(vm.secondButtonTitle, for: .normal)
		
	}
	
	func dropShadow() {
		shadowLayer.removeFromSuperlayer()
		shadowLayer.frame = avatarImageView.frame
		shadowLayer.path = UIBezierPath(roundedRect: avatarImageView.bounds, cornerRadius: 25.0).cgPath
		shadowLayer.shadowOpacity = 1.0
		shadowLayer.shadowRadius = 18.0
		shadowLayer.masksToBounds = false
		shadowLayer.shadowColor = UIColor(hex: 0x000000, alpha: 0.2)?.cgColor
		shadowLayer.shadowOffset = CGSize(width: 2.0, height: 2.0)
		shadowLayer.opacity = 1.0
		shadowLayer.shouldRasterize = true
		shadowLayer.rasterizationScale = UIScreen.main.scale
		avatarImageView.superview?.layer.insertSublayer(shadowLayer, at: 0)
	}
	
	//MARK: -
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
//		dropShadow()
	}

}
