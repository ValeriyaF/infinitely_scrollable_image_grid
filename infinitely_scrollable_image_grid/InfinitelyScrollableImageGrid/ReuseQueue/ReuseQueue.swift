//
//  ReuseQueue.swift
//  infinitely_scrollable_image_grid
//
//  Created by Valeriia Fisenko on 02/03/2025.
//

import UIKit

protocol ReuseQueue {

    func dequeueReusableView(withIdentifier identifier: String) -> UIView?
    func enqueueReusableView(_ view: UIView, withIdentifier identifier: String)
}

final class ReuseQueueImpl: ReuseQueue {

    private var reusePool: [String: [UIView]] = [:]

    func dequeueReusableView(withIdentifier identifier: String) -> UIView? {
        guard var views = reusePool[identifier], views.isEmpty == false else {
            return nil
        }

        let view = views.removeLast()
        reusePool[identifier] = views
        return view
    }

    func enqueueReusableView(_ view: UIView, withIdentifier identifier: String) {
        reusePool[identifier, default: []].append(view)
    }
}
