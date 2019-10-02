//
//  RawTransactionType+Helper.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 30/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterCore
import BigInt

extension RawTransactionType {

	static func type(with value: BigUInt) -> RawTransactionType? {
		let supported: [RawTransactionType] = [.sendCoin,
																					 .sellCoin,
																					 .sellAllCoins,
																					 .buyCoin,
																					 .createCoin,
																					 .declareCandidacy,
																					 .delegate,
																					 .unbond,
																					 .redeemCheck,
																					 .setCandidateOnline,
																					 .setCandidateOffline,
																					 .createMultisigAddress,
																					 .multisend,
																					 .editCandidate]

		for type in supported {
			if value == BigUInt(type.rawValue) {
				return type
			}
		}
		return nil
	}
}
