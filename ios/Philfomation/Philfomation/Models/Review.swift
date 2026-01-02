//
//  Review.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var businessId: String
    var userId: String
    var userName: String
    var userPhotoURL: String?
    var rating: Int
    var comment: String
    var photos: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String? = nil,
        businessId: String,
        userId: String,
        userName: String,
        userPhotoURL: String? = nil,
        rating: Int,
        comment: String,
        photos: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.businessId = businessId
        self.userId = userId
        self.userName = userName
        self.userPhotoURL = userPhotoURL
        self.rating = rating
        self.comment = comment
        self.photos = photos
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var ratingStars: String {
        String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating)
    }
}
