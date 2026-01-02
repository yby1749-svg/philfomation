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
