//
//  TransactionManager+Default.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 22/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer


public extension MinterExplorer.TransactionManager {

	class var `default`: MinterExplorer.TransactionManager {
		get {
			let httpClient = APIClient.shared
			let manager = self.init(httpClient: httpClient)
			return manager
		}
	}

}
