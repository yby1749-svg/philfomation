//
//  StatsDashboardView.swift
//  Philfomation
//

import SwiftUI
import Charts

struct StatsDashboardView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        DashboardSkeletonView()
                    } else {
                        // Stats Cards
                        StatsCardsSection(cards: viewModel.statCards)

                        // Weekly Trend Chart
                        if let stats = viewModel.dashboardStats {
                            WeeklyTrendSection(trend: stats.weeklyPostTrend)
                        }

                        // Popular Posts
                        PopularPostsSection(
                            posts: viewModel.popularPosts,
                            selectedPeriod: $viewModel.selectedPeriod
                        ) { period in
                            viewModel.setPeriod(period)
                        }

                        // Category Distribution
                        CategoryDistributionSection(
                            postDistribution: viewModel.postCategoryDistribution,
                            businessDistribution: viewModel.businessCategoryDistribution
                        )

                        // Popular Businesses
                        PopularBusinessesSection(businesses: viewModel.popularBusinesses)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("통계 대시보드")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.loadDashboard() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }
}

// MARK: - Stats Cards Section
struct StatsCardsSection: View {
    let cards: [StatCardData]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(cards) { card in
                StatCard(data: card)
            }
        }
    }
}

struct StatCard: View {
    let data: StatCardData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: data.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: data.color))

                Spacer()

                if let trend = data.trend, let trendValue = data.trendValue {
                    HStack(spacing: 2) {
                        Image(systemName: trend.icon)
                            .font(.caption2)
                        Text(trendValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(Color(hex: trend.color))
                }
            }

            Text(data.value)
                .font(.title2)
                .fontWeight(.bold)

            Text(data.title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}

// MARK: - Weekly Trend Section
struct WeeklyTrendSection: View {
    let trend: [DailyCount]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("주간 게시글 추이")
                .font(.headline)

            Chart(trend) { item in
                BarMark(
                    x: .value("날짜", item.dayLabel),
                    y: .value("게시글", item.count)
                )
                .foregroundStyle(Color(hex: "2563EB").gradient)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Popular Posts Section
struct PopularPostsSection: View {
    let posts: [PopularPostStats]
    @Binding var selectedPeriod: TimePeriod
    var onPeriodChange: (TimePeriod) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("인기 게시글")
                    .font(.headline)

                Spacer()

                Picker("기간", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedPeriod) { newValue in
                    onPeriodChange(newValue)
                }
            }

            if posts.isEmpty {
                Text("데이터가 없습니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                    PopularPostRow(rank: index + 1, post: post)

                    if index < posts.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PopularPostRow: View {
    let rank: Int
    let post: PopularPostStats

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(rankColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(post.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: post.category.color).opacity(0.2))
                        .foregroundStyle(Color(hex: post.category.color))
                        .clipShape(Capsule())

                    Text(post.authorName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                    Text("\(post.viewCount)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Label("\(post.likeCount)", systemImage: "heart")
                    Label("\(post.commentCount)", systemImage: "bubble.right")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Category Distribution Section
struct CategoryDistributionSection: View {
    let postDistribution: [CategoryDistribution]
    let businessDistribution: [CategoryDistribution]

    @State private var selectedTab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카테고리 분포")
                .font(.headline)

            Picker("", selection: $selectedTab) {
                Text("게시글").tag(0)
                Text("업소").tag(1)
            }
            .pickerStyle(.segmented)

            let distribution = selectedTab == 0 ? postDistribution : businessDistribution

            if distribution.isEmpty {
                Text("데이터가 없습니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Horizontal bar chart for distribution
                VStack(spacing: 8) {
                    ForEach(distribution) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: item.color))
                                .frame(width: 10, height: 10)

                            Text(item.category)
                                .font(.caption)
                                .frame(width: 60, alignment: .leading)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(.systemGray5))
                                        .frame(height: 16)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: item.color))
                                        .frame(width: geometry.size.width * CGFloat(item.percentage / 100), height: 16)
                                }
                            }
                            .frame(height: 16)

                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Popular Businesses Section
struct PopularBusinessesSection: View {
    let businesses: [PopularBusinessStats]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("인기 업소")
                .font(.headline)

            if businesses.isEmpty {
                Text("데이터가 없습니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(businesses.enumerated()), id: \.element.id) { index, business in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(index < 3 ? .yellow : .secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(business.name)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(business.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", business.rating))
                                .fontWeight(.medium)
                            Text("(\(business.reviewCount))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }

                    if index < businesses.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Dashboard Skeleton
struct DashboardSkeletonView: View {
    var body: some View {
        VStack(spacing: 20) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 100)
                        .shimmer()
                }
            }

            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .shimmer()

            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 300)
                .shimmer()
        }
    }
}

#Preview {
    StatsDashboardView()
}
