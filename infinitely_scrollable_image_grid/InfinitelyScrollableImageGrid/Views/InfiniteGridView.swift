//
//  InfiniteGridView.swift
//  infinitely_scrollable_image_grid
//
//  Created by Valeriia Fisenko on 01/03/2025.
//

import UIKit

final class InfiniteGridView: UIView {
    
    private weak var hostScrollView: UIScrollView?

    private(set) var referenceCoordinates: Coordinates = .init(x: 0, y: 0)
    private(set) var tileSize: CGFloat
    private(set) var centreCoordinates: Coordinates = .init(x: Int.max, y: Int.max)

    private var presentingViews: Set<ImageTileView> = []

    private let reuseQueue: ReuseQueue
    private let reuseViewIdentifier = "GridTile"

    private let imageLoader: ImageLoader

    private let screenSize = UIScreen.main.bounds.size

    init(
        hostScrollView: UIScrollView,
        imageLoader: ImageLoader,
        reuseQueue: ReuseQueue,
        tileSize: CGFloat
    ) {
        self.hostScrollView = hostScrollView
        self.imageLoader = imageLoader
        self.reuseQueue = reuseQueue
        self.tileSize = tileSize

        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initializeGrid(with gridOffset: CGFloat) {
        centerScrollViewContent(with: gridOffset)
        updateGridLayout()

        hostScrollView?.delegate = self
    }

    func updateGridLayout() {
        guard let scrollview = hostScrollView else { return }

        let centre = computedCentreCoordinates(scrollview)
        guard centre != centreCoordinates else { return }
        self.centreCoordinates = centre
        let xTilesRequired = Int(UIScreen.main.bounds.size.width / tileSize)
        let yTilesRequired = Int(UIScreen.main.bounds.size.height / tileSize)
        let lowerBoundX = centre.x - xTilesRequired
        let upperBoundX = centre.x + xTilesRequired
        let lowerBoundY = centre.y - yTilesRequired
        let upperBoundY = centre.y + yTilesRequired
        addTilesInVisibleBounds(lowerX: lowerBoundX, upperX: upperBoundX,
                                lowerY: lowerBoundY, upperY: upperBoundY)
        removeTilesOutsideVisibleBounds(lowerX: lowerBoundX, upperX: upperBoundX,
                                        lowerY: lowerBoundY, upperY: upperBoundY)
    }

    func zoom(with scale: CGFloat) {
        for view in presentingViews {
            view.removeFromSuperview()
        }
        presentingViews = []

        let newTileSize = tileSize * scale
        tileSize = newTileSize
        centreCoordinates = .init(x: Int.max, y: Int.max)

        updateGridLayout()
        realignTilePositionsToCenter()
    }
}

//MARK: - UIScrollViewDelegate
extension InfiniteGridView: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateGridLayout()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard decelerate == false else { return }
        self.realignTilePositionsToCenter()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.realignTilePositionsToCenter()
    }
}

// MARK: - Private
extension InfiniteGridView {

    private func centerScrollViewContent(with gridOffset: CGFloat) {
        guard let scrollview = hostScrollView else { return }

        let xOffset = gridOffset - ((scrollview.frame.size.width - self.frame.size.width) * 0.5)
        let yOffset = gridOffset - ((scrollview.frame.size.height - self.frame.size.height) * 0.5)
        scrollview.setContentOffset(CGPoint(x: xOffset, y: yOffset), animated: false)
    }

    private func addTilesInVisibleBounds(lowerX: Int, upperX: Int, lowerY: Int, upperY: Int) {
        let coordinatesSet: Set<Coordinates> = Set(presentingViews.map { $0.coordinates })

        var coordX = lowerX
        while coordX <= upperX {
            var coordY = lowerY
            while coordY <= upperY {
                if coordinatesSet.contains(Coordinates(x: coordX, y: coordY)) == false {
                    createTile(at: Coordinates(x: coordX, y: coordY))
                }
                coordY += 1
            }
            coordX += 1
        }
    }

    private func removeTilesOutsideVisibleBounds(lowerX: Int, upperX: Int, lowerY: Int, upperY: Int) {
        guard presentingViews.isEmpty == false else {
            return
        }

        for tile in presentingViews {
            let tileX = tile.coordinates.x
            let tileY = tile.coordinates.y
            if tileX < lowerX || tileX > upperX || tileY < lowerY || tileY > upperY {
                tile.prepareForReuse()
                reuseQueue.enqueueReusableView(tile, withIdentifier: reuseViewIdentifier)
                tile.removeFromSuperview()
            }
        }
    }

    private func createTile(at tileCoordinates: Coordinates) {
        let tile = (reuseQueue.dequeueReusableView(withIdentifier: reuseViewIdentifier) as? ImageTileView) ?? ImageTileView(imageLoader: imageLoader)
        tile.update(with: frameForTile(at: tileCoordinates), coordinates: tileCoordinates)
        presentingViews.insert(tile)

        self.addSubview(tile)
    }

    private func frameForTile(at coordinates: Coordinates) -> CGRect {
        let xIntOffset = coordinates.x - referenceCoordinates.x
        let yIntOffset = coordinates.y - referenceCoordinates.y
        let xOffset = self.bounds.size.width * 0.5 + (tileSize * (CGFloat(xIntOffset) - 0.5))
        let yOffset = self.bounds.size.height * 0.5 + (tileSize * (CGFloat(yIntOffset) - 0.5))
        return CGRect(x: xOffset, y: yOffset, width: tileSize, height: tileSize)
    }


    private func computedCentreCoordinates(_ scrollview: UIScrollView) -> Coordinates {
        let contentOffset = scrollview.contentOffset
        let scrollviewSize = scrollview.frame.size
        let xOffset = -(self.center.x - (contentOffset.x + scrollviewSize.width * 0.5))
        let yOffset = -(self.center.y - (contentOffset.y + scrollviewSize.height * 0.5))
        let xIntOffset = Int((xOffset / tileSize).rounded())
        let yIntOffset = Int((yOffset / tileSize).rounded())
        return Coordinates(x: xIntOffset + referenceCoordinates.x, y: yIntOffset + referenceCoordinates.y)
    }

    private func realignTilePositionsToCenter() {
        guard centreCoordinates != referenceCoordinates,
              let scrollview = hostScrollView else { return }
        let xOffset = CGFloat(centreCoordinates.x - referenceCoordinates.x) * tileSize
        let yOffset = CGFloat(centreCoordinates.y - referenceCoordinates.y) * tileSize
        referenceCoordinates = centreCoordinates
        for tile in presentingViews {
            var frame = tile.frame
            frame.origin.x -= xOffset
            frame.origin.y -= yOffset
            tile.frame = frame
        }
        var newContentOffset = scrollview.contentOffset
        newContentOffset.x -= xOffset
        newContentOffset.y -= yOffset
        scrollview.setContentOffset(newContentOffset, animated: false)
    }
}
