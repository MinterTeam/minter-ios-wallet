//
//  AccordionTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 12/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

open class AccordionTableViewCell: UITableViewCell {
	
	// MARK: Properties
	
	/// Flag which tells if the cell is expanded.
	open private(set) var expanded = false
	
	// MARK: Actions
	
	/**
	Public setter of the `expanded` property (this should be overriden by a subclass for custom UI update)
	
	- parameter expanded: `true` if the cell should be expanded, `false` if it should be collapsed.
	- parameter animated: If `true` action should be animated.
	*/
	open func setExpanded(_ expanded: Bool, animated: Bool) {
		self.expanded = expanded
	}
	
	open func willSetExpanded(animated: Bool) {}
	
	open func willSetCollapsed(animated: Bool) {}
	
}
