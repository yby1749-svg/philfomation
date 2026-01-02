//
//  AnalyticsViewModel.swift
//  Philfomation
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var dashboardStats: DashboardStats?
    @Published var popularPosts: [PopularPostStats] = []
    @Published var popularBusinesses: [PopularBusinessStats] = []
    @Published var postCategoryDistribution: [CategoryDistribution] = []
    @Published var businessCategoryDistribution: [CategoryDistribution] = []
    @Published var userActivityStats: UserActivityStats?

    @Published var selectedPeriod: TimePeriod = .week
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let analyticsService = AnalyticsService.shared

    // MARK: - Computed Properties

    var statCards: [StatCardData] {
        guard let stats = dashboardStats else { return [] }

        return [
            StatCardData(
                title: "총 게시글",
                value: "\(stats.totalPosts)",
                icon: "doc.text.fill",
                color: "2563EB",
                trend: stats.postsToday > 0 ? .up : .neutral,
                trendValue: stats.postsToday > 0 ? "+\(stats.postsToday) 오늘" : nil
            ),
            StatCardData(
                title: "총 업소",
                value: "\(stats.totalBusinesses)",
                icon: "building.2.fill",
                color: "7C3AED",
                trend: nil,
                trendValue: nil
            ),
            StatCardData(
                title: "총 회원",
                value: "\(stats.totalUsers)",
                icon: "person.2.fill",
                color: "059669",
                trend: nil,
                trendValue: nil
            ),
            StatCardData(
                title: "총 조회수",
                value: formatNumber(stats.viewsToday),
                icon: "eye.fill",
                color: "F59E0B",
                trend: .up,
                trendValue: "활발"
            )
        ]
    }

    // MARK: - Load Methods

    func loadDashboard() async {
        isLoading = true
        errorMessage = nil

        do {
            async let stats = analyticsService.fetchDashboardStats()
            async let posts = analyticsService.fetchPopularPosts(limit: 5, period: selectedPeriod)
            async let businesses = analyticsService.fetchPopularBusinesses(limit: 5)
            async let postDist = analyticsService.fetchPostCategoryDistribution()
            async let businessDist = analyticsService.fetchBusinessCategoryDistribution()

            dashboardStats = try await stats
            popularPosts = try await posts
            popularBusinesses = try await businesses
            postCategoryDistribution = try await postDist
            businessCategoryDistribution = try await businessDist
        } catch {
            errorMessage = "데이터를 불러오는데 실패했습니다."
            print("Analytics error: \(error)")
        }

        isLoading = false
    }

    func loadUserStats(userId: String) async {
        do {
            userActivityStats = try await analyticsService.fetchUserActivityStats(userId: userId)
        } catch {
            print("User stats error: \(error)")
        }
    }

    func refreshPopularPosts() async {
        do {
            popularPosts = try await analyticsService.fetchPopularPosts(limit: 10, period: selectedPeriod)
        } catch {
            print("Popular posts error: \(error)")
        }
    }

    func setPeriod(_ period: TimePeriod) {
        selectedPeriod = period
        Task {
            await refreshPopularPosts()
        }
    }

    // MARK: - Helpers

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}
