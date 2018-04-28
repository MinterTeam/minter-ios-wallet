//
//  DroppableView.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 26/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit


class DroppableView : CCMPlayNDropView {
	
	//MARK: -
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.shadowView = UIView(frame: self.frame)
	}
	
	//MARK: -
	
	var shadowView: UIView?
	
	var shadowLayer = CAShapeLayer()
	
	//MARK: -
	
	private func dropShadow() {
		
		shadowLayer.removeFromSuperlayer()
		shadowLayer.frame = self.bounds
		shadowLayer.path = UIBezierPath(roundedRect: CGRect(x: self.bounds.minX + 10, y: self.bounds.minY + 10, width: self.bounds.width - 20.0, height: self.bounds.height - 20.0), cornerRadius: 16.0).cgPath
		shadowLayer.shadowOpacity = 1.0
		shadowLayer.shadowRadius = 2.0
		shadowLayer.masksToBounds = false
		shadowLayer.shadowColor = UIColor(hex: 0x502EC2, alpha: 0.3)?.cgColor
		shadowLayer.shadowOffset = CGSize(width: 1.0, height: 2.0)
		shadowLayer.opacity = 1.0
		shadowLayer.shouldRasterize = true
		shadowLayer.rasterizationScale = UIScreen.main.scale
		
		self.layer.insertSublayer(shadowLayer, at: 0)
	}
	
	//MARK: -
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		dropShadow()
	}
	
	override func draggingStarted(_ gesture: UIPanGestureRecognizer) {
		super.draggingStarted(gesture)
		
//		shadowLayer.frame = self.frame
//		shadowLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 16.0).cgPath
		
//		print(self.frame)
		
	}
	
	override func draggingMoved(_ gesture: UIPanGestureRecognizer!) {
		super.draggingMoved(gesture)
		
//		shadowLayer.frame = self.frame
	}
	
}
