//
//  Analytics.swift
//  Philfomation
//

import Foundation

// MARK: - Dashboard Stats
struct DashboardStats {
    let totalPosts: Int
    let totalBusinesses: Int
    let totalUsers: Int
    let totalComments: Int

    // Today's stats
    let postsToday: Int
    let viewsToday: Int

    // Weekly trend
    let weeklyPostTrend: [DailyCount]
    let weeklyViewTrend: [DailyCount]
}

// MARK: - Daily Count for Charts
struct DailyCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - Popular Post Stats
struct PopularPostStats: Identifiable {
    let id: String
    let title: String
    let category: PostCategory
    let authorName: String
    let viewCount: Int
    let likeCount: Int
    let commentCount: Int
    let engagementScore: Double

    var engagementRate: String {
        String(format: "%.1f", engagementScore)
    }
}

// MARK: - Popular Business Stats
struct PopularBusinessStats: Identifiable {
    let id: String
    let name: String
    let category: BusinessCategory
    let rating: Double
    let reviewCount: Int
    let viewCount: Int
}

// MARK: - Category Distribution
struct CategoryDistribution: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let percentage: Double
    let color: String
}

// MARK: - User Activity Stats
struct UserActivityStats {
    let totalViews: Int
    let totalLikes: Int
    let totalComments: Int
    let totalBookmarks: Int
    let postsWritten: Int
    let reviewsWritten: Int

    var engagementLevel: EngagementLevel {
        let score = totalLikes + (totalComments * 2) + (postsWritten * 5) + (reviewsWritten * 3)
        switch score {
        case 0..<10: return .newbie
        case 10..<50: return .active
        case 50..<100: return .contributor
        default: return .expert
        }
    }
}

enum EngagementLevel: String {
    case newbie = "뉴비"
    case active = "활동가"
    case contributor = "기여자"
    case expert = "전문가"

    var icon: String {
        switch self {
        case .newbie: return "leaf.fill"
        case .active: return "flame.fill"
        case .contributor: return "star.fill"
        case .expert: return "crown.fill"
        }
    }

    var color: String {
        switch self {
        case .newbie: return "22C55E"
        case .active: return "F59E0B"
        case .contributor: return "8B5CF6"
        case .expert: return "EF4444"
        }
    }
}

// MARK: - Time Period
enum TimePeriod: String, CaseIterable, Identifiable {
    case today = "오늘"
    case week = "이번 주"
    case month = "이번 달"
    case all = "전체"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .today: return 1
        case .week: return 7
        case .month: return 30
        case .all: return 365
        }
    }
}

// MARK: - Stat Card Data
struct StatCardData: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: String
    let trend: TrendDirection?
    let trendValue: String?
}

enum TrendDirection {
    case up
    case down
    case neutral

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .neutral: return "arrow.right"
        }
    }

    var color: String {
        switch self {
        case .up: return "22C55E"
        case .down: return "EF4444"
        case .neutral: return "6B7280"
        }
    }
}
