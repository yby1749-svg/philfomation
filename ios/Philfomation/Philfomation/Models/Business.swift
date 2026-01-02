//
//  Business.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore
import CoreLocation

enum BusinessCategory: String, Codable, CaseIterable {
    case restaurant = "음식점"
    case massage = "마사지"
    case salon = "미용실"
    case karaoke = "노래방"
    case mart = "마트"
    case travel = "여행사"
    case other = "기타"

    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .massage: return "hand.raised.fill"
        case .salon: return "scissors"
        case .karaoke: return "music.mic"
        case .mart: return "cart.fill"
        case .travel: return "airplane"
        case .other: return "building.2.fill"
        }
    }

    var color: String {
        switch self {
        case .restaurant: return "F97316"
        case .massage: return "EC4899"
        case .salon: return "8B5CF6"
        case .karaoke: return "EF4444"
        case .mart: return "22C55E"
        case .travel: return "3B82F6"
        case .other: return "6B7280"
        }
    }
}

struct Business: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var category: BusinessCategory
    var description: String?
    var address: String
    var phone: String?
    var photos: [String]
    var rating: Double
    var reviewCount: Int
    var ownerId: String?
    var latitude: Double?
    var longitude: Double?
    var openingHours: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String? = nil,
        name: String,
        category: BusinessCategory,
        description: String? = nil,
        address: String,
        phone: String? = nil,
        photos: [String] = [],
        rating: Double = 0.0,
        reviewCount: Int = 0,
        ownerId: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        openingHours: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.address = address
        self.phone = phone
        self.photos = photos
        self.rating = rating
        self.reviewCount = reviewCount
        self.ownerId = ownerId
        self.latitude = latitude
        self.longitude = longitude
        self.openingHours = openingHours
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lng = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}
