//
//  BaseCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift


protocol Configurable where Self : UITableViewCell {
	func configure(item: BaseCellItem)
}

typealias ConfigurableCell = UITableViewCell & Configurable


class BaseCell : ConfigurableCell {
	
	var disposeBag = DisposeBag()
	
	func configure(item: BaseCellItem) {}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		disposeBag = DisposeBag()
	}
	
}


class ExpandableCell : AccordionTableViewCell, Configurable {
	
	var disposeBag = DisposeBag()
	
	func configure(item: BaseCellItem) {}
	
	@IBOutlet weak var detailView: UIView?
	
	var expandable = true
	
	//MARK: -
	
	override func willSetExpanded(animated: Bool) {
		super.willSetExpanded(animated: animated)
		
		toggle(expanded, animated: true)
	}
	
	override func willSetCollapsed(animated: Bool) {
		super.willSetCollapsed(animated: animated)
		
		toggle(expanded, animated: true)
	}
	
	override func setExpanded(_ expanded: Bool, animated: Bool) {
		super.setExpanded(expanded, animated: animated)
	}
	
	func toggle(_ expanded: Bool, animated: Bool) {
		guard !expandable || detailView != nil else {
			return
		}
		
		if animated {
			let alwaysOptions: UIViewAnimationOptions = [.allowUserInteraction,
																									 .beginFromCurrentState,
																									 .transitionCrossDissolve]
			let expandedOptions: UIViewAnimationOptions = [.curveEaseInOut]
			let collapsedOptions: UIViewAnimationOptions = [.curveEaseInOut]
			let options = expanded ? alwaysOptions.union(expandedOptions) : alwaysOptions.union(collapsedOptions)
			
			UIView.transition(with: detailView!, duration: 0.4, options: options, animations: { [weak self] in
				self?.toggleCell()
			}, completion: nil)
		} else {
			toggleCell()
		}
	}
	
	// MARK: Helpers
	
	private func toggleCell() {
		detailView?.isHidden = expanded
		detailView?.alpha = expanded ? 0.0 : 1.0
		
		setNeedsLayout()
		layoutIfNeeded()
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		disposeBag = DisposeBag()
	}

}
