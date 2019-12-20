//
//  PassbookManager.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 19.12.2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation

let passbookAPIBaseURLString = Configuration().environment.passbookAPIURLString
let passbookPassId = Configuration().environment.passbookTypeString

enum PassbookManagerError: Error {
  case noURL
  case noPass
}

class PassbookManager {

  func pass(with address: String, completion: ((Data?, Error?) -> ())?) {

    guard let url = URL(string: passbookAPIBaseURLString + "passes/\(passbookPassId)/\(address)") else {
      completion?(nil, PassbookManagerError.noURL)
      return
    }

    var data: Data?
    var err: Error?

    DispatchQueue.global().async {

      defer {
        completion?(data, err)
      }

      do {
        data = try Data(contentsOf: url)
      } catch {
        err = PassbookManagerError.noPass
      }
    }
  }

}
