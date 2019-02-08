//
//  BaseViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 02/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation


protocol ViewModelProtocol {
	associatedtype Input
	associatedtype Output
	
	var input: Input! { get }
	var output: Output! { get }
}


class BaseViewModel {

	
	
}
