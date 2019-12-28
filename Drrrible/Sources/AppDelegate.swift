//
//  AppDelegate.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 07/03/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Properties
    
    var dependency: AppDependency!
    
    
    // MARK: UI
    
    var window: UIWindow?
    
    
    // MARK: UIApplicationDelegate
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 将 appdelegate 中的代码抽离到一个 dependency 中
        // dependency 当中提供
        // 1. SDK 的初始化
        // 2. 外观的设置
        // 3. 返回 window
        self.dependency = self.dependency ?? CompositionRoot.resolve()
        self.dependency.configureSDKs()
        self.dependency.configureAppearance()
        self.window = self.dependency.window
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return self.dependency.openURL(url, options)
    }
}
