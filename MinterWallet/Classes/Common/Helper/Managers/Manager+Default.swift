//
//  Manager+Default.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 22/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import MinterCore
import MinterExplorer
import MinterMy


public extension MinterExplorer.ExplorerTransactionManager {

	class var `default`: MinterExplorer.ExplorerTransactionManager {
		get {
			let httpClient = APIClient.shared
			let manager = self.init(httpClient: httpClient)
			return manager
		}
	}

}

public extension MinterExplorer.ExplorerAddressManager {
	
	class var `default`: MinterExplorer.ExplorerAddressManager {
		get {
			let httpClient = APIClient.shared
			let manager = self.init(httpClient: httpClient)
			return manager
		}
	}
}

public extension MinterMy.InfoManager {
	
	class var `default`: MinterMy.InfoManager {
		get {
			let httpClient = APIClient.shared
			let manager = self.init(httpClient: httpClient)
			return manager
		}
	}
	
}

public extension MinterExplorer.ExplorerCoinManager {
	class var `default`: MinterExplorer.ExplorerCoinManager {
		get {
			let httpClient = APIClient.shared
			let manager = self.init(httpClient: httpClient)
			return manager
		}
	}
}
