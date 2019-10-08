//
//  DashedView.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/10/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

class DashedView: UIView {
	
	var shapeLayer = CAShapeLayer()
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		shapeLayer.removeFromSuperlayer()

		shapeLayer.bounds = bounds
		shapeLayer.position = CGPoint(x: bounds.width/2, y: bounds.height/2)
		shapeLayer.fillColor = nil
		shapeLayer.strokeColor = UIColor(hex: 0x929292, alpha: 0.4)?.cgColor
		shapeLayer.lineWidth = 2.0
		shapeLayer.lineJoin = kCALineJoinRound
		shapeLayer.lineDashPattern = [3, 3]
		shapeLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 8.0).cgPath

		self.layer.addSublayer(shapeLayer)
	}

}
