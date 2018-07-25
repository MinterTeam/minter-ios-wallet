//
//  UsernameView.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 23/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import AlamofireImage


class UsernameView: UIView {
	
	//MARK: -
	@IBOutlet weak var imageWrapperView: UIView!
	
	@IBOutlet weak var imageView: UIImageView!
	
	@IBOutlet weak var usernameLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
//		imageView.layer.cornerRadius = 13.0
		imageView.makeBorderWithCornerRadius(radius: 13, borderColor: .clear, borderWidth: 2)
	}
	
	//MARK: -
	
	func set(username: String?, image: UIImage?, placeholderImage: UIImage? = UIImage(named: "AvatarPlaceholder")) {
		self.usernameLabel.text = username
		self.imageView.image = placeholderImage
		
		if let image = image {
			self.imageView.image = image
		}
		else if let placeholder = placeholderImage {
			self.imageView.image = placeholder
		}
		
	}
	
	func set(username: String?, imageURL: URL?, placeholderImage: UIImage? = UIImage(named: "AvatarPlaceholder")) {
		self.usernameLabel.text = username
		imageView.image = placeholderImage
		
		if let imageURL = imageURL {
			imageView.af_setImage(withURL: imageURL, placeholderImage: placeholderImage, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.crossDissolve(0.3), runImageTransitionIfCached: false) { (response) in
				
			}
		}
	}
	
}
