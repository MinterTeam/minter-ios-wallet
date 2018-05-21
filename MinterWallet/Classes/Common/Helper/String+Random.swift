//
//  String+Random.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation


extension String {
	
	static func random(length: Int = 20) -> String {
		let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		var randomString: String = ""
		
		for _ in 0..<length {
			let randomValue = arc4random_uniform(UInt32(base.count))
			randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
		}
		return randomString
	}
}
