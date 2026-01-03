//
//  PhilfomationApp.swift
//  Philfomation
//
//  Created by robin on 1/2/26.
//

import SwiftUI
import UIKit
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Setup push notifications
        PushNotificationService.shared.setup()

        return true
    }

    // Handle APNs token
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // Handle Universal Links
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            return DeepLinkManager.shared.handleURL(url)
        }
        return false
    }
}

@main
struct PhilfomationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var deepLinkManager = DeepLinkManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(themeManager)
                .environmentObject(deepLinkManager)
                .preferredColorScheme(themeManager.colorScheme)
                .tint(themeManager.currentAccentColor)
                .onOpenURL { url in
                    _ = DeepLinkManager.shared.handleURL(url)
                }
        }
    }
}
