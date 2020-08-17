//
//  UnityEmbeddedSwift.swift
//  UnitySwiftMix
//
//  Created by xu on 2019/11/19.
//  Copyright © 2019 tech. All rights reserved.
//

/*
 集成步骤
 1.生成iOS项目
 2.添加Embedded Binaries，删除Linked Frameworks and Libraries
 3.NativeCallProxy.h选择为UnityFramework-Public
 4.Data文件夹选择为UnityFramework
 ref:https://forum.unity.com/threads/integration-unity-as-a-library-in-native-ios-app.685219/#post-4754306
 */

typealias Unity = UnityEmbeddedSwift

import Foundation
import UnityFramework
 
class UnityEmbeddedSwift: UIResponder, UnityFrameworkListener {
    
    typealias UnityMessage = (objectName: String?,methodName: String?, messageBody: String?)
 
    static let instance = UnityEmbeddedSwift()
    private var ufw : UnityFramework!
    private static var mainWindow : UIWindow! //Window to return to when exitting Unity window
    private static var launchOpts : [UIApplication.LaunchOptionsKey: Any]?
 
    private static var cachedMessages = [UnityMessage]()
    
    static func setLaunchinOptions(_ launchingOptions : [UIApplication.LaunchOptionsKey: Any]?, mainWindow: UIWindow?) {
        UnityEmbeddedSwift.mainWindow = mainWindow
        UnityEmbeddedSwift.launchOpts = launchingOptions
    }
 
    static func sendUnityMessage(_ msg: UnityMessage) {
        //Send the message right away if Unity is initialized, else cache it
        if(UnityEmbeddedSwift.instance.isInitialized()) {
            UnityEmbeddedSwift.instance.ufw.sendMessageToGO(withName: msg.objectName, functionName: msg.methodName, message: msg.messageBody)
        }else {
            UnityEmbeddedSwift.cachedMessages.append(msg)
        }
    }
    
    static func initUnity() {
        if UnityEmbeddedSwift.instance.isInitialized() {
            return
        }
        
        UnityEmbeddedSwift.instance.ufw = UnityEmbeddedSwift.instance.UnityFrameworkLoad()!
        UnityEmbeddedSwift.instance.ufw.setDataBundleId("com.unity3d.framework")
        UnityEmbeddedSwift.instance.ufw.register(UnityEmbeddedSwift.instance)
        
        UnityEmbeddedSwift.instance.ufw.runEmbedded(withArgc: CommandLine.argc, argv: CommandLine.unsafeArgv, appLaunchOpts: UnityEmbeddedSwift.launchOpts)
        
        FrameworkLibAPI.registerAPIforNativeCalls(UnityInterface.shared)
        
        UnityEmbeddedSwift.instance.sendUnityMessageToGameObject()
    }
    
    static func unloadUnity() {
        if UnityEmbeddedSwift.instance.isInitialized() {
            UnityEmbeddedSwift.cachedMessages.removeAll()
            UnityEmbeddedSwift.instance.ufw.unloadApplication()
        }
    }
    
    static func unityAppDelegate() -> UnityAppController? {
        return UnityEmbeddedSwift.instance.ufw?.appController()
    }
    
    static func unityViewController() -> UIViewController? {
        return UnityEmbeddedSwift.instance.ufw?.appController()?.rootViewController
    }
    
    static func unityView() -> UIView? {
        return UnityEmbeddedSwift.instance.ufw?.appController()?.rootView
    }
    
    static func pause() {
        UnityEmbeddedSwift.instance.ufw.pause(true)
    }
    
    static func resume() {
        UnityEmbeddedSwift.instance.ufw.pause(false)
    }
 
    private func sendUnityMessageToGameObject() {
        if(UnityEmbeddedSwift.cachedMessages.count >= 0 && isInitialized()) {
            for msg in UnityEmbeddedSwift.cachedMessages {
                ufw.sendMessageToGO(withName: msg.objectName, functionName: msg.methodName, message: msg.messageBody)
            }
       
            UnityEmbeddedSwift.cachedMessages.removeAll()
        }
    }
    
    //Private functions called within the class
    private func isInitialized() -> Bool {
        return ufw != nil && (ufw.appController() != nil)
    }
 
    private func UnityFrameworkLoad() -> UnityFramework? {
        let bundlePath: String = Bundle.main.bundlePath + "/Frameworks/UnityFramework.framework"
   
        let bundle = Bundle(path: bundlePath )
        if bundle?.isLoaded == false {
            bundle?.load()
        }
   
        let ufw = bundle?.principalClass?.getInstance()
        if ufw?.appController() == nil {
            // unity is not initialized
            // ufw?.executeHeader = &mh_execute_header
       
            let machineHeader = UnsafeMutablePointer<MachHeader>.allocate(capacity: 1)
            machineHeader.pointee = _mh_execute_header
       
            ufw!.setExecuteHeader(machineHeader)
        }
        return ufw
    }
}

extension UnityEmbeddedSwift: UIApplicationDelegate {
    func applicationWillResignActive(_ application: UIApplication) {
        ufw.appController()?.applicationWillResignActive(application)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        ufw.appController()?.applicationDidEnterBackground(application)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        ufw.appController()?.applicationWillEnterForeground(application)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        ufw.appController()?.applicationDidBecomeActive(application)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        ufw.appController()?.applicationWillTerminate(application)
    }
}

extension UnityEmbeddedSwift {
    //Callback from UnityFrameworkListener
    func unityDidUnload(_ notification: Notification!) {
        ufw.unregisterFrameworkListener(self)
        ufw = nil
    }
}


