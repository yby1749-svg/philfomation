//
//  Chat.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

struct Chat: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String]
    var lastMessage: String?
    var lastMessageTime: Date?
    var unreadCount: [String: Int]
    var createdAt: Date

    init(
        id: String? = nil,
        participants: [String],
        lastMessage: String? = nil,
        lastMessageTime: Date? = nil,
        unreadCount: [String: Int] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.unreadCount = unreadCount
        self.createdAt = createdAt
    }

    func otherParticipantId(currentUserId: String) -> String? {
        participants.first { $0 != currentUserId }
    }
}

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String
    var text: String?
    var imageUrl: String?
    var timestamp: Date
    var isRead: Bool

    init(
        id: String? = nil,
        senderId: String,
        senderName: String,
        text: String? = nil,
        imageUrl: String? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.imageUrl = imageUrl
        self.timestamp = timestamp
        self.isRead = isRead
    }

    var isImageMessage: Bool {
        imageUrl != nil && (text == nil || text?.isEmpty == true)
    }
}
