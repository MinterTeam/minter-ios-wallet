//
//  ShadowView.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class ShadowView: UIView {
	
	//MARK: -
	
	var shadowLayer = CAShapeLayer()
	
	//MARK: -
	
	private func dropShadow() {

		shadowLayer.removeFromSuperlayer()
		shadowLayer.frame = self.frame
		shadowLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 16.0).cgPath
		shadowLayer.shadowOpacity = 1.0
		shadowLayer.shadowRadius = 2.0
		shadowLayer.masksToBounds = false
		shadowLayer.shadowColor = UIColor(hex: 0x502EC2, alpha: 0.3)?.cgColor
		shadowLayer.shadowOffset = CGSize(width: 1.0, height: 2.0)
		shadowLayer.opacity = 1.0
		shadowLayer.shouldRasterize = true
		shadowLayer.rasterizationScale = UIScreen.main.scale
		self.superview?.layer.insertSublayer(shadowLayer, at: 0)
	}
	
	//MARK: -
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		dropShadow()
	}

}
