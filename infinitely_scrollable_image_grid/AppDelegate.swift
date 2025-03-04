//
//  AppDelegate.swift
//  infinitely_scrollable_image_grid
//
//  Created by Valeriia Fisenko on 01/03/2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            window = UIWindow(frame: UIScreen.main.bounds)

            let vc = InfinitelyScrollableImageGridViewController(imageLoader: ImageLoaderImpl())

            window?.rootViewController = vc
            window?.makeKeyAndVisible()
        }

        
        return true
    }
}
