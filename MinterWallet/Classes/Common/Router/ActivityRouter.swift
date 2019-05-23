//
//  ActivityRouter.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 21/05/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import UIKit

class ActivityRouter: BaseRouter {

	static var patterns: [String] = []

	static func viewController(path: [String], param: [String : Any]) -> UIViewController? {
		return nil
	}

	static func activityViewController(activities: [Any], sourceView: UIView) -> UIViewController {
		let vc = UIActivityViewController(activityItems: activities, applicationActivities: [])
		vc.popoverPresentationController?.sourceView = sourceView
		return vc
	}

}
