//
//  User.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

enum UserType: String, Codable, CaseIterable {
    case customer = "customer"
    case business = "business"

    var displayName: String {
        switch self {
        case .customer: return "손님"
        case .business: return "업소"
        }
    }
}

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var photoURL: String?
    var phoneNumber: String?
    var userType: UserType
    var fcmToken: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String? = nil,
        name: String,
        email: String,
        photoURL: String? = nil,
        phoneNumber: String? = nil,
        userType: UserType = .customer,
        fcmToken: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.photoURL = photoURL
        self.phoneNumber = phoneNumber
        self.userType = userType
        self.fcmToken = fcmToken
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
