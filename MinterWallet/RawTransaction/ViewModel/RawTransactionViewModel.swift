//
//  RawTransactionViewModel.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 24/09/2019.
//  Copyright © 2019 Minter. All rights reserved.
//

import Foundation
import MinterCore
import BigInt
import RxSwift

class RawTransactionViewModel: BaseViewModel, ViewModelProtocol {

	// MARK: -

	enum cellIdentifierPrefix: String {
		case fee = "TwoTitleTableViewCell_TransactionFee"
		case separator = "SeparatorTableViewCell"
		case blank = "BlankTableViewCell"
		case button = "ButtonTableViewCell_send"
		case cancelButton = "ButtonTableViewCell_cancel"
	}

	// MARK: - ViewModelProtocol

	struct Input {}
	struct Output {
		var sections: Observable<[BaseTableSectionItem]>
		var shouldClose: Observable<Void>
	}

	var input: RawTransactionViewModel.Input!
	var output: RawTransactionViewModel.Output!

	// MARK: -

	private var cancelButtonDidTapSubject = PublishSubject<Void>()
	private var sendButtonDidTapSubject = PublishSubject<Void>()
	private var sectionsSubject = PublishSubject<[BaseTableSectionItem]>()
	private var sendingTxSubject = PublishSubject<Bool>()

	// MARK: -

	private var payload: String?
	private var type: RawTransactionType
	private var gasCoin: String
	private var data: Data?

	private let accountManager = AccountManager()
	private var fields: [[String: String]] = []
	private var currentGas = BehaviorSubject<Int>(value: RawTransactionDefaultGasPrice)
	private var gasObservable: Observable<String> {
		return currentGas.asObservable()
			.map({ [weak self] (obj) -> String in
				let payloadData = self?.payload?.data(using: .utf8)
				return self?.comissionText(for: obj, payloadData: payloadData) ?? ""
		})
	}
	private let coinFormatter = CurrencyNumberFormatter.coinFormatter
	private let decimalFormatter = CurrencyNumberFormatter.decimalFormatter

	// MARK: -

	init(gasCoin: String,
			 type: RawTransactionType,
			 data: Data?,
			 payload: String?,
			 serviceData: Data?,
			 signatureType: Data?) {

		self.type = type
		self.gasCoin = gasCoin

		super.init()

		self.payload = payload
		self.data = data

		switch type {
		case .sendCoin:
			if let data = data,
				let txData = RLP.decode(data),
				let content = txData[0]?.content {
				switch content {
				case .list(let items, _, _):
					if let coinData = items[0].data,
						let coin = String(data: coinData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let addressData = items[1].data,
						let valueData = items[2].data {
							let address = addressData.toHexString()
							let value = BigUInt(valueData)
							let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: amount,
																																		formatter: decimalFormatter)

							let sendingValue = amountString + " " + coin

							fields.append(["key": "YOU'RE sending".localized(), "value": sendingValue])
							fields.append(["key": "TO".localized(), "value": "Mx" + address])
							if let payload = payload {
								fields.append(["key": "PAYLOAD MESSAGE".localized(), "value": payload])
							}
					}
					break
				case .noItem: break
				case .data(_): break
				}
			}
		case .sellCoin:
			break
		case .sellAllCoins:
			break
		case .buyCoin:
			break
		case .createCoin:
			break
		case .declareCandidacy:
			break
		case .delegate:
			break
		case .unbond:
			break
		case .redeemCheck:
			break
		case .setCandidateOnline:
			break
		case .setCandidateOffline:
			break
		case .createMultisigAddress:
			break
		case .multisend:
			break
		case .editCandidate:
			break
		}

		self.input = Input()
		self.output = Output(sections: sectionsSubject.asObservable(),
												 shouldClose: cancelButtonDidTapSubject.asObservable())

		sendButtonDidTapSubject.subscribe(onNext: { [weak self] (_) in
			self?.sendTx()
		}).disposed(by: disposeBag)

		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
			self.sectionsSubject.onNext(self.createSections())
		}
	}

	private func sendTx() {
		guard let address = Session.shared.accounts.value.first?.address else {
			return
		}

		Observable.combineLatest(GateManager.shared.nonce(address: "Mx" + address),
														 GateManager.shared.minGas())
			.do(onNext: { [weak self] (result) in
				self?.sendingTxSubject.onNext(false)
			}, onError: { [weak self] error in
					print(error)
			}, onSubscribe: { [weak self] in
				self?.sendingTxSubject.onNext(true)
			}).flatMap({ [weak self] (result) -> Observable<String?> in
				let (nonce, _) = result
				guard let nnnc = BigUInt(decimal: Decimal(nonce+1)),
					let gasCoin = self?.gasCoin,
					let type = self?.type,
					let mnemonic = self?.accountManager.mnemonic(for: address),
					let seed = self?.accountManager.seed(mnemonic: mnemonic),
					let privateKey = try self?.accountManager.privateKey(from: seed).raw.toHexString()
					else {
						return Observable.empty()
				}

				let tx = RawTransaction(nonce: nnnc,
																type: BigUInt(type.rawValue),
																gasCoin: gasCoin,
																data: self?.data ?? Data(),
																payload: self?.payload?.data(using: .utf8) ?? Data())

				let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: privateKey)
				return GateManager.shared.send(rawTx: signedTx)
			}).subscribe().disposed(by: disposeBag)
	}

	// MARK: - Sections

	private func createSections() -> [BaseTableSectionItem] {
		var items = [RawTransactionFieldTableViewCellItem]()
		for field in fields {
			let item = RawTransactionFieldTableViewCellItem(reuseIdentifier: "RawTransactionFieldTableViewCell",
																											identifier: "RawTransactionFieldTableViewCell_" + String.random())
			item.title = field["key"]
			item.value = field["value"]
			items.append(item)
		}

		let fee = TwoTitleTableViewCellItem(reuseIdentifier: "TwoTitleTableViewCell",
																				identifier: cellIdentifierPrefix.fee.rawValue)
		fee.title = "Transaction Fee".localized()
		let payloadData = payload?.data(using: .utf8)
		fee.subtitle = self.comissionText(for: 1, payloadData: payloadData)
		fee.subtitleObservable = self.gasObservable

		let separator = SeparatorTableViewCellItem(reuseIdentifier: "SeparatorTableViewCell",
																							 identifier: cellIdentifierPrefix.separator.rawValue)

		let blank = BlankTableViewCellItem(reuseIdentifier: "BlankTableViewCell",
																			 identifier: cellIdentifierPrefix.blank.rawValue)

		let button = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																				 identifier: cellIdentifierPrefix.button.rawValue)
		button.title = "CONFIRM AND SEND".localized()
		button.buttonPattern = "purple"
		button.output?.didTapButton
			.asDriver(onErrorJustReturn: ())
			.drive(sendButtonDidTapSubject.asObserver())
			.disposed(by: disposeBag)
		button.isLoadingObserver = sendingTxSubject.asObservable()

		let cancelButton = ButtonTableViewCellItem(reuseIdentifier: "ButtonTableViewCell",
																							 identifier: cellIdentifierPrefix.cancelButton.rawValue)
		cancelButton.title = "CANCEL".localized()
		cancelButton.buttonPattern = "blank"
		cancelButton.output?.didTapButton
			.asDriver(onErrorJustReturn: ())
			.drive(cancelButtonDidTapSubject.asObserver())
			.disposed(by: disposeBag)

		var section = BaseTableSectionItem(header: "")
		section.items = items + [fee, separator, blank, button, cancelButton]
		return [section]
	}

	private func comissionText(for gas: Int, payloadData: Data? = nil) -> String {
		let payloadCom = Decimal((payloadData ?? Data()).count) * RawTransaction.payloadByteComissionPrice.decimalFromPIP()
		let commission = (self.type.commission() + payloadCom).PIPToDecimal() * Decimal(gas)
		let balanceString = CurrencyNumberFormatter.formattedDecimal(with: commission,
																																 formatter: coinFormatter)
		return balanceString + " " + (Coin.baseCoin().symbol ?? "")
	}
}
