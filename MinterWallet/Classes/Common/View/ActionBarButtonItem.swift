//
//  ActionBarButtonItem.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 23/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit

class ActionBarButtonItem: UIBarButtonItem {

	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.setTitleTextAttributes([
			NSAttributedStringKey.font: UIFont.boldFont(of: 14),
			NSAttributedStringKey.foregroundColor: UIColor.white
		], for: .normal)
		
		self.setTitleTextAttributes([
			NSAttributedStringKey.font: UIFont.boldFont(of: 14),
			NSAttributedStringKey.foregroundColor: UIColor.white
		], for: .selected)
	}


}
