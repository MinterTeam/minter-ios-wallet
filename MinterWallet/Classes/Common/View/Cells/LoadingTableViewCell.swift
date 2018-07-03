//
//  LoadingTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 30/06/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift


class LoadingTableViewCellItem : BaseCellItem {
	
	var isLoadingObservable: Observable<Bool>?
	
}


class LoadingTableViewCell: BaseCell {
	
	//MARK: - IBOutelet

	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	//MARK: -
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
	//MARK: - Configurable
	
	override func configure(item: BaseCellItem) {
		super.configure(item: item)
		
		if let item = item as? LoadingTableViewCellItem {
			
			item.isLoadingObservable?.distinctUntilChanged().subscribe(onNext: { [weak self] (val) in
				if val {
					self?.activityIndicator?.startAnimating()
				}
				else {
					self?.activityIndicator?.stopAnimating()
				}
			}).disposed(by: disposeBag)
			
		}
	}
    
}
