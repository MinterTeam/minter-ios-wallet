//
//  GateManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 23/01/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import Alamofire


enum GateManagerError : Error {
	case wrongResponse
}

class GateManager {
	
	//MARK: -
	
	private init() {}
	
	static let shared = GateManager()
	
	//MARK: -
	
	func minGasPrice(completion: ((Int?, Error?) -> ())?) {
		
		Alamofire.request("https://gate.minter.network/api/v1/min-gas", method: .get, parameters: nil).responseJSON { (response) in
			if let resp = response.value as? [String : Any], let data = resp["data"] as? [String : Any], let gas = data["gas"] as? String, let gasInt = Int(gas) {
				completion?(gasInt, nil)
			}
			else {
				completion?(nil, GateManagerError.wrongResponse)
			}
		}
	}
	
}
