//
//  NotificationService.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

class NotificationService {
    static let shared = NotificationService()

    private let db = Firestore.firestore()
    private let collection = "notifications"

    private init() {}

    // MARK: - Fetch Notifications

    func fetchNotifications(userId: String, limit: Int = 50) async throws -> [AppNotification] {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: AppNotification.self) }
    }

    func fetchUnreadCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        return snapshot.documents.count
    }

    // MARK: - Create Notifications

    func createNotification(_ notification: AppNotification) async throws {
        try db.collection(collection).addDocument(from: notification)
    }

    func createCommentNotification(
        postAuthorId: String,
        postId: String,
        commenterName: String,
        commenterId: String
    ) async throws {
        // 자신의 게시글에 자신이 댓글을 달면 알림 생성하지 않음
        guard postAuthorId != commenterId else { return }

        let notification = AppNotification(
            userId: postAuthorId,
            type: .comment,
            title: "새 댓글",
            message: "\(commenterName)님이 회원님의 게시글에 댓글을 남겼습니다.",
            relatedPostId: postId,
            relatedCommentId: nil,
            senderId: commenterId,
            senderName: commenterName,
            isRead: false,
            createdAt: Date()
        )

        try await createNotification(notification)
    }

    func createLikeNotification(
        targetAuthorId: String,
        targetType: LikeTargetType,
        targetId: String,
        likerName: String,
        likerId: String
    ) async throws {
        // 자신의 게시글/댓글에 자신이 좋아요하면 알림 생성하지 않음
        guard targetAuthorId != likerId else { return }

        let message = targetType == .post
            ? "\(likerName)님이 회원님의 게시글을 좋아합니다."
            : "\(likerName)님이 회원님의 댓글을 좋아합니다."

        let notification = AppNotification(
            userId: targetAuthorId,
            type: .like,
            title: "좋아요",
            message: message,
            relatedPostId: targetType == .post ? targetId : nil,
            relatedCommentId: targetType == .comment ? targetId : nil,
            senderId: likerId,
            senderName: likerName,
            isRead: false,
            createdAt: Date()
        )

        try await createNotification(notification)
    }

    // MARK: - Update Notifications

    func markAsRead(notificationId: String) async throws {
        try await db.collection(collection).document(notificationId).updateData([
            "isRead": true
        ])
    }

    func markAllAsRead(userId: String) async throws {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    // MARK: - Delete Notifications

    func deleteNotification(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }

    func deleteAllNotifications(userId: String) async throws {
        let snapshot = try await db.collection(collection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
}
