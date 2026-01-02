//
//  ChatRoom.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

enum ChatRoomCategory: String, Codable, CaseIterable {
    case general = "일반"
    case business = "비즈니스"
    case life = "생활"
    case travel = "여행"
    case food = "맛집"
    case job = "구인구직"
    case buy = "사고팔기"
    case other = "기타"

    var icon: String {
        switch self {
        case .general: return "bubble.left.and.bubble.right.fill"
        case .business: return "briefcase.fill"
        case .life: return "house.fill"
        case .travel: return "airplane"
        case .food: return "fork.knife"
        case .job: return "person.badge.plus"
        case .buy: return "cart.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct ChatRoom: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String?
    var category: ChatRoomCategory
    var ownerId: String
    var ownerName: String
    var photoURL: String?
    var memberCount: Int
    var lastMessage: String?
    var lastMessageTime: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String? = nil,
        name: String,
        description: String? = nil,
        category: ChatRoomCategory,
        ownerId: String,
        ownerName: String,
        photoURL: String? = nil,
        memberCount: Int = 1,
        lastMessage: String? = nil,
        lastMessageTime: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.photoURL = photoURL
        self.memberCount = memberCount
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum MemberRole: String, Codable {
    case admin = "admin"
    case member = "member"
}

struct ChatRoomMember: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var userName: String
    var userPhotoURL: String?
    var role: MemberRole
    var joinedAt: Date

    init(
        id: String? = nil,
        userId: String,
        userName: String,
        userPhotoURL: String? = nil,
        role: MemberRole = .member,
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userPhotoURL = userPhotoURL
        self.role = role
        self.joinedAt = joinedAt
    }
}
