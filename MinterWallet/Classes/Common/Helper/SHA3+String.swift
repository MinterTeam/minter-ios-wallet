//
//  SHA3+String.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 03/05/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import CryptoSwift


class SHA3Helper {
	
	class func hashString(from: String) -> String? {
		let mnemonicHash = SHA3(variant: .keccak256).calculate(for: from.data(using: .utf8)!.bytes)
		
		return String(data: Data(bytes: mnemonicHash), encoding: .utf8)
	}
	
}

//extension String {
//	public func sha256() -> String {
//		return bytes.sha256().toHexString()
//	}
//}
