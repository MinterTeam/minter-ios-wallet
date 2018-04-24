//
//  SuperExpandableTableView.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 11/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import ExpandableCell

class SuperExpandableTableView : ExpandableTableView {
	
	weak var scrollViewDelegate: UIScrollViewDelegate?
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		scrollViewDelegate?.scrollViewDidScroll?(scrollView)
	}
	
	//Add more methods here
	
}
