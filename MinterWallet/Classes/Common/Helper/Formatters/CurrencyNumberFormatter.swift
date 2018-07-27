//
//  CurrencyNumberFormatter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 28/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation


class CurrencyNumberFormatter : NumberFormatter {
	
	class var transactionFormatter : NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.decimalSeparator = "."
		formatter.groupingSeparator = " "
		formatter.plusSign = "+ "
		formatter.minusSign = "- "
		formatter.minimumFractionDigits = 2
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
		formatter.minimumFractionDigits = 2
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
		formatter.minimumFractionDigits = 2
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
		formatter.minimumFractionDigits = 2
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
