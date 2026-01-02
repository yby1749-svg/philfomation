//
//  PushNotificationService.swift
//  Philfomation
//

import Foundation
import Combine
import FirebaseMessaging
import FirebaseFirestore
import UserNotifications
import UIKit

class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    @Published var fcmToken: String?
    @Published var isPermissionGranted = false

    private let db = Firestore.firestore()

    private override init() {
        super.init()
    }

    // MARK: - Setup

    func setup() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Request Permission

    func requestPermission() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)

            await MainActor.run {
                isPermissionGranted = granted
            }

            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }

            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }

    // MARK: - Token Management

    func saveFCMToken(userId: String) async {
        guard let token = fcmToken else { return }

        do {
            try await db.collection("users").document(userId).updateData([
                "fcmToken": token
            ])
            print("FCM token saved for user: \(userId)")
        } catch {
            print("Error saving FCM token: \(error)")
        }
    }

    func removeFCMToken(userId: String) async {
        do {
            try await db.collection("users").document(userId).updateData([
                "fcmToken": FieldValue.delete()
            ])
            print("FCM token removed for user: \(userId)")
        } catch {
            print("Error removing FCM token: \(error)")
        }
    }

    // MARK: - Send Notification (via Cloud Function)

    func sendPushNotification(
        to userId: String,
        title: String,
        body: String,
        data: [String: String]? = nil
    ) async {
        // This will be handled by Cloud Functions
        // The app just needs to create the notification in Firestore
        // and Cloud Function will send the push notification
    }

    // MARK: - Test Notification

    func sendTestNotification(userId: String) async -> Result<String, Error> {
        // Firebase Functions URL
        guard let url = URL(string: "https://us-central1-philfomation-232a8.cloudfunctions.net/sendTestNotification") else {
            return .failure(NSError(domain: "PushNotification", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": userId,
            "title": "테스트 알림",
            "body": "푸시 알림이 정상적으로 작동합니다! 🎉"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(NSError(domain: "PushNotification", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }

            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String {
                    return .success(message)
                }
                return .success("Notification sent")
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = json["error"] as? String {
                    return .failure(NSError(domain: "PushNotification", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: error]))
                }
                return .failure(NSError(domain: "PushNotification", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Request failed"]))
            }
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Check Permission Status

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Get Current FCM Token

    func getCurrentToken() async -> String? {
        do {
            let token = try await Messaging.messaging().token()
            await MainActor.run {
                self.fcmToken = token
            }
            return token
        } catch {
            print("Error fetching FCM token: \(error)")
            return nil
        }
    }
}

// MARK: - MessagingDelegate
extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "nil")")

        Task { @MainActor in
            self.fcmToken = fcmToken
        }

        // If user is logged in, save the token
        if let userId = AuthService.shared.currentUserId, let token = fcmToken {
            Task {
                await saveFCMToken(userId: userId)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    // Handle foreground notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("Received notification in foreground: \(userInfo)")

        // Show banner and play sound even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("User tapped notification: \(userInfo)")

        // Handle deep linking based on notification data
        handleNotificationTap(userInfo: userInfo)

        completionHandler()
    }

    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Extract notification type and related IDs
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "comment", "like":
            if let postId = userInfo["postId"] as? String {
                // Navigate to post detail
                NotificationCenter.default.post(
                    name: .navigateToPost,
                    object: nil,
                    userInfo: ["postId": postId]
                )
            }
        case "chat":
            if let chatId = userInfo["chatId"] as? String {
                // Navigate to chat
                NotificationCenter.default.post(
                    name: .navigateToChat,
                    object: nil,
                    userInfo: ["chatId": chatId]
                )
            }
        default:
            break
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToPost = Notification.Name("navigateToPost")
    static let navigateToChat = Notification.Name("navigateToChat")
}
