//
//  Post.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

// MARK: - Post Model
struct Post: Identifiable, Codable {
    @DocumentID var id: String?
    let authorId: String
    let authorName: String
    let category: PostCategory
    let title: String
    let content: String
    let imageURLs: [String]?
    var likeCount: Int
    var commentCount: Int
    var viewCount: Int
    let createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case authorId
        case authorName
        case category
        case title
        case content
        case imageURLs
        case likeCount
        case commentCount
        case viewCount
        case createdAt
        case updatedAt
    }
}

// MARK: - Post Category
enum PostCategory: String, Codable, CaseIterable, Identifiable {
    case qna = "질문답변"
    case experience = "경험담"
    case free = "자유게시판"
    case info = "정보공유"
    case tip = "꿀팁"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .qna: return "questionmark.circle.fill"
        case .experience: return "text.book.closed.fill"
        case .free: return "bubble.left.and.bubble.right.fill"
        case .info: return "info.circle.fill"
        case .tip: return "lightbulb.fill"
        }
    }

    var color: String {
        switch self {
        case .qna: return "2563EB"
        case .experience: return "7C3AED"
        case .free: return "059669"
        case .info: return "D97706"
        case .tip: return "DC2626"
        }
    }
}

// MARK: - Comment Model
struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    let postId: String
    let authorId: String
    let authorName: String
    let content: String
    var likeCount: Int
    let createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case postId
        case authorId
        case authorName
        case content
        case likeCount
        case createdAt
        case updatedAt
    }
}

// MARK: - Like Model
struct Like: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let targetId: String  // postId or commentId
    let targetType: LikeTargetType
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case targetId
        case targetType
        case createdAt
    }
}

enum LikeTargetType: String, Codable {
    case post
    case comment
}

// MARK: - Extensions
extension Post {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    static var sample: Post {
        Post(
            id: "sample1",
            authorId: "user1",
            authorName: "테스트유저",
            category: .qna,
            title: "마닐라 환전소 추천해주세요",
            content: "다음주에 마닐라 여행 가는데 환전소 어디가 좋을까요? 공항보다 시내가 좋다고 들었는데...",
            imageURLs: nil,
            likeCount: 5,
            commentCount: 3,
            viewCount: 42,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: nil
        )
    }
}

extension Comment {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    static var sample: Comment {
        Comment(
            id: "comment1",
            postId: "sample1",
            authorId: "user2",
            authorName: "답변자",
            content: "말라테 쪽 환전소가 환율이 좋아요!",
            likeCount: 2,
            createdAt: Date().addingTimeInterval(-1800),
            updatedAt: nil
        )
    }
}
