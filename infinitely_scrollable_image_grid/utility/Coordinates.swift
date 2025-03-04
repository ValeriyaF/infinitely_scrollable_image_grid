//
//  Coordinates.swift
//  infinitely_scrollable_image_grid
//
//  Created by Valeriia Fisenko on 03/03/2025.
//

struct Coordinates {
    let x: Int
    let y: Int

    var key: String {
        "\(x),\(y)"
    }
}

extension Coordinates: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

extension Coordinates: Equatable {

    static func == (lhs: Coordinates, rhs: Coordinates) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}
