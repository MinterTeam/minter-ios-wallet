//
//  Sugar.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 04/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

//MARK: Array

extension Array {
	public subscript (safe index: Int) -> Element? {
		return indices ~= index ? self[index] : nil
	}
}
