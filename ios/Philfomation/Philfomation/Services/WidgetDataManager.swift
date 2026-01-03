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

    func saveExchangeRate(phpToKrw: Double, krwToPhp: Double, trend: String = "stable") {
        let defaults = sharedDefaults
        defaults?.set(phpToKrw, forKey: "phpToKrw")
        defaults?.set(krwToPhp, forKey: "krwToPhp")
        defaults?.set(krwToPhp, forKey: "exchangeRate_KRW_PHP")
        defaults?.set(phpToKrw, forKey: "exchangeRate_PHP_KRW")
        defaults?.set(trend, forKey: "exchangeRate_trend")

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let lastUpdated = formatter.string(from: Date())
        defaults?.set(lastUpdated, forKey: "exchangeRateLastUpdated")
        defaults?.set(lastUpdated, forKey: "exchangeRate_lastUpdated")
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

    // MARK: - Latest Posts for Community Widget

    func saveLatestPosts(_ posts: [Post]) {
        let widgetPosts = posts.prefix(5).map { post in
            WidgetPostData(
                id: post.id ?? UUID().uuidString,
                title: post.title,
                category: post.category.rawValue,
                categoryColor: post.category.color,
                authorName: post.authorName,
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                timeAgo: timeAgo(from: post.createdAt)
            )
        }

        if let data = try? JSONEncoder().encode(Array(widgetPosts)) {
            sharedDefaults?.set(data, forKey: "latestPosts")
            sharedDefaults?.synchronize()
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "CommunityWidget")
    }

    // MARK: - Popular Businesses

    func savePopularBusinesses(_ businesses: [Business]) {
        let widgetBusinesses = businesses.prefix(5).map { business in
            WidgetBusinessData(
                id: business.id ?? UUID().uuidString,
                name: business.name,
                category: business.category.rawValue,
                categoryIcon: business.category.icon,
                categoryColor: business.category.color,
                rating: business.rating,
                reviewCount: business.reviewCount,
                distance: nil
            )
        }

        if let data = try? JSONEncoder().encode(Array(widgetBusinesses)) {
            sharedDefaults?.set(data, forKey: "popularBusinesses")
            sharedDefaults?.synchronize()
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "BusinessWidget")
    }

    // MARK: - Reload All Widgets

    func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Helpers

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Widget Data Models

struct PopularPostData: Codable {
    let id: String
    let title: String
    let category: String
    let likeCount: Int
}

struct WidgetPostData: Codable {
    let id: String
    let title: String
    let category: String
    let categoryColor: String
    let authorName: String
    let likeCount: Int
    let commentCount: Int
    let timeAgo: String
}

struct WidgetBusinessData: Codable {
    let id: String
    let name: String
    let category: String
    let categoryIcon: String
    let categoryColor: String
    let rating: Double
    let reviewCount: Int
    let distance: String?
}
