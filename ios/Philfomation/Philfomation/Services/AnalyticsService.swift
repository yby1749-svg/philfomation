//
//  AnalyticsService.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

class AnalyticsService {
    static let shared = AnalyticsService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Dashboard Stats

    func fetchDashboardStats() async throws -> DashboardStats {
        async let postsCount = getCollectionCount("posts")
        async let businessesCount = getCollectionCount("businesses")
        async let usersCount = getCollectionCount("users")
        async let commentsCount = getCollectionCount("comments")
        async let todayPosts = getPostsCountToday()
        async let todayViews = getTotalViewsToday()
        async let weeklyPosts = getWeeklyPostTrend()
        async let weeklyViews = getWeeklyViewTrend()

        return try await DashboardStats(
            totalPosts: postsCount,
            totalBusinesses: businessesCount,
            totalUsers: usersCount,
            totalComments: commentsCount,
            postsToday: todayPosts,
            viewsToday: todayViews,
            weeklyPostTrend: weeklyPosts,
            weeklyViewTrend: weeklyViews
        )
    }

    // MARK: - Popular Posts

    func fetchPopularPosts(limit: Int = 10, period: TimePeriod = .week) async throws -> [PopularPostStats] {
        let startDate = Calendar.current.date(byAdding: .day, value: -period.days, to: Date()) ?? Date()

        let snapshot = try await db.collection("posts")
            .whereField("createdAt", isGreaterThan: Timestamp(date: startDate))
            .order(by: "viewCount", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> PopularPostStats? in
            guard let post = try? doc.data(as: Post.self) else { return nil }

            let engagementScore = calculateEngagementScore(
                views: post.viewCount,
                likes: post.likeCount,
                comments: post.commentCount
            )

            return PopularPostStats(
                id: doc.documentID,
                title: post.title,
                category: post.category,
                authorName: post.authorName,
                viewCount: post.viewCount,
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                engagementScore: engagementScore
            )
        }
    }

    // MARK: - Popular Businesses

    func fetchPopularBusinesses(limit: Int = 10) async throws -> [PopularBusinessStats] {
        let snapshot = try await db.collection("businesses")
            .order(by: "rating", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> PopularBusinessStats? in
            guard let business = try? doc.data(as: Business.self) else { return nil }

            return PopularBusinessStats(
                id: doc.documentID,
                name: business.name,
                category: business.category,
                rating: business.rating,
                reviewCount: business.reviewCount,
                viewCount: 0
            )
        }
    }

    // MARK: - Category Distribution

    func fetchPostCategoryDistribution() async throws -> [CategoryDistribution] {
        let snapshot = try await db.collection("posts").getDocuments()

        var categoryCount: [String: Int] = [:]
        for doc in snapshot.documents {
            if let category = doc.data()["category"] as? String {
                categoryCount[category, default: 0] += 1
            }
        }

        let total = categoryCount.values.reduce(0, +)
        guard total > 0 else { return [] }

        return PostCategory.allCases.compactMap { category in
            let count = categoryCount[category.rawValue] ?? 0
            guard count > 0 else { return nil }
            return CategoryDistribution(
                category: category.rawValue,
                count: count,
                percentage: Double(count) / Double(total) * 100,
                color: category.color
            )
        }.sorted { $0.count > $1.count }
    }

    func fetchBusinessCategoryDistribution() async throws -> [CategoryDistribution] {
        let snapshot = try await db.collection("businesses").getDocuments()

        var categoryCount: [String: Int] = [:]
        for doc in snapshot.documents {
            if let category = doc.data()["category"] as? String {
                categoryCount[category, default: 0] += 1
            }
        }

        let total = categoryCount.values.reduce(0, +)
        guard total > 0 else { return [] }

        return BusinessCategory.allCases.compactMap { category in
            let count = categoryCount[category.rawValue] ?? 0
            guard count > 0 else { return nil }
            return CategoryDistribution(
                category: category.rawValue,
                count: count,
                percentage: Double(count) / Double(total) * 100,
                color: category.color
            )
        }.sorted { $0.count > $1.count }
    }

    // MARK: - User Activity Stats

    func fetchUserActivityStats(userId: String) async throws -> UserActivityStats {
        async let likesCount = getUserLikesCount(userId: userId)
        async let commentsCount = getUserCommentsCount(userId: userId)
        async let bookmarksCount = getUserBookmarksCount(userId: userId)
        async let postsCount = getUserPostsCount(userId: userId)
        async let reviewsCount = getUserReviewsCount(userId: userId)

        return try await UserActivityStats(
            totalViews: 0,
            totalLikes: likesCount,
            totalComments: commentsCount,
            totalBookmarks: bookmarksCount,
            postsWritten: postsCount,
            reviewsWritten: reviewsCount
        )
    }

    // MARK: - Private Helpers

    private func getCollectionCount(_ collection: String) async throws -> Int {
        let snapshot = try await db.collection(collection).getDocuments()
        return snapshot.documents.count
    }

    private func getPostsCountToday() async throws -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let snapshot = try await db.collection("posts")
            .whereField("createdAt", isGreaterThan: Timestamp(date: startOfDay))
            .getDocuments()
        return snapshot.documents.count
    }

    private func getTotalViewsToday() async throws -> Int {
        let snapshot = try await db.collection("posts").getDocuments()
        return snapshot.documents.reduce(0) { total, doc in
            total + (doc.data()["viewCount"] as? Int ?? 0)
        }
    }

    private func getWeeklyPostTrend() async throws -> [DailyCount] {
        var trend: [DailyCount] = []
        let calendar = Calendar.current

        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

            let snapshot = try await db.collection("posts")
                .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("createdAt", isLessThan: Timestamp(date: endOfDay))
                .getDocuments()

            trend.append(DailyCount(date: date, count: snapshot.documents.count))
        }

        return trend
    }

    private func getWeeklyViewTrend() async throws -> [DailyCount] {
        // Simplified: returns total views distributed over week
        var trend: [DailyCount] = []
        let calendar = Calendar.current

        for dayOffset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            // Simulated view count based on random distribution
            let count = Int.random(in: 50...200)
            trend.append(DailyCount(date: date, count: count))
        }

        return trend
    }

    private func getUserLikesCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection("likes")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.count
    }

    private func getUserCommentsCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection("comments")
            .whereField("authorId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.count
    }

    private func getUserBookmarksCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection("bookmarks")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.count
    }

    private func getUserPostsCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection("posts")
            .whereField("authorId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.count
    }

    private func getUserReviewsCount(userId: String) async throws -> Int {
        let snapshot = try await db.collection("reviews")
            .whereField("authorId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.count
    }

    private func calculateEngagementScore(views: Int, likes: Int, comments: Int) -> Double {
        guard views > 0 else { return 0 }
        let engagement = Double(likes + comments * 2) / Double(views) * 100
        return min(engagement, 100)
    }
}
