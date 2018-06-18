//
//  ValidatableCellProtocol.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import SwiftValidator

protocol ValidatableCellDelegate : class {
	
	func didValidateField(field: ValidatableCellProtocol)
	
	func validate(field: ValidatableCellProtocol, completion: (() -> ())?)
	
}


protocol ValidatableCellProtocol : Validatable where Self : BaseCell {
	
	var validateDelegate: ValidatableCellDelegate? { get set }
	
	var validator: Validator { get set }
	
	func setValid()
	
	func setInvalid(message: String?)
	
	func setDefault()	

}
