//
//  BUttonTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 10/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift


protocol ButtonTableViewCellDelegate: class {
	func ButtonTableViewCellDidTap(_ cell: ButtonTableViewCell)
}


class ButtonTableViewCellItem : BaseCellItem {

	var title: String?
	
	var buttonPattern: String?
	
	var isButtonEnabled = true
	
	var isButtonEnabledObservable: Observable<Bool>?
	
	var isLoadingObserver: Observable<Bool>?

}


class ButtonTableViewCell: BaseCell {
	
	//MARK: -

	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	@IBOutlet weak var button: DefaultButton!
	
	//MARK: - IBActions
	
	@IBAction func buttonDidTap(_ sender: Any) {
		delegate?.ButtonTableViewCellDidTap(self)
	}
	
	//MARK: -
	
	weak var delegate: ButtonTableViewCellDelegate?
	
	//MARK: -
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	//MARK: -
	
	override func configure(item: BaseCellItem) {
		super.configure(item: item)
		
		if let buttonItem = item as? ButtonTableViewCellItem {
			button?.setTitle(buttonItem.title, for: .normal)
			button?.pattern = buttonItem.buttonPattern
			button?.isEnabled = buttonItem.isButtonEnabled
			activityIndicator?.isHidden = true
			
			buttonItem.isButtonEnabledObservable?.bind(to: button.rx.isEnabled).disposed(by: disposeBag)
			
			buttonItem.isLoadingObserver?.bind(onNext: { [weak self] (val) in
				
				var defaultState = buttonItem.isButtonEnabled
				
				self?.button?.isEnabled = defaultState//!val
				self?.activityIndicator?.isHidden = !val
				if val {
					self?.activityIndicator?.startAnimating()
					self?.button?.isEnabled = false
				}
				else {
					self?.activityIndicator?.stopAnimating()
//					self?.button?.isEnabled = defaultState
				}
			}).disposed(by: disposeBag)
			
		}
	}
    
}
