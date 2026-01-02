//
//  WidgetDataManager.swift
//  Philfomation
//

import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let appGroupId = "group.com.philfomation.app"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    private init() {}

    // MARK: - Exchange Rate Data

    func saveExchangeRate(phpToKrw: Double, krwToPhp: Double) {
        let defaults = sharedDefaults
        defaults?.set(phpToKrw, forKey: "phpToKrw")
        defaults?.set(krwToPhp, forKey: "krwToPhp")

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        let lastUpdated = formatter.localizedString(for: Date(), relativeTo: Date())
        defaults?.set(lastUpdated, forKey: "exchangeRateLastUpdated")
        defaults?.synchronize()

        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "ExchangeRateWidget")
    }

    // MARK: - Popular Posts Data

    func savePopularPosts(_ posts: [PopularPostData]) {
        let defaults = sharedDefaults

        if let encoded = try? JSONEncoder().encode(posts) {
            defaults?.set(encoded, forKey: "popularPosts")
            defaults?.synchronize()
        }

        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "PopularPostsWidget")
    }
}

// MARK: - Popular Post Data for Widget

struct PopularPostData: Codable {
    let id: String
    let title: String
    let category: String
    let likeCount: Int
}
