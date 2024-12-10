//
//  AppDelegate.swift
//  MyVideoSDKApp
//

import UIKit
import ZoomVideoSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - UIApplicationDelegate Methods

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Initialize Zoom Video SDK
        let initParams = ZoomVideoSDKInitParams()
        initParams.domain = "zoom.us"       // Make sure this is correct for your environment.
        initParams.enableLog = true         // Enable logs for debugging.
//        initParams.logSize = 5              // Adjust log size if needed, default is 5 MB.

        let initError = ZoomVideoSDK.shareInstance()?.initialize(initParams)
        if initError == .Errors_Success {
            print("Zoom Video SDK initialized successfully.")
        } else {
            print("Zoom Video SDK failed to initialize with error: \(String(describing: initError))")
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Handle discarded scenes if needed.
    }
}
