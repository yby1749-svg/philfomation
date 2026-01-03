//
//  Notification.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

// MARK: - Notification Model
struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String           // 알림 받는 사용자
    let type: NotificationType
    let title: String
    let message: String
    let relatedPostId: String?   // 관련 게시글 ID
    let relatedCommentId: String? // 관련 댓글 ID
    let senderId: String?        // 알림 발생시킨 사용자
    let senderName: String?
    var isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case type
        case title
        case message
        case relatedPostId
        case relatedCommentId
        case senderId
        case senderName
        case isRead
        case createdAt
    }
}

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case comment = "comment"        // 내 게시글에 댓글
    case like = "like"              // 내 게시글/댓글에 좋아요
    case reply = "reply"            // 내 댓글에 답글
    case system = "system"          // 시스템 알림

    var icon: String {
        switch self {
        case .comment: return "bubble.right.fill"
        case .like: return "heart.fill"
        case .reply: return "arrowshape.turn.up.left.fill"
        case .system: return "bell.fill"
        }
    }

    var color: String {
        switch self {
        case .comment: return "2563EB"
        case .like: return "DC2626"
        case .reply: return "7C3AED"
        case .system: return "059669"
        }
    }
}

// MARK: - Notification Preferences
struct NotificationPreferences: Codable {
    // 알림 타입별 설정
    var commentEnabled: Bool = true
    var likeEnabled: Bool = true
    var replyEnabled: Bool = true
    var systemEnabled: Bool = true
    var chatEnabled: Bool = true

    // 방해금지 모드
    var quietHoursEnabled: Bool = false
    var quietHoursStart: Int = 22  // 22:00
    var quietHoursEnd: Int = 8     // 08:00

    // 소리/진동 설정
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true

    // 미리보기 설정
    var showPreview: Bool = true

    // 기본값
    static let `default` = NotificationPreferences()

    // 저장 키
    private static let storageKey = "notificationPreferences"

    // 저장
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        }
    }

    // 불러오기
    static func load() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }

    // 현재 방해금지 시간인지 확인
    func isInQuietHours() -> Bool {
        guard quietHoursEnabled else { return false }

        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        if quietHoursStart < quietHoursEnd {
            // 같은 날 (예: 08:00 ~ 22:00)
            return hour >= quietHoursStart && hour < quietHoursEnd
        } else {
            // 다음 날로 넘어가는 경우 (예: 22:00 ~ 08:00)
            return hour >= quietHoursStart || hour < quietHoursEnd
        }
    }

    // 알림 타입이 활성화되어 있는지 확인
    func isEnabled(for type: NotificationType) -> Bool {
        switch type {
        case .comment: return commentEnabled
        case .like: return likeEnabled
        case .reply: return replyEnabled
        case .system: return systemEnabled
        }
    }
}

// MARK: - Notification Category (for grouping)
enum NotificationCategory: String {
    case social = "SOCIAL"          // 댓글, 좋아요, 답글
    case chat = "CHAT"              // 채팅 메시지
    case system = "SYSTEM"          // 시스템 알림

    var identifier: String { rawValue }

    var summaryFormat: String {
        switch self {
        case .social: return "%u개의 새로운 알림"
        case .chat: return "%u개의 새로운 메시지"
        case .system: return "%u개의 시스템 알림"
        }
    }
}

// MARK: - Extensions
extension AppNotification {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    static var sample: AppNotification {
        AppNotification(
            id: "sample1",
            userId: "user1",
            type: .comment,
            title: "새 댓글",
            message: "홍길동님이 댓글을 남겼습니다.",
            relatedPostId: "post1",
            relatedCommentId: nil,
            senderId: "user2",
            senderName: "홍길동",
            isRead: false,
            createdAt: Date().addingTimeInterval(-3600)
        )
    }
}
