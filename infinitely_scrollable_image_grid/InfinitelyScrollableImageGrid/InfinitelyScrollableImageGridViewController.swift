//
//  InfinitelyScrollableImageGridViewController.swift
//  infinitely_scrollable_image_grid
//
//  Created by Valeriia Fisenko on 01/03/2025.
//

import UIKit

enum Constants {
    static let initialTileSize: CGFloat = 100.0

    static let maxTileSize: CGFloat = UIScreen.main.bounds.size.height / 2.5
    static let minTileSize: CGFloat = UIScreen.main.bounds.size.height / 25.0
}

final class InfinitelyScrollableImageGridViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private let gridView: InfiniteGridView

    init(imageLoader: ImageLoader) {
        self.gridView = InfiniteGridView(
            hostScrollView: scrollView,
            imageLoader: imageLoader,
            reuseQueue: ReuseQueueImpl(),
            tileSize: Constants.initialTileSize
        )

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviews()
        setupGestureRecognizers()
    }
}

// MARK: Setup UI
extension InfinitelyScrollableImageGridViewController {
    
    private func setupSubviews() {
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.backgroundColor = .clear
        
        view.addSubview(scrollView)
        scrollView.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        let gridOffset = UIScreen.main.bounds.size.height * 100.0
        NSLayoutConstraint.activate([
            gridView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: gridOffset),
            gridView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: gridOffset),
            scrollView.trailingAnchor.constraint(equalTo: gridView.trailingAnchor, constant: gridOffset),
            scrollView.bottomAnchor.constraint(equalTo: gridView.bottomAnchor, constant: gridOffset),
        ])
        
        scrollView.setNeedsLayout()
        scrollView.layoutIfNeeded()
        
        gridView.initializeGrid(with: gridOffset)
    }

    private func setupGestureRecognizers() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        scrollView.addGestureRecognizer(pinchGesture)
    }
}

// MARK: - UIPinchGestureRecognizer
extension InfinitelyScrollableImageGridViewController {

    @objc func handlePinch(_ sender: UIPinchGestureRecognizer) {
        guard sender.state == .changed || sender.state == .ended else { return }

        let scale = sender.scale
        let currentTileSize = gridView.tileSize
        sender.scale = 1.0

        guard currentTileSize >= Constants.minTileSize && currentTileSize <= Constants.maxTileSize else {
            if currentTileSize < Constants.minTileSize {
                gridView.zoom(with: Constants.minTileSize / currentTileSize)
            } else if currentTileSize > Constants.maxTileSize {
                gridView.zoom(with: Constants.maxTileSize / currentTileSize)
            }

            showWarningAlert()
            return
        }

        gridView.zoom(with: scale)
    }

    private func showWarningAlert() {
        let alert = UIAlertController(
            title: "Warning",
            message: "Sorry, zoom scale is out of acceptable range",
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
