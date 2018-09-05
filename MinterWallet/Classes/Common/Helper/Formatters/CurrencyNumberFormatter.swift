//
//  CurrencyNumberFormatter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 28/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation


class CurrencyNumberFormatter : NumberFormatter {
	
	class func formattedDecimal(with number: Decimal, formatter: NumberFormatter) -> String {
		
		let newNF = formatter.copy() as! NumberFormatter
		let amount = number
		for _ in 0...18 {
			
			defer {
				newNF.maximumFractionDigits += 1
			}
			
			guard let str = newNF.string(from: amount as NSNumber) else {
				continue
			}
			
			let lh = CurrencyNumberFormatter.decimal(from: str) ?? 0
			if abs(lh) < 1 {
				let count = number.significantFractionalDecimalDigits
				newNF.minimumFractionDigits = max(4, min(8, count))
				newNF.roundingMode = .up
				let l0Str = newNF.string(from: number as NSNumber) ?? ""
				
				if let newDecimal = CurrencyNumberFormatter.decimal(from: l0Str) {
					if newDecimal == 0 {
						continue
					}
				}
				
				return l0Str
			}
			if lh != Decimal(0.0) {
				return newNF.string(from: lh as NSNumber) ?? ""
			}
		}
		
		if amount == 0 {
			return "0.0000"
		}
		
		return formatter.string(from: amount as NSNumber) ?? ""
	}
	
	class func decimal(from formattedString: String) -> Decimal? {
		let str = formattedString.replacingOccurrences(of: " ", with: "")
		return Decimal(string: str)
	}
	
	
	class var transactionFormatter : NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.decimalSeparator = "."
		formatter.groupingSeparator = " "
		formatter.plusSign = "+ "
		formatter.minusSign = "- "
		formatter.minimumFractionDigits = 4
		formatter.maximumFractionDigits = 4
		formatter.positivePrefix = formatter.plusSign
		formatter.roundingMode = .down
		return formatter
	}
	
	class var coinFormatter : NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.decimalSeparator = "."
		formatter.groupingSeparator = " "
		formatter.plusSign = ""
		formatter.minusSign = ""
		formatter.minimumFractionDigits = 4
		formatter.maximumFractionDigits = 4
		formatter.positivePrefix = formatter.plusSign
		formatter.roundingMode = .down
		return formatter
	}
	
	class var decimalFormatter: NumberFormatter {
		let formatter = NumberFormatter()
		formatter.generatesDecimalNumbers = true
		formatter.decimalSeparator = "."
		formatter.generatesDecimalNumbers = true
		formatter.minimumFractionDigits = 4
		formatter.maximumFractionDigits = 100
		formatter.minimumIntegerDigits = 1
		formatter.maximumIntegerDigits = 1000
		formatter.roundingMode = .down
		return formatter
	}
	
	class var decimalShortFormatter: NumberFormatter {
		let formatter = NumberFormatter()
		formatter.generatesDecimalNumbers = true
		formatter.decimalSeparator = "."
		formatter.generatesDecimalNumbers = true
		formatter.minimumFractionDigits = 4
		formatter.maximumFractionDigits = 4
		formatter.minimumIntegerDigits = 1
		formatter.maximumIntegerDigits = 1000
		formatter.roundingMode = .down
		return formatter
	}
	
	class var decimalShortNoMantissaFormatter: NumberFormatter {
		let formatter = NumberFormatter()
		formatter.generatesDecimalNumbers = true
		formatter.decimalSeparator = "."
		formatter.generatesDecimalNumbers = true
		formatter.minimumFractionDigits = 0
		formatter.maximumFractionDigits = 4
		formatter.minimumIntegerDigits = 1
		formatter.maximumIntegerDigits = 1000
		formatter.roundingMode = .down
		return formatter
	}
	
}
