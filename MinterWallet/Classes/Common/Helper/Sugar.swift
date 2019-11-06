//
//  Sugar.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

// MARK: Array

extension Array {
	public subscript (safe index: Int) -> Element? {
		return indices ~= index ? self[index] : nil
	}
}

extension Array {
	subscript(safe range: Range<Index>) -> [Element]? {
		guard range.lowerBound >= self.startIndex else { return nil }
		guard range.upperBound <= self.endIndex else { return Array(self) }
		
		return Array(self[range])
	}
}

extension String {
	func base64Encoded() -> String? {
		return data(using: .utf8)?.base64EncodedString()
	}

	func base64Decoded() -> String? {
		var st = self;
		if (self.count % 4 <= 2){
			st += String(repeating: "=", count: (self.count % 4))
		}
		guard let data = Data(base64Encoded: st) else { return nil }
		return String(data: data, encoding: .utf8)
	}
}

extension String {

	func getKeyVals() -> [String: String]? {
		var results = [String: String]()
		var keyValues = self.split(separator: "&")
		if keyValues.count > 0 {
			for pair in keyValues {
				let kv = pair.split(separator: "=")
				if kv.count > 1 {
					results.updateValue(String(kv[1]), forKey: String(kv[0]))
				}
			}
		}
		return results
	}
}
