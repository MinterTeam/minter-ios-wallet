//
//  ValidatableCellProtocol.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import SwiftValidator


protocol ValidatableCellProtocol : class, Validatable {
	
	var validator: Validator { get set }
	
	func setValid()
	
	func setInvalid()
	
	func setDefault()
}
