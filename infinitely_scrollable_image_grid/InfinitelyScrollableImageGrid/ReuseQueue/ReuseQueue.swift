//
//  ReuseQueue.swift
//  infinitely_scrollable_image_grid
//
//  Created by Valeriia Fisenko on 02/03/2025.
//

import UIKit

protocol ReuseQueue {

    func createView(_ view: UIView, withIdentifier identifier: String)
    func removeAll(withIdentifier identifier: String)
    func allocatedViews(withIdentifier identifier: String) -> [UIView]

    func dequeueReusableView(withIdentifier identifier: String) -> UIView?
    func enqueueReusableView(_ view: UIView, withIdentifier identifier: String)
}

final class ReuseQueueImpl: ReuseQueue {

    private var reusePool: [String: [UIView]] = [:]
    private var presentingViews: [String: [UIView]] = [:]

    func createView(_ view: UIView, withIdentifier identifier: String) {
        presentingViews[identifier, default: []].append(view)
    }

    func removeAll(withIdentifier identifier: String) {
        for view in (presentingViews[identifier] ?? []) {
            view.removeFromSuperview()
        }
        presentingViews[identifier] = []
//        reusePool[identifier] = []
    }

    func allocatedViews(withIdentifier identifier: String) -> [UIView] {
        presentingViews[identifier] ?? []
    }

    func dequeueReusableView(withIdentifier identifier: String) -> UIView? {
        guard var views = reusePool[identifier], views.isEmpty == false else {
            return nil
        }

        let view = views.removeLast()
        reusePool[identifier] = views
        return view
    }

    func enqueueReusableView(_ view: UIView, withIdentifier identifier: String) {
        if let reusableView = view as? ReusableView {
            reusableView.prepareForReuse()
        }

        reusePool[identifier, default: []].append(view)

        var allocated = presentingViews[identifier, default: []]
        if let index = allocated.firstIndex(of: view) {
            allocated.remove(at: index)
            presentingViews[identifier] = allocated
        }
    }
}
