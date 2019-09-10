source 'https://github.com/Cocoapods/Specs'
use_frameworks!

platform :ios, '10.0'

def shared_pods
	pod 'MinterCore'
	pod 'MinterMy'
	pod 'MinterExplorer'
	pod 'Alamofire', '4.7.3'
	pod 'AlamofireImage', '3.4.1'
	pod 'RxSwift', '4.3.1'
	pod 'RxGesture'
	pod 'RxDataSources', '~> 3.0'
	pod 'RxAppState', '1.2.0'
	pod 'SwiftValidator', :git => 'https://github.com/jpotts18/SwiftValidator.git', :branch => 'master'
	pod 'TPKeyboardAvoiding', '~> 1.3'
	pod 'KeychainSwift', '12.0.0'
	pod 'RealmSwift', '3.11.0'
	pod 'AFDateHelper', '~> 4.2.2'
	pod 'NotificationBannerSwift', '1.8.0'
	pod 'Fabric', '~> 1.7'
	pod 'Crashlytics', '~> 3.10'
	pod 'ObjectMapper', '~> 3.3'
	pod 'XLPagerTabStrip', '~> 8.0'
	pod 'ReachabilitySwift', '~> 4.3'
	pod 'YandexMobileMetrica/Dynamic', '3.2.0'
	pod 'SwiftCentrifuge'
	pod 'GoldenKeystore', :git => 'https://github.com/sidorov-panda/GoldenKeystore'
	pod 'GrowingTextView'
end

target 'MinterWallet' do
	shared_pods
end

target 'MinterWalletTestnet' do
	shared_pods
end

target 'MinterWalletTests' do
	pod 'CryptoSwift'
	pod 'RxSwift', '4.3.1'
end
