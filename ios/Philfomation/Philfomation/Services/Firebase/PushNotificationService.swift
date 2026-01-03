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

// MARK: - Notification Action Identifiers
enum NotificationActionIdentifier: String {
    case reply = "REPLY_ACTION"
    case markAsRead = "MARK_AS_READ_ACTION"
    case viewPost = "VIEW_POST_ACTION"
    case viewChat = "VIEW_CHAT_ACTION"
}

// MARK: - Notification Category Identifiers
enum NotificationCategoryIdentifier: String {
    case social = "SOCIAL_CATEGORY"      // 댓글, 좋아요, 답글
    case chat = "CHAT_CATEGORY"          // 채팅 메시지
    case system = "SYSTEM_CATEGORY"      // 시스템 알림
}

class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()

    @Published var fcmToken: String?
    @Published var isPermissionGranted = false

    private let db = Firestore.firestore()

    // Notification preferences
    var preferences: NotificationPreferences {
        NotificationPreferences.load()
    }

    private override init() {
        super.init()
    }

    // MARK: - Setup

    func setup() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
    }

    // MARK: - Register Notification Categories

    private func registerNotificationCategories() {
        // Social category actions (댓글, 좋아요, 답글)
        let viewPostAction = UNNotificationAction(
            identifier: NotificationActionIdentifier.viewPost.rawValue,
            title: "게시글 보기",
            options: [.foreground]
        )

        let markAsReadAction = UNNotificationAction(
            identifier: NotificationActionIdentifier.markAsRead.rawValue,
            title: "읽음으로 표시",
            options: []
        )

        let socialCategory = UNNotificationCategory(
            identifier: NotificationCategoryIdentifier.social.rawValue,
            actions: [viewPostAction, markAsReadAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "새로운 알림이 있습니다",
            categorySummaryFormat: "%u개의 새로운 알림",
            options: []
        )

        // Chat category actions
        let replyAction = UNTextInputNotificationAction(
            identifier: NotificationActionIdentifier.reply.rawValue,
            title: "답장",
            options: [],
            textInputButtonTitle: "보내기",
            textInputPlaceholder: "메시지 입력..."
        )

        let viewChatAction = UNNotificationAction(
            identifier: NotificationActionIdentifier.viewChat.rawValue,
            title: "채팅 열기",
            options: [.foreground]
        )

        let chatCategory = UNNotificationCategory(
            identifier: NotificationCategoryIdentifier.chat.rawValue,
            actions: [replyAction, viewChatAction, markAsReadAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "새로운 메시지가 있습니다",
            categorySummaryFormat: "%u개의 새로운 메시지",
            options: []
        )

        // System category
        let systemCategory = UNNotificationCategory(
            identifier: NotificationCategoryIdentifier.system.rawValue,
            actions: [markAsReadAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "시스템 알림",
            categorySummaryFormat: "%u개의 시스템 알림",
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            socialCategory,
            chatCategory,
            systemCategory
        ])
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

        // Check user preferences
        let prefs = preferences

        // Check quiet hours
        if prefs.isInQuietHours() {
            // During quiet hours, show banner only (no sound/vibration)
            completionHandler([.banner, .badge])
            return
        }

        // Check if notification type is enabled
        if let type = userInfo["type"] as? String {
            let notificationType = NotificationType(rawValue: type)

            if let notifType = notificationType, !prefs.isEnabled(for: notifType) {
                // This notification type is disabled, don't show
                completionHandler([])
                return
            }

            // Check chat notifications separately
            if type == "chat" && !prefs.chatEnabled {
                completionHandler([])
                return
            }
        }

        // Build presentation options based on preferences
        var options: UNNotificationPresentationOptions = [.banner, .badge]

        if prefs.soundEnabled {
            options.insert(.sound)
        }

        completionHandler(options)
    }

    // Handle notification tap and actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("User tapped notification: \(userInfo)")

        // Handle notification actions
        switch response.actionIdentifier {
        case NotificationActionIdentifier.reply.rawValue:
            handleReplyAction(response: response, userInfo: userInfo)

        case NotificationActionIdentifier.markAsRead.rawValue:
            handleMarkAsReadAction(userInfo: userInfo)

        case NotificationActionIdentifier.viewPost.rawValue:
            handleViewPostAction(userInfo: userInfo)

        case NotificationActionIdentifier.viewChat.rawValue:
            handleViewChatAction(userInfo: userInfo)

        case UNNotificationDefaultActionIdentifier:
            // Default tap action - handle deep linking
            handleNotificationTap(userInfo: userInfo)

        default:
            break
        }

        completionHandler()
    }

    // MARK: - Action Handlers

    private func handleReplyAction(response: UNNotificationResponse, userInfo: [AnyHashable: Any]) {
        guard let textResponse = response as? UNTextInputNotificationResponse else { return }
        let replyText = textResponse.userText

        if let chatId = userInfo["chatId"] as? String {
            // Send reply message
            NotificationCenter.default.post(
                name: .sendChatReply,
                object: nil,
                userInfo: ["chatId": chatId, "message": replyText]
            )
        }
    }

    private func handleMarkAsReadAction(userInfo: [AnyHashable: Any]) {
        if let notificationId = userInfo["notificationId"] as? String {
            Task {
                try? await NotificationService.shared.markAsRead(notificationId: notificationId)
            }
        }
    }

    private func handleViewPostAction(userInfo: [AnyHashable: Any]) {
        if let postId = userInfo["postId"] as? String {
            NotificationCenter.default.post(
                name: .navigateToPost,
                object: nil,
                userInfo: ["postId": postId]
            )
        }
    }

    private func handleViewChatAction(userInfo: [AnyHashable: Any]) {
        if let chatId = userInfo["chatId"] as? String {
            NotificationCenter.default.post(
                name: .navigateToChat,
                object: nil,
                userInfo: ["chatId": chatId]
            )
        }
    }

    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Extract notification type and related IDs
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "comment", "like", "reply":
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
        case "business":
            if let businessId = userInfo["businessId"] as? String {
                NotificationCenter.default.post(
                    name: .navigateToBusiness,
                    object: nil,
                    userInfo: ["businessId": businessId]
                )
            }
        default:
            // For system or unknown types, open notifications view
            NotificationCenter.default.post(name: .navigateToNotifications, object: nil)
        }
    }

    // MARK: - Schedule Local Notification with Grouping

    func scheduleLocalNotification(
        title: String,
        body: String,
        type: NotificationType,
        threadId: String? = nil,
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        // Set category based on type
        switch type {
        case .comment, .like, .reply:
            content.categoryIdentifier = NotificationCategoryIdentifier.social.rawValue
        case .system:
            content.categoryIdentifier = NotificationCategoryIdentifier.system.rawValue
        }

        // Set thread identifier for grouping
        if let threadId = threadId {
            content.threadIdentifier = threadId
        } else {
            // Group by type if no specific thread
            content.threadIdentifier = type.rawValue
        }

        // Add user info
        var info = userInfo
        info["type"] = type.rawValue
        content.userInfo = info

        // Sound based on preferences
        if preferences.soundEnabled && !preferences.isInQuietHours() {
            content.sound = .default
        }

        // Create request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToPost = Notification.Name("navigateToPost")
    static let navigateToChat = Notification.Name("navigateToChat")
    static let navigateToBusiness = Notification.Name("navigateToBusiness")
    static let navigateToNotifications = Notification.Name("navigateToNotifications")
    static let sendChatReply = Notification.Name("sendChatReply")
}
