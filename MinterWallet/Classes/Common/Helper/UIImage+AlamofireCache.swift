//
//  UIImage+AlamofireCache.swift
//  MinterWallet
//
//  Created by Alexey Sidorov on 10/09/2018.
//  Copyright © 2018 Minter. All rights reserved.
//

import Foundation
import AlamofireImage

extension UIImageView {
	
	func af_setImageIgnoreCache(string: String?) {
		guard let url = string, let nsurl = URL(string: url) else { return }
		let urlRequest = URLRequest(url: nsurl, cachePolicy: .reloadIgnoringCacheData)
		
		let imageDownloader = ImageDownloader.default
		if let imageCache = imageDownloader.imageCache as? AutoPurgingImageCache, let urlCache = imageDownloader.sessionManager.session.configuration.urlCache {
			_ = imageCache.removeImages(matching: urlRequest)
			urlCache.removeCachedResponse(for: urlRequest)
		}
		
		af_setImage(withURLRequest: urlRequest)
	}
	
}
