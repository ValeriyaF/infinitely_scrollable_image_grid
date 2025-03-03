//
//  ImageTileView.swift
//  infinitely_scrollable_image_grid
//
//  Created by Valeriia Fisenko on 02/03/2025.
//

import UIKit

final class ImageTileView: UIView, ReusableView {

    private(set) var coordinates: Coordinates

    private let imageView = UIImageView()
    
    private let imageLoader: ImageLoader
    private var imageLoadTask: Task<Void, Error>?

    init(imageLoader: ImageLoader) {
        self.imageLoader = imageLoader
        coordinates = .init(x: 0, y: 0)

        super.init(frame: .zero)
        
        self.backgroundColor = UIColor.clear
        self.layer.borderWidth = 0.5
        self.layer.borderColor = .init(gray: 1, alpha: 0.5)
        
        setupSubviews()
    }
    
    func update(with frame: CGRect, coordinates: Coordinates) {
        self.coordinates = coordinates
        self.frame = frame

        loadImage(for: coordinates, size: Int(min(frame.width, frame.height)))
    }
    
    func loadImage(for coordinates: Coordinates, size: Int) {
        imageLoadTask?.cancel()
        imageLoadTask = Task {
            if let image = try? await imageLoader.loadRandomImage(for: coordinates.key, size: size) {
                imageView.image = image
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }
}

// MARK: Setup UI
extension ImageTileView {
    
    private func setupSubviews() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        imageView.backgroundColor = .gray
    }
}

// MARK: ReusableView
extension ImageTileView {
    
    func prepareForReuse() {
        imageLoadTask?.cancel()
        imageView.image = nil
        frame = .zero
        coordinates = Coordinates(x: 0, y: 0)
    }
}
