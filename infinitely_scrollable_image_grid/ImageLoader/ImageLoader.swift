//
//  ImageLoader.swift
//  infinitely_scrollable_image_grid
//
//  Created by Valeriia Fisenko on 02/03/2025.
//

import UIKit

enum ImageLoaderErrors: Error {
    case cannotLoadImage
    case cannotDecodeImage
}

protocol ImageLoader {
    func loadRandomImage(for key: String, size: Int) async throws -> UIImage
}

final class ImageLoaderImpl: ImageLoader {

    private let urlSession: URLSession
    private var imageCache: NSCache<NSString, PicsumImage>

    init(
        urlSession: URLSession = .shared,
        imageCache:NSCache<NSString, PicsumImage> = NSCache<NSString, PicsumImage>()
    ) {
        self.urlSession = urlSession
        self.imageCache = imageCache
    }

    func loadRandomImage(for key: String, size: Int) async throws -> UIImage {
        let nsKey = key as NSString
        let cachedImage: PicsumImage? = imageCache.object(forKey: nsKey)

        if let cachedImage, cachedImage.image.size.width >= CGFloat(size) {
            return cachedImage.image
        }

        let image = try await loadImage(byId: cachedImage?.id, size: size)
        imageCache.setObject(image, forKey: nsKey)

        return image.image
    }
}

// MARK: - Private
extension ImageLoaderImpl {

    private func loadImage(byId id: String? = nil, size: Int) async throws -> PicsumImage {
        guard let url = buildURL(id: id, size: size) else { throw ImageLoaderErrors.cannotLoadImage }

        let (data, urlResp) = try await urlSession.data(from: url)
        guard let image = UIImage(data: data) else { throw ImageLoaderErrors.cannotDecodeImage  }
        let imageId = (urlResp as? HTTPURLResponse)?.value(forHTTPHeaderField: "picsum-id")

        return PicsumImage(id: imageId, image: image)
    }

    private func buildURL(id: String?, size: Int) -> URL? {
        guard var url = URL(string: "https://picsum.photos") else { return nil }

        if let id = id {
            url.appendPathComponent("id")
            url.appendPathComponent("\(id)")
        }

        url.appendPathComponent("\(size)")

        return url
    }
}
