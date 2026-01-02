//
//  PhilfomationWidget.swift
//  PhilfomationWidget
//

import WidgetKit
import SwiftUI

// MARK: - Exchange Rate Widget

struct ExchangeRateEntry: TimelineEntry {
    let date: Date
    let phpToKrw: Double
    let krwToPhp: Double
    let lastUpdated: String
}

struct ExchangeRateProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExchangeRateEntry {
        ExchangeRateEntry(
            date: Date(),
            phpToKrw: 24.5,
            krwToPhp: 0.041,
            lastUpdated: "방금 전"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ExchangeRateEntry) -> Void) {
        let entry = loadExchangeRate()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExchangeRateEntry>) -> Void) {
        let entry = loadExchangeRate()
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadExchangeRate() -> ExchangeRateEntry {
        let defaults = UserDefaults(suiteName: "group.com.philfomation.app")
        let phpToKrw = defaults?.double(forKey: "phpToKrw") ?? 24.5
        let krwToPhp = defaults?.double(forKey: "krwToPhp") ?? 0.041
        let lastUpdated = defaults?.string(forKey: "exchangeRateLastUpdated") ?? "업데이트 필요"

        return ExchangeRateEntry(
            date: Date(),
            phpToKrw: phpToKrw,
            krwToPhp: krwToPhp,
            lastUpdated: lastUpdated
        )
    }
}

struct ExchangeRateWidgetView: View {
    var entry: ExchangeRateEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallExchangeRateView(entry: entry)
        case .systemMedium:
            MediumExchangeRateView(entry: entry)
        default:
            SmallExchangeRateView(entry: entry)
        }
    }
}

struct SmallExchangeRateView: View {
    var entry: ExchangeRateEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "wonsign.circle.fill")
                    .foregroundStyle(.blue)
                Text("환율")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("1 PHP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("₩\(String(format: "%.1f", entry.phpToKrw))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("₩1,000")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("₱\(String(format: "%.1f", entry.krwToPhp * 1000))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            Text(entry.lastUpdated)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumExchangeRateView: View {
    var entry: ExchangeRateEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wonsign.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("환율 정보")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Text("Philfomation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("PHP → KRW")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("₩\(String(format: "%.2f", entry.phpToKrw))")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("KRW → PHP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("₱\(String(format: "%.4f", entry.krwToPhp))")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }

                Text("업데이트: \(entry.lastUpdated)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ExchangeRateWidget: Widget {
    let kind: String = "ExchangeRateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExchangeRateProvider()) { entry in
            ExchangeRateWidgetView(entry: entry)
        }
        .configurationDisplayName("환율 정보")
        .description("PHP/KRW 환율을 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Popular Posts Widget

struct PopularPostEntry: TimelineEntry {
    let date: Date
    let posts: [WidgetPost]
}

struct WidgetPost: Identifiable {
    let id: String
    let title: String
    let category: String
    let likeCount: Int
}

struct PopularPostsProvider: TimelineProvider {
    func placeholder(in context: Context) -> PopularPostEntry {
        PopularPostEntry(date: Date(), posts: samplePosts)
    }

    func getSnapshot(in context: Context, completion: @escaping (PopularPostEntry) -> Void) {
        let entry = loadPopularPosts()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PopularPostEntry>) -> Void) {
        let entry = loadPopularPosts()
        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadPopularPosts() -> PopularPostEntry {
        let defaults = UserDefaults(suiteName: "group.com.philfomation.app")

        if let data = defaults?.data(forKey: "popularPosts"),
           let decoded = try? JSONDecoder().decode([WidgetPostData].self, from: data) {
            let posts = decoded.map { WidgetPost(id: $0.id, title: $0.title, category: $0.category, likeCount: $0.likeCount) }
            return PopularPostEntry(date: Date(), posts: posts)
        }

        return PopularPostEntry(date: Date(), posts: samplePosts)
    }

    private var samplePosts: [WidgetPost] {
        [
            WidgetPost(id: "1", title: "마닐라 맛집 추천", category: "맛집", likeCount: 42),
            WidgetPost(id: "2", title: "보라카이 여행 후기", category: "여행", likeCount: 38),
            WidgetPost(id: "3", title: "필리핀 생활 꿀팁", category: "생활", likeCount: 25)
        ]
    }
}

struct WidgetPostData: Codable {
    let id: String
    let title: String
    let category: String
    let likeCount: Int
}

struct PopularPostsWidgetView: View {
    var entry: PopularPostEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("인기 게시글")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            ForEach(entry.posts.prefix(3)) { post in
                HStack(spacing: 8) {
                    Text(post.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())

                    Text(post.title)
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                        Text("\(post.likeCount)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct PopularPostsWidget: Widget {
    let kind: String = "PopularPostsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PopularPostsProvider()) { entry in
            PopularPostsWidgetView(entry: entry)
        }
        .configurationDisplayName("인기 게시글")
        .description("커뮤니티 인기 게시글을 확인하세요")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct PhilfomationWidgetBundle: WidgetBundle {
    var body: some Widget {
        ExchangeRateWidget()
        PopularPostsWidget()
    }
}

#Preview(as: .systemSmall) {
    ExchangeRateWidget()
} timeline: {
    ExchangeRateEntry(date: Date(), phpToKrw: 24.5, krwToPhp: 0.041, lastUpdated: "방금 전")
}

#Preview(as: .systemMedium) {
    PopularPostsWidget()
} timeline: {
    PopularPostEntry(date: Date(), posts: [
        WidgetPost(id: "1", title: "마닐라 맛집 추천", category: "맛집", likeCount: 42),
        WidgetPost(id: "2", title: "보라카이 여행 후기", category: "여행", likeCount: 38),
        WidgetPost(id: "3", title: "필리핀 생활 꿀팁", category: "생활", likeCount: 25)
    ])
}
