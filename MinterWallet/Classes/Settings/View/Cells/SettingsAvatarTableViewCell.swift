//
//  SettingsAvatarTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


class SettingsAvatarTableViewCellItem : BaseCellItem {
	
	var avatar: UIImage?
	
}



class SettingsAvatarTableViewCell: BaseCell {
	
	var shadowLayer = CAShapeLayer()

	//MARK: -
	
	@IBOutlet weak var avatarImageView: UIImageView! {
		didSet {
			
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
		}
	}
	
	//MARK: -
	
	func dropShadow() {
		shadowLayer.removeFromSuperlayer()
		shadowLayer.frame = avatarImageView.frame
		shadowLayer.path = UIBezierPath(roundedRect: avatarImageView.bounds, cornerRadius: 17.0).cgPath
		shadowLayer.shadowOpacity = 1.0
		shadowLayer.shadowRadius = 18.0
		shadowLayer.masksToBounds = false
		shadowLayer.shadowColor = UIColor(hex: 0x000000, alpha: 0.2)?.cgColor
		shadowLayer.shadowOffset = CGSize(width: 5.0, height: 5.0)
		shadowLayer.opacity = 1.0
		shadowLayer.shouldRasterize = true
		shadowLayer.rasterizationScale = UIScreen.main.scale
		layer.insertSublayer(shadowLayer, at: 0)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		dropShadow()
	}

}
