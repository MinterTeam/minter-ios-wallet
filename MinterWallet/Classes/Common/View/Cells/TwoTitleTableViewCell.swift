//
//  TwoTitleTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift


class TwoTitleTableViewCellItem : BaseCellItem {
	
	var title: String?
	
	var subtitle: String?
	
	var subtitleObservable: Observable<String>?
	
}


class TwoTitleTableViewCell: BaseCell {

	//MARK: -
	
	@IBOutlet weak var label: UILabel!
	
	@IBOutlet weak var sublabel: UILabel!
	
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

		if let item = item as? TwoTitleTableViewCellItem {
			label.text = item.title
			sublabel.text = item.subtitle

			item.subtitleObservable?.asDriver(onErrorJustReturn: "").drive(sublabel.rx.text).disposed(by: disposeBag)

		}
	}

}
