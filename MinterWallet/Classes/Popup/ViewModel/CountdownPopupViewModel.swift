//
//  CountdownPopupViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation


class CountdownPopupViewModel : PopupViewModel {
	
	var count: Int?
	
	var unit: (one: String, two: String, other: String)?
	
	var desc: String?
	
	var buttonTitle: String?
	
}
