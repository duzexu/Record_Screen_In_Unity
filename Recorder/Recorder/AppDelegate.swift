//
//  AppDelegate.swift
//  Recorder
//
//  Created by xu on 2020/7/27.
//  Copyright © 2020 SceneConsole. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UnityEmbeddedSwift.setLaunchinOptions(launchOptions, mainWindow: nil)
        UnityEmbeddedSwift.initUnity()
        return true
    }


}

