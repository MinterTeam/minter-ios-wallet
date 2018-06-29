//
//  CALayer+Shadow.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 21/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

extension CALayer {
	func applySketchShadow(
		color: UIColor = .black,
		alpha: Float = 0.5,
		x: CGFloat = 0,
		y: CGFloat = 2,
		blur: CGFloat = 4,
		spread: CGFloat = 0)
	{
		shadowColor = color.cgColor
		shadowOpacity = alpha
		shadowOffset = CGSize(width: x, height: y)
		shadowRadius = blur / 2.0
		if spread == 0 {
			shadowPath = nil
		} else {
			let dx = -spread
			let rect = bounds.insetBy(dx: dx, dy: dx)
			shadowPath = UIBezierPath(rect: rect).cgPath
		}
	}
}

protocol CornerRadius {
	func makeBorderWithCornerRadius(radius: CGFloat, borderColor: UIColor, borderWidth: CGFloat)
}

extension UIView: CornerRadius {

	func makeBorderWithCornerRadius(radius: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
		let rect = self.bounds;
		
		let maskPath = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: radius, height: radius))
		
		// Create the shape layer and set its path
		let maskLayer = CAShapeLayer()
		maskLayer.frame = rect
		maskLayer.path  = maskPath.cgPath
		
		// Set the newly created shape layer as the mask for the view's layer
		self.layer.mask = maskLayer
		
		//Create path for border
		let borderPath = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: radius, height: radius))
		
		// Create the shape layer and set its path
		let borderLayer = CAShapeLayer()
		
		borderLayer.frame       = rect
		borderLayer.path        = borderPath.cgPath
		borderLayer.strokeColor = borderColor.cgColor
		borderLayer.fillColor   = UIColor.clear.cgColor
		borderLayer.lineWidth   = borderWidth * UIScreen.main.scale
		
		//Add this layer to give border.
		self.layer.insertSublayer(borderLayer, at: 1)
	}
	
}
