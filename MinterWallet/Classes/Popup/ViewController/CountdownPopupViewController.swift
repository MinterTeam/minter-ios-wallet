//
//  CountdownPopupViewController.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import CountdownLabel

protocol CountdownPopupViewControllerDelegate : class {
	func didFinishCounting(viewController: CountdownPopupViewController)
}


class CountdownPopupViewController: PopupViewController {
	
	weak var delegate: CountdownPopupViewControllerDelegate?
	
	//MARK: - IBOutlets
	
	@IBOutlet weak var button: DefaultButton!
	
	@IBOutlet weak var desc1Label: UILabel!
	
	@IBOutlet weak var countdownLabel: CountdownLabel!
	
	@IBOutlet weak var desc2Label: UILabel!
	
	//MARK: -
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		updateUI()
		
		countdownLabel.setCountDownTime(minutes: 10)
		countdownLabel.timeFormat = "ss"
		countdownLabel.animationType = .Evaporate
		countdownLabel.start()
		
		countdownLabel.then(targetTime: 1) { [weak self] in
			self?.dismiss(animated: true, completion: {
				self?.delegate?.didFinishCounting(viewController: self!)
			})
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	//MARK: -
	
	func updateUI() {
		
		guard let vm = viewModel as? CountdownPopupViewModel else {
			return
		}
		
		button?.setTitle(vm.buttonTitle, for: .normal)
		desc1Label?.text = vm.desc1
		desc2Label?.text = vm.desc2
//		countdownLabel?.text = String(vm.count ?? 0)
		
	}
	
	//MARK: -
	
}
