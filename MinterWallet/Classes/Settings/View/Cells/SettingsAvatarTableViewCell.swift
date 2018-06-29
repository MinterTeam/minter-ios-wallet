//
//  SettingsAvatarTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import AlamofireImage


protocol SettingsAvatarTableViewCellDelegate: class {
	func didTapChangeAvatar(cell: SettingsAvatarTableViewCell)
}


class SettingsAvatarTableViewCellItem : BaseCellItem {

	var avatar: UIImage?
	
	var avatarURL: URL?

}


class SettingsAvatarTableViewCell: BaseCell {
	
	weak var delegate: SettingsAvatarTableViewCellDelegate?
	
	var shadowLayer = CAShapeLayer()
	
	//MARK: -
	
	@IBAction func changeAvatarDidTap(_ sender: Any) {
		delegate?.didTapChangeAvatar(cell: self)
	}
	
	@IBOutlet weak var changeAvatarButton: DefaultButton!
	
	@IBOutlet weak var avatarImageView: UIImageView! {
		didSet {
			avatarImageView?.layer.cornerRadius = 25.0
			avatarImageView.superview?.layer.applySketchShadow(color: UIColor(hex: 0x000000, alpha: 0.2)!, alpha: 1, x: 0, y: 2, blur: 18, spread: 0)
			avatarImageView.makeBorderWithCornerRadius(radius: 25, borderColor: .white, borderWidth: 4)
		}
	}
	
	//MARK: -
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	//MARK: -
	
	override func configure(item: BaseCellItem) {
		super.configure(item: item)
		
		if let avatarItem = item as? SettingsAvatarTableViewCellItem {
			self.avatarImageView.image = avatarItem.avatar ?? UIImage(named: "AvatarPlaceholderImage")
			
			if nil == avatarItem.avatar, let url = avatarItem.avatarURL {
				let filter = RoundedCornersFilter(radius: 25.0)
				let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
				self.avatarImageView.af_setImage(withURLRequest: request, placeholderImage: UIImage(named: "AvatarPlaceholderImage"), filter: filter, progress: nil, progressQueue: DispatchQueue.main, imageTransition: .crossDissolve(0.3), runImageTransitionIfCached: false) { (response) in
					
					if let data = response.value {
						self.avatarImageView.image = data//UIImage(data: data)
					}
				}
			}
		}

	}
	
	//MARK: -
	
	func dropShadow() {
		
		shadowLayer.removeFromSuperlayer()
		shadowLayer.frame = avatarImageView.frame
		shadowLayer.path = UIBezierPath(roundedRect: CGRect(x: avatarImageView.bounds.origin.x, y: avatarImageView.bounds.origin.y, width: avatarImageView.bounds.width, height: avatarImageView.bounds.height), cornerRadius: 25.0).cgPath
		
//		shadowLayer.shadowOpacity = 1.0
//		shadowLayer.shadowRadius = 18.0
		shadowLayer.fillColor = UIColor.clear.cgColor
//		shadowLayer.masksToBounds = false
//		shadowLayer.shadowColor = UIColor(hex: 0x000000, alpha: 0.2)?.cgColor
//		shadowLayer.shadowOffset = CGSize(width: 2.0, height: 2.0)
//		shadowLayer.opacity = 1.0
//		shadowLayer.shouldRasterize = true
//		shadowLayer.rasterizationScale = UIScreen.main.scale
		shadowLayer.applySketchShadow(color: UIColor(hex: 0x000000, alpha: 1)!, alpha: 0.2, x: 0, y: 2, blur: 18, spread: 0)
		layer.insertSublayer(shadowLayer, at: 0)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
//		dropShadow()
	}

}
