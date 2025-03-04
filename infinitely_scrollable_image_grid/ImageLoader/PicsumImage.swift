//
//  PicsumImage.swift
//  infinitely_scrollable_image_grid
//
//  Created by Valeriia Fisenko on 02/03/2025.
//

import UIKit

// NSCache requires reference semantics
final class PicsumImage {
    
    let id: String?
    let image: UIImage

    init(id: String?, image: UIImage) {
        self.id = id
        self.image = image
    }
}
