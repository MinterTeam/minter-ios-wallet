//
//  ReceiveRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 06/08/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation


class ReceiveRouter : BaseRouter {

	static var patterns: [String] {
		return ["receive"]
	}

	static func viewController(path: [String], param: [String : Any]) -> UIViewController? {
		return Storyboards.Receive.instantiateInitialViewController()
	}
	
	//MARK: -
	
	static func activityViewController(activities: [Any], sourceView: UIView) -> UIViewController {
		let vc = UIActivityViewController(activityItems: activities, applicationActivities: [])
		vc.popoverPresentationController?.sourceView = sourceView
		return vc
	}

}
