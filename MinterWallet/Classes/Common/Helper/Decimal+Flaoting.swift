//
//  Decimal+Flaoting.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/12/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

extension Decimal.RoundingMode {
	init(_ rule: FloatingPointRoundingRule, for value: Decimal) {
		switch rule {
		case .down: self = .down
		case .up:   self = .up
			
		case .awayFromZero: self = value < 0 ? .down : .up
		case .towardZero:   self = value < 0 ? .up : .down
			
		case .toNearestOrAwayFromZero: self = .plain
		case .toNearestOrEven:         self = .bankers
		}
	}
}

extension Decimal {
	
	public mutating func round(_ rule: FloatingPointRoundingRule) {
		var original = self
		NSDecimalRound(&self, &original, 0, .init(rule, for: self))
	}
	
//	public mutating func formRemainder(dividingBy other: Decimal) {
//		let q = (self / other).rounded(.toNearestOrEven)
//		self -= other * q
//	}
	
	public mutating func formSquareRoot() {
		guard !isZero else { return }
		guard self > 0 else { self = .nan; return }
		
		var guess: Decimal = 1
		for _ in 0..<10 {
			guess = ((self / guess) + guess) / 2
		}
		
		self = guess
	}
	
	public mutating func addProduct(_ lhs: Decimal, _ rhs: Decimal) {
		self += lhs * rhs
	}
}
