//
//  infinitely_scrollable_image_gridTests.swift
//  infinitely_scrollable_image_gridTests
//
//  Created by Valeriia Fisenko on 01/03/2025.
//

import XCTest
@testable import infinitely_scrollable_image_grid

final class ImageLoaderTests: XCTestCase {

    private var imageLoader: ImageLoaderImpl!
    private var sessionMock: URLSession!
    private var imageCacheMock: NSCache<NSString, PicsumImage>!

    override func setUp() {
        super.setUp()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        sessionMock = URLSession(configuration: config)
        imageCacheMock = NSCache<NSString, PicsumImage>()

        imageLoader = ImageLoaderImpl(urlSession: sessionMock, imageCache: imageCacheMock)
    }

    override func tearDown() {
        imageLoader = nil
        sessionMock = nil
        MockURLProtocol.requestHandler = nil
        imageCacheMock = nil
        super.tearDown()
    }

    func testLoadRandomImage_whenCacheHasLargerEnoughImage() async throws {
        // Given
        let key = "testKey"
        let image = UIImage(systemName: "pencil")!
        let picsumImage = PicsumImage(id: "123", image: image)
        imageCacheMock.setObject(picsumImage, forKey: key as NSString)

        // When
        let returnedImage = try await imageLoader.loadRandomImage(for: key, size: Int(image.size.width) / 2)

        // Then
        XCTAssertEqual(returnedImage, image, "Should return the cached image without a network call")
    }

    func testLoadRandomImage_whenCacheHasSmallerImage() async throws {
        // Given
        let key = "testKey"
        let picsumid = "999"
        let smallImage = UIImage(systemName: "pencil")!
        let picsumImage = PicsumImage(id: "123", image: smallImage)
        imageCacheMock.setObject(picsumImage, forKey: key as NSString)

        // Prepare a mocked network response
        let expectedNetworkImage = UIImage(systemName: "scribble")!
        let expectedNetworkData = expectedNetworkImage.pngData()!
        let expectedUrlResponse = HTTPURLResponse(
            url: URL(string: "https://picsum.photos/id/123/100")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["picsum-id": picsumid]
        )!

        MockURLProtocol.requestHandler = { request in
            return (expectedNetworkData, expectedUrlResponse)
        }

        // When
        let returnedImage = try await imageLoader.loadRandomImage(
            for: key,
            size: Int(smallImage.size.width) * 2
        )

        // Then
        XCTAssertEqual(returnedImage.ciImage, expectedNetworkImage.ciImage, "Should return the same image")

        // ensure cache is updated
        let cachedAfterCall = imageCacheMock.object(forKey: key as NSString)
        XCTAssertNotNil(cachedAfterCall, "Cache should be updated")
        XCTAssertEqual(cachedAfterCall?.id, picsumid, "Picsum ID should be updated from response header")
    }

    func testLoadRandomImage_noCache() async throws {
        // Given
        let key = "noCacheKey"
        let picsumid = "1"
        let testImage = UIImage(systemName: "circle")!
        let testData = testImage.pngData()!
        let response = HTTPURLResponse(
            url: URL(string: "https://picsum.photos/200")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["picsum-id": picsumid]
        )!

        MockURLProtocol.requestHandler = { request in
            return (testData, response)
        }

        // When
        let returnedImage = try await imageLoader.loadRandomImage(for: key, size: 200)

        // Then
        XCTAssertEqual(returnedImage.ciImage, testImage.ciImage)

        // ensure cache is updated
        let cachedAfterCall = imageCacheMock.object(forKey: key as NSString)
        XCTAssertNotNil(cachedAfterCall, "Cache should be updated")
        XCTAssertEqual(cachedAfterCall?.id, picsumid, "Picsum ID should be updated from response header")
    }

    func testLoadRandomImage_whenDataIsCorrupt() async {
        // Given
        let key = "decodeFailKey"
        let corruptData = Data([0x00, 0x01, 0x02]) // Not a valid image
        let response = HTTPURLResponse(
            url: URL(string: "https://picsum.photos/300")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        MockURLProtocol.requestHandler = { request in
            return (corruptData, response)
        }

        do {
            _ = try await imageLoader.loadRandomImage(for: key, size: 300)
            XCTFail("Expected cannotDecodeImage error")
        } catch let error as ImageLoaderErrors {
            XCTAssertEqual(error, .cannotDecodeImage)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // ensure cache is not updated
        let cachedAfterCall = imageCacheMock.object(forKey: key as NSString)
        XCTAssertNil(cachedAfterCall, "Cache should be empty")
    }
}
