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

class SettingsAvatarTableViewCellItem: BaseCellItem {
	var avatar: UIImage?
	var avatarURL: URL?
}

class SettingsAvatarTableViewCell: BaseCell {

	weak var delegate: SettingsAvatarTableViewCellDelegate?

	var shadowLayer = CAShapeLayer()

	// MARK: -

	@IBAction func changeAvatarDidTap(_ sender: Any) {
		delegate?.didTapChangeAvatar(cell: self)
	}
	@IBOutlet weak var changeAvatarButton: DefaultButton!
	@IBOutlet weak var avatarImageView: UIImageView! {
		didSet {
			let color = UIColor(hex: 0x000000, alpha: 0.2)!
			avatarImageView
				.superview?
				.layer
				.applySketchShadow(color: color, alpha: 1, x: 0, y: 2, blur: 18, spread: 0)
			avatarImageView.makeBorderWithCornerRadius(radius: 25,
																								 borderColor: .clear,
																								 borderWidth: 4)
		}
	}

	// MARK: -

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}

	// MARK: -

	override func configure(item: BaseCellItem) {
		super.configure(item: item)

		if let avatarItem = item as? SettingsAvatarTableViewCellItem {
			self.avatarImageView.image = avatarItem.avatar ?? UIImage(named: "AvatarPlaceholderImage")

			if nil == avatarItem.avatar, let url = avatarItem.avatarURL {
				let filter = RoundedCornersFilter(radius: 25.0)
				let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
				self.avatarImageView.af_setImage(withURLRequest: request,
																				 placeholderImage: UIImage(named: "AvatarPlaceholderImage"),
																				 filter: filter,
																				 progress: nil,
																				 progressQueue: DispatchQueue.main,
																				 imageTransition: .crossDissolve(0.3),
																				 runImageTransitionIfCached: false) { (response) in
					if let data = response.value {
						self.avatarImageView.image = data//UIImage(data: data)
					}
				}
			}
		}
	}

	// MARK: -

	override func layoutSubviews() {
		super.layoutSubviews()
	}
}
