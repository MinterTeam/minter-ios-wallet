//
//  SendPopupViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 18/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import AlamofireImage

protocol SendPopupViewControllerDelegate : class {
	func didFinish(viewController: SendPopupViewController)
	func didCancel(viewController: SendPopupViewController)
}


class SendPopupViewController: PopupViewController {
	
	//MARK: -
	
	weak var delegate: SendPopupViewControllerDelegate?
	
	//MARK: - IBOutlet
	
	@IBOutlet weak var amountTitle: UILabel!
	
	@IBOutlet weak var avatarImage: UIImageView! {
		didSet {
			avatarImage.backgroundColor = .white
			avatarImage.layer.cornerRadius = 25.0
		}
	}
	
	@IBOutlet weak var userLabel: UILabel!
	
	@IBOutlet weak var actionButton: DefaultButton!
	
	@IBOutlet weak var cancelButton: DefaultButton!
	
	@IBOutlet weak var acitionButtonActivityIndicator: UIActivityIndicatorView!
	
	@IBAction func secondButtonDidTap(_ sender: UIButton) {
		self.delegate?.didCancel(viewController: self)
	}
	
	@IBAction func didTapActionButton(_ sender: UIButton) {
		acitionButtonActivityIndicator?.startAnimating()
		acitionButtonActivityIndicator?.alpha = 1.0
		sender.isEnabled = false

		self.delegate?.didFinish(viewController: self)
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
		let cur = CurrencyNumberFormatter.coinFormatter.string(from: (sendViewModel?.amount ?? 0) as NSNumber) ?? ""
		amountTitle.text = String(cur + " " + (sendViewModel?.coin ?? "")).uppercased()
		avatarImage.image = UIImage(named: "AvatarPlaceholderImage")
		if let avatarURL = sendViewModel?.avatarImage {
			avatarImage.af_setImage(withURL: avatarURL, filter: RoundedCornersFilter(radius: 25.0))
		}
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
