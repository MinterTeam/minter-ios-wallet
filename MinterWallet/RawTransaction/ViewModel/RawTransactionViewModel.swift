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
		var errorNotification: Observable<NotifiableError?>
		var successNotification: Observable<NotifiableSuccess?>
	}

	var input: RawTransactionViewModel.Input!
	var output: RawTransactionViewModel.Output!

	// MARK: -

	private var cancelButtonDidTapSubject = PublishSubject<Void>()
	private var errorNotificationSubject = PublishSubject<NotifiableError?>()
	private var successNotificationSubject = PublishSubject<NotifiableSuccess?>()
	private var sendButtonDidTapSubject = PublishSubject<Void>()
	private var sectionsSubject = PublishSubject<[BaseTableSectionItem]>()
	private var sendingTxSubject = PublishSubject<Bool>()

	// MARK: -

	private var nonce: BigUInt?
	private var payload: String?
	private var type: RawTransactionType
	private var gasPrice: BigUInt?
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
	private let noMantissaFormatter = CurrencyNumberFormatter.decimalShortNoMantissaFormatter

	// MARK: -

	init(
		nonce: BigUInt?,
		gasPrice: BigUInt?,
		gasCoin: String?,
		type: RawTransactionType,
		data: Data?,
		payload: String?,
		serviceData: Data?,
		signatureType: Data?
	) {
		self.type = type
		self.gasPrice = gasPrice
		self.gasCoin = gasCoin ?? Coin.baseCoin().symbol!
		self.nonce = nonce

		super.init()

		self.payload = payload
		self.data = data
		if let data = data,
			let txData = RLP.decode(data),
			let content = txData[0]?.content {
			switch content {
			case .list(let items, _, _):
				switch type {
				case .sendCoin:
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
				}
				case .sellCoin:
					fields.append(["key": "TYPE".localized(), "value": "SELL COIN"])
					if let coinFromData = items[0].data,
						let coinFrom = String(data: coinFromData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let valueData = items[1].data,
						let coinToData = items[2].data,
						let coinTo = String(data: coinToData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let minimumValueToBuyData = items[2].data {
							let minimumValueToBuy = BigUInt(minimumValueToBuyData)
							let value = BigUInt(valueData)
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: value) ?? 0).PIPToDecimal(),
																																					formatter: decimalFormatter)
							fields.append(["key": "COIN FROM".localized(), "value": coinFrom])
							fields.append(["key": "AMOUNT".localized(), "value": amountString])
							fields.append(["key": "COIN TO".localized(), "value": coinTo])
					}
					break
				case .sellAllCoins:
					fields.append(["key": "TYPE".localized(), "value": "SELL ALL"])
					if let coinFromData = items[0].data,
						let coinFrom = String(data: coinFromData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let coinToData = items[1].data,
						let coinTo = String(data: coinToData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let minimumValueToBuyData = items[2].data {
//							let minimumValueToBuy = BigUInt(minimumValueToBuyData)
							fields.append(["key": "COIN FROM".localized(), "value": coinFrom])
							fields.append(["key": "COIN TO".localized(), "value": coinTo])
					}
					break
				case .buyCoin:
					fields.append(["key": "TYPE".localized(), "value": "BUY COIN"])
					if let coinFromData = items[0].data,
						let coinFrom = String(data: coinFromData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let valueData = items[1].data,
						let coinToData = items[2].data,
						let coinTo = String(data: coinToData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let maximumValueToBuyData = items[2].data {
							let maximumValueToBuy = BigUInt(maximumValueToBuyData)
							let value = BigUInt(valueData)
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: value) ?? 0).PIPToDecimal(),
																																					formatter: decimalFormatter)
							fields.append(["key": "COIN FROM".localized(), "value": coinFrom])
							fields.append(["key": "AMOUNT".localized(), "value": amountString])
							fields.append(["key": "COIN TO".localized(), "value": coinTo])
					}
					break
				case .createCoin:
					fields.append(["key": "TYPE".localized(), "value": "CREATE COIN"])
					if let coinNameData = items[0].data,
						let coinName = String(data: coinNameData, encoding: .utf8),
						let coinSymbolData = items[1].data,
						let coinSymbol = String(data: coinSymbolData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let initialAmountData = items[2].data,
						let initialReserveData = items[3].data,
						let constantReserveRatioData = items[4].data {
							let initialAmount = BigUInt(initialAmountData)
							let initialReserve = BigUInt(initialReserveData)
							let crr = BigUInt(constantReserveRatioData)
							let initialAmountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: initialAmount) ?? 0).PIPToDecimal(),
																																								 formatter: decimalFormatter)
							let initialReserveString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: initialReserve) ?? 0).PIPToDecimal(),
																																									formatter: decimalFormatter)
							let crrString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: crr) ?? 0),
																																			 formatter: noMantissaFormatter)
							fields.append(["key": "COIN NAME".localized(), "value": coinName])
							fields.append(["key": "COIN SYMBOL".localized(), "value": coinSymbol])
							fields.append(["key": "INITIAL AMOUNT".localized(), "value": initialAmountString])
							fields.append(["key": "INITIAL RESERVE".localized(), "value": initialReserveString])
							fields.append(["key": "CONSTANT RESERVE RATIO".localized(), "value": crrString])
					}
					break
				case .declareCandidacy:
					fields.append(["key": "TYPE".localized(), "value": "DECLARE CANDIDACY".localized()])
					if
						let addressData = items[0].data,
						let publicKeyData = items[1].data,
						let commissionData = items[2].data,
						let coinData = items[3].data,
						let coin = String(data: coinData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let stakeData = items[4].data {
							let commission = BigUInt(commissionData)
							let commissionString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: commission) ?? 0),
																																							formatter: noMantissaFormatter)
						
							let stake = BigUInt(stakeData)
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
																																					formatter: decimalFormatter)
							fields.append(["key": "ADDRESS".localized(), "value": "Mx" + addressData.toHexString()])
							fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])
							fields.append(["key": "COMMISSION".localized(), "value": commissionString])
							fields.append(["key": "COIN".localized(), "value": coin])
							fields.append(["key": "STAKE".localized(), "value": amountString])
					}
					break
				case .delegate:
					fields.append(["key": "TYPE".localized(), "value": "DELEGATE".localized()])
					if
						let publicKeyData = items[0].data,
						let coinData = items[1].data,
						let coin = String(data: coinData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let stakeData = items[2].data {
							let stake = BigUInt(stakeData)
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
																																					formatter: decimalFormatter)
							fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])
							fields.append(["key": "COIN".localized(), "value": coin])
							fields.append(["key": "AMOUNT".localized(), "value": amountString])
					}
					break
				case .unbond:
					fields.append(["key": "TYPE".localized(), "value": "UNBOND".localized()])
					if
						let publicKeyData = items[0].data,
						let coinData = items[1].data,
						let coin = String(data: coinData, encoding: .utf8)?
							.replacingOccurrences(of: "\0", with: ""),
						let stakeData = items[2].data {
							let stake = BigUInt(stakeData)
							let amountString = CurrencyNumberFormatter.formattedDecimal(with: (Decimal(bigInt: stake) ?? 0).PIPToDecimal(),
																																					formatter: decimalFormatter)
							fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])
							fields.append(["key": "COIN".localized(), "value": coin])
							fields.append(["key": "AMOUNT".localized(), "value": amountString])
					}
					break
				case .redeemCheck:
					fields.append(["key": "TYPE".localized(), "value": "REDEEM CHECK".localized()])
					if
						let checkData = items[0].data,
						let proofData = items[1].data {
						fields.append(["key": "CHECK".localized(), "value": "Mc" + checkData.toHexString()])
						fields.append(["key": "PROOF".localized(), "value": proofData.toHexString()])
					}
					break
				case .setCandidateOnline:
					fields.append(["key": "TYPE".localized(), "value": "SET CANDIDATE ON".localized()])
					if let publicKeyData = items[0].data {
						fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])
					}
					break
				case .setCandidateOffline:
					fields.append(["key": "TYPE".localized(), "value": "SET CANDIDATE OFF".localized()])
					if let publicKeyData = items[0].data {
						fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])
					}
					break
				case .createMultisigAddress:
					break
				case .multisend:
					if let arrayData = items[0].data,
						let array = RLP.decode(arrayData) {
						for i in 0..<(array.count ?? 0) {
							if let addressDictData = array[i]?.data,
							let addressDict = RLP.decode(addressDictData),
								let coinData = addressDict[0]?.data,
									let coin = String(data: coinData, encoding: .utf8)?
										.replacingOccurrences(of: "\0", with: ""),
									let addressData = addressDict[1]?.data,
									let valueData = addressDict[2]?.data {
										let address = addressData.toHexString()
										let value = BigUInt(valueData)
										let amount = (Decimal(bigInt: value) ?? 0).PIPToDecimal()
										let amountString = CurrencyNumberFormatter.formattedDecimal(with: amount,
																																					formatter: decimalFormatter)
										let sendingValue = amountString + " " + coin
										fields.append(["key": "YOU'RE sending".localized(), "value": sendingValue])
										fields.append(["key": "TO".localized(), "value": "Mx" + address])
								}
						}
					}
					break
				case .editCandidate:
					fields.append(["key": "TYPE".localized(), "value": "EDIT CANDIDATE".localized()])
					if let publicKeyData = items[0].data,
						let rewardAddressData = items[1].data,
						let ownerAddressData = items[2].data {
							fields.append(["key": "PUBLIC KEY".localized(), "value": "Mp" + publicKeyData.toHexString()])
							fields.append(["key": "REWARD ADDRESS".localized(), "value": "Mx" + rewardAddressData.toHexString()])
							fields.append(["key": "OWNDER ADDRESS".localized(), "value": "Mx" + ownerAddressData.toHexString()])
					}
					break
				}
				break
			case .noItem: break
			case .data(_): break
			}
			if let gasCoin = gasCoin {
				fields.append(["key": "GAS COIN".localized(), "value": gasCoin])
			}
			if let payload = payload, payload.count > 0 {
				fields.append(["key": "PAYLOAD MESSAGE".localized(), "value": payload])
			}
		}

		self.input = Input()
		self.output = Output(sections: sectionsSubject.asObservable(),
												 shouldClose: cancelButtonDidTapSubject.asObservable(),
												 errorNotification: errorNotificationSubject.asObservable(),
												 successNotification: successNotificationSubject.asObservable())

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

				let gasPrice = (self?.gasPrice != nil) ? self!.gasPrice! : BigUInt(try self?.currentGas.value() ?? RawTransactionDefaultGasPrice)
				let resultNonce = (self?.nonce != nil) ? self!.nonce! : nnnc

				let tx = RawTransaction(nonce: resultNonce,
																gasPrice: gasPrice,
																gasCoin: gasCoin,
																type: BigUInt(type.rawValue),
																data: self?.data ?? Data(),
																payload: self?.payload?.data(using: .utf8) ?? Data())

				let signedTx = RawTransactionSigner.sign(rawTx: tx, privateKey: privateKey)
				return GateManager.shared.send(rawTx: signedTx)
			}).subscribe(onNext: { [weak self] (result) in
				self?.successNotificationSubject.onNext(NotifiableSuccess(title: "Tx has been sent \(result ?? "")"))
				self?.cancelButtonDidTapSubject.onNext(())
				Session.shared.loadTransactions()
				Session.shared.loadBalances()
				Session.shared.loadDelegatedBalance()
				self?.sendingTxSubject.onNext(false)
			}, onError: { [weak self] (error) in
				self?.sendingTxSubject.onNext(false)
				self?.handle(error: error)
			}).disposed(by: disposeBag)
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

	private func handle(error: Error) {
		var notification: NotifiableError
		if let error = error as? HTTPClientError {
			if let errorMessage = error.userData?["log"] as? String {
				notification = NotifiableError(title: "An Error Occurred".localized(),
																			 text: errorMessage)
			} else {
				notification = NotifiableError(title: "An Error Occurred".localized(),
																			 text: "Unable to send transaction".localized())
			}
		} else {
			notification = NotifiableError(title: "An Error Occurred".localized(),
																		 text: "Unable to send transaction".localized())
		}
		self.errorNotificationSubject.onNext(notification)
	}
}
