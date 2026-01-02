//
//  Bookmark.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

// MARK: - Bookmark Model
struct Bookmark: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let postId: String
    let postTitle: String
    let postCategory: PostCategory
    let postAuthorName: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case postId
        case postTitle
        case postCategory
        case postAuthorName
        case createdAt
    }
}
