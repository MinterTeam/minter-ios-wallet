//
//  SwitchTableViewCell.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 16/04/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import UIKit
import RxSwift

class SwitchTableViewCellItem : BaseCellItem {
	
	var title: String = ""
	
	var isOn = Variable(false)
	
}

protocol SwitchTableViewCellDelegate : class {
	func didSwitch(isOn: Bool, cell: SwitchTableViewCell)
}


class SwitchTableViewCell: BaseCell {
	
	//MARK: - IBOutelet

	@IBOutlet weak var label: UILabel!
	
	@IBOutlet weak var `switch`: UISwitch!
	
	@IBAction func didSwitch(_ sender: UISwitch) {
		delegate?.didSwitch(isOn: sender.isOn, cell: self)
	}
	
	//MARK: -
	
	weak var delegate: SwitchTableViewCellDelegate?
	
	var disposeBag = DisposeBag()
	
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
		
		if let item = item as? SwitchTableViewCellItem {
			self.label.text = item.title
			self.switch.isOn = item.isOn.value
		}
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
//		self.label.text = ""
//		self.switch.isOn = false
	}

}
