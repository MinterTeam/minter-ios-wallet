//
//  BaseCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift
//import AEAccordion


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
	
	override func setExpanded(_ expanded: Bool, animated: Bool) {
		super.setExpanded(expanded, animated: animated)
		
		self.toggle(expanded, animated: animated)
	}
	
	override func willToggleCell(animated: Bool) {
		if !expanded {
			self.toggle(!expanded, animated: animated)
		}
	}
	
	override func didToggleCell(animated: Bool) {
		if !expanded {
			self.toggle(expanded, animated: animated)
		}
	}
	
	var toggling = false
	
	override func toggle(_ expanded: Bool, animated: Bool) {
		guard detailView != nil && !toggling else {
			return
		}
		
		toggling = true
		
		if animated {
			let alwaysOptions: UIViewAnimationOptions = [.allowUserInteraction,
																									 .beginFromCurrentState,
																									 .transitionCrossDissolve]
			let expandedOptions: UIViewAnimationOptions = [.curveEaseInOut]
			let collapsedOptions: UIViewAnimationOptions = [.curveEaseInOut]
			let options = expanded ? alwaysOptions.union(expandedOptions) : alwaysOptions.union(collapsedOptions)
			
			UIView.transition(with: detailView!, duration: 0.2, options: options, animations: { [weak self] in
				self?.toggleCell(expanded)
				}, completion: { (completed) in
					self.toggling = false
			})
		} else {
			toggleCell(expanded)
			toggling = false
		}
	}
	
	// MARK: Helpers
	
	private func toggleCell(_ val: Bool) {
		detailView?.isHidden = !val
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		disposeBag = DisposeBag()
	}

}
