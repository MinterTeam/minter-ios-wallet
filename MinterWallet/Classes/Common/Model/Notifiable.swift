//
//  Notifiable.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 20/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation

protocol Notifiable {
	var title: String? { get set }
	
	var text: String? { get set }
}


struct NotifiableError : Notifiable {
	
	var title: String?
	
	var text: String?
	
}

struct NotifiableSuccess : Notifiable {
	
	var title: String?
	
	var text: String?
	
}

