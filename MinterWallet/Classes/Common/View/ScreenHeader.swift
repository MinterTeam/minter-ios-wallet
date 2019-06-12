//
//  ScreenHeader.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

protocol ScreenHeaderProtocol: class {
	var headerView: ScreenHeader? { get set }
	var tableHeaderTopConstraint: NSLayoutConstraint? { get set }
	var tableHeaderTopPadding: Double { get }

	func additionalUpdateHeaderViewFromScrollEvent(_ scrollView: UIScrollView)

}

class ScreenHeader: UIView {

	weak var delegate: ScreenHeaderProtocol?

	@objc dynamic var minHeight: CGFloat = 0//UIApplication.shared.statusBarFrame.size.height

	@IBInspectable
	dynamic var topConstraintAdditionPadding: CGFloat = 0.0

	fileprivate func defaultUpdateHeaderViewFromScrollEvent(with contentOffset: CGPoint) {

		guard let tableHeaderTopPadding = delegate?.tableHeaderTopPadding else {
			return
		}

		//если скролим вверх, то оставляем хедер неподвижным
		let staticPosition = -self.bounds.height - CGFloat(tableHeaderTopPadding) + topConstraintAdditionPadding
		if contentOffset.y <= staticPosition {
			delegate?.tableHeaderTopConstraint?.constant = staticPosition
		} else {
			//если скролим хедер вниз
			//значение констрейнта при оффсете меньше чем высота хедера
			let halfWayConstraint = -contentOffset.y - self.bounds.height - CGFloat(tableHeaderTopPadding) + topConstraintAdditionPadding
			//если скролим очень далеко, то скролим не дальше чем на высоту хедера + паддинга + высоты статус бара
			let farAwayConstant = -self.bounds.height - CGFloat(tableHeaderTopPadding) + minHeight
			let newConstant = min(halfWayConstraint, farAwayConstant)
			let oldConstant = delegate?.tableHeaderTopConstraint!.constant
			if newConstant != oldConstant {
				delegate?.tableHeaderTopConstraint?.constant = newConstant
			}
		}
	}

	func updateHeaderViewFromScrollEvent(_ scrollView: UIScrollView) {
		defaultUpdateHeaderViewFromScrollEvent(with: scrollView.contentOffset)
		delegate?.additionalUpdateHeaderViewFromScrollEvent(scrollView)
	}

}
