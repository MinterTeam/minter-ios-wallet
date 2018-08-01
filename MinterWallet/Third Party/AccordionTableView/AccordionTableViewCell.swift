
/**
*  https://github.com/tadija/AEAccordion
*  Copyright (c) Marko Tadić 2015-2018
*  Licensed under the MIT license. See LICENSE file.
*/

import UIKit

open class AccordionTableViewCell: UITableViewCell {
	
	// MARK: Properties
	
	/// Flag which tells if the cell is expanded.
	open private(set) var expanded = false
	
	open var toggling = false
	
	// MARK: Actions
	
	/**
	Public setter of the `expanded` property (this should be overriden by a subclass for custom UI update)
	
	- parameter expanded: `true` if the cell should be expanded, `false` if it should be collapsed.
	- parameter animated: If `true` action should be animated.
	*/
	open func setExpanded(_ expanded: Bool, animated: Bool) {
		self.expanded = expanded
	}

	open func willToggleCell(animated: Bool) {}
	
	open func didToggleCell(animated: Bool) {}
	
	func toggle(_ expanded: Bool, animated: Bool) {}
	
}
