//
//  SendPopupViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 18/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

protocol SendPopupViewControllerDelegate : class {
	func didFinish(viewController: SendPopupViewController)
	func didCancel(viewController: SendPopupViewController)
}


class SendPopupViewController: PopupViewController {
	
	//MARK: -
	
	weak var delegate: SendPopupViewControllerDelegate?
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var amountTitle: UILabel!
	
	@IBOutlet weak var avatarImage: UIImageView!
	
	@IBOutlet weak var userLabel: UILabel!
	
	@IBOutlet weak var actionButton: DefaultButton!
	
	@IBOutlet weak var cancelButton: DefaultButton!
	
	@IBAction func secondButtonDidTap(_ sender: Any) {
		delegate?.didCancel(viewController: self)
		self.dismiss(animated: true) {
			
		}
	}
	
	@IBAction func didTapActionButton(_ sender: Any) {
		delegate?.didFinish(viewController: self)
		self.dismiss(animated: true) {
			
		}
	}
	
	//MARK: -
	
	var shadowLayer = CAShapeLayer()
	
	//MARK: -
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		hidesBottomBarWhenPushed = true
	}
	
	//MARK: -
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func loadView() {
		super.loadView()
		
		updateUI()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	//MARK: -
	
	private func updateUI() {
		
		let sendViewModel = viewModel as? SendPopupViewModel
		
		popupTitle.text = sendViewModel?.popupTitle
		amountTitle.text = String(sendViewModel?.amount ?? 0)
		avatarImage.image = sendViewModel?.avatarImage
		userLabel.text = sendViewModel?.username
		actionButton.setTitle(sendViewModel?.buttonTitle ?? "", for: .normal)
		cancelButton.setTitle(sendViewModel?.cancelTitle ?? "", for: .normal)
	}
	
	func dropShadow() {
		shadowLayer.removeFromSuperlayer()
		shadowLayer.frame = avatarImage.frame
		shadowLayer.path = UIBezierPath(roundedRect: avatarImage.bounds, cornerRadius: 25.0).cgPath
		shadowLayer.shadowOpacity = 1.0
		shadowLayer.shadowRadius = 18.0
		shadowLayer.masksToBounds = false
		shadowLayer.shadowColor = UIColor(hex: 0x000000, alpha: 0.2)?.cgColor
		shadowLayer.shadowOffset = CGSize(width: 2.0, height: 2.0)
		shadowLayer.opacity = 1.0
		shadowLayer.shouldRasterize = true
		shadowLayer.rasterizationScale = UIScreen.main.scale
		avatarImage.superview?.layer.insertSublayer(shadowLayer, at: 0)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		dropShadow()
	}

}
