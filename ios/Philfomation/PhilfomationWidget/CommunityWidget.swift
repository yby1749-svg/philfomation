//
//  CommunityWidget.swift
//  PhilfomationWidget
//

import WidgetKit
import SwiftUI

// MARK: - Community Widget Entry
struct CommunityEntry: TimelineEntry {
    let date: Date
    let posts: [WidgetPost]
    let configuration: ConfigurationAppIntent
}

struct WidgetPost: Identifiable {
    let id: String
    let title: String
    let category: String
    let categoryColor: String
    let authorName: String
    let likeCount: Int
    let commentCount: Int
    let timeAgo: String
}

// MARK: - Configuration Intent
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "커뮤니티 위젯"
    static var description = IntentDescription("최신 커뮤니티 게시글을 확인하세요")
}

// MARK: - Timeline Provider
struct CommunityProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CommunityEntry {
        CommunityEntry(date: Date(), posts: samplePosts, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> CommunityEntry {
        CommunityEntry(date: Date(), posts: samplePosts, configuration: configuration)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CommunityEntry> {
        // Fetch latest posts from shared data
        let posts = await fetchLatestPosts()
        let entry = CommunityEntry(date: Date(), posts: posts, configuration: configuration)

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchLatestPosts() async -> [WidgetPost] {
        // Try to load from shared UserDefaults (App Group)
        if let sharedDefaults = UserDefaults(suiteName: "group.com.philfomation.app"),
           let data = sharedDefaults.data(forKey: "latestPosts"),
           let posts = try? JSONDecoder().decode([WidgetPostData].self, from: data) {
            return posts.map { post in
                WidgetPost(
                    id: post.id,
                    title: post.title,
                    category: post.category,
                    categoryColor: post.categoryColor,
                    authorName: post.authorName,
                    likeCount: post.likeCount,
                    commentCount: post.commentCount,
                    timeAgo: post.timeAgo
                )
            }
        }
        return samplePosts
    }

    private var samplePosts: [WidgetPost] {
        [
            WidgetPost(id: "1", title: "마닐라 맛집 추천", category: "맛집", categoryColor: "F97316", authorName: "김철수", likeCount: 15, commentCount: 8, timeAgo: "1시간 전"),
            WidgetPost(id: "2", title: "세부 여행 팁 공유", category: "여행", categoryColor: "3B82F6", authorName: "이영희", likeCount: 23, commentCount: 12, timeAgo: "3시간 전"),
            WidgetPost(id: "3", title: "필리핀 생활 질문", category: "질문", categoryColor: "8B5CF6", authorName: "박민수", likeCount: 5, commentCount: 3, timeAgo: "5시간 전")
        ]
    }
}

// MARK: - Shared Data Model
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

// MARK: - Widget Views
struct CommunityWidgetEntryView: View {
    var entry: CommunityProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallCommunityView(post: entry.posts.first)
        case .systemMedium:
            MediumCommunityView(posts: Array(entry.posts.prefix(2)))
        case .systemLarge:
            LargeCommunityView(posts: Array(entry.posts.prefix(4)))
        default:
            SmallCommunityView(post: entry.posts.first)
        }
    }
}

struct SmallCommunityView: View {
    let post: WidgetPost?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(Color(hex: "2563EB"))
                Text("커뮤니티")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            if let post = post {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: post.categoryColor).opacity(0.2))
                        .foregroundStyle(Color(hex: post.categoryColor))
                        .clipShape(Capsule())

                    Text(post.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    Spacer()

                    HStack {
                        Label("\(post.likeCount)", systemImage: "heart")
                        Label("\(post.commentCount)", systemImage: "bubble.right")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            } else {
                Text("게시글 없음")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct MediumCommunityView: View {
    let posts: [WidgetPost]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(Color(hex: "2563EB"))
                Text("커뮤니티")
                    .font(.headline)
                Spacer()
                Text("최신글")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(posts) { post in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(post.category)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: post.categoryColor).opacity(0.2))
                                .foregroundStyle(Color(hex: post.categoryColor))
                                .clipShape(Capsule())

                            Text(post.timeAgo)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Text(post.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Label("\(post.likeCount)", systemImage: "heart")
                        Label("\(post.commentCount)", systemImage: "bubble.right")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}

struct LargeCommunityView: View {
    let posts: [WidgetPost]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(Color(hex: "2563EB"))
                Text("커뮤니티")
                    .font(.headline)
                Spacer()
                Text("최신글")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(posts) { post in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(post.category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: post.categoryColor).opacity(0.2))
                            .foregroundStyle(Color(hex: post.categoryColor))
                            .clipShape(Capsule())

                        Spacer()

                        Text(post.timeAgo)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Text(post.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack {
                        Text(post.authorName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        HStack(spacing: 8) {
                            Label("\(post.likeCount)", systemImage: "heart")
                            Label("\(post.commentCount)", systemImage: "bubble.right")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if post.id != posts.last?.id {
                    Divider()
                }
            }
        }
        .padding()
    }
}

// MARK: - Widget Definition
struct CommunityWidget: Widget {
    let kind: String = "CommunityWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: CommunityProvider()) { entry in
            CommunityWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("커뮤니티")
        .description("최신 커뮤니티 게시글을 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Color Extension for Widget
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview(as: .systemSmall) {
    CommunityWidget()
} timeline: {
    CommunityEntry(date: .now, posts: [
        WidgetPost(id: "1", title: "마닐라 맛집 추천합니다!", category: "맛집", categoryColor: "F97316", authorName: "김철수", likeCount: 15, commentCount: 8, timeAgo: "1시간 전")
    ], configuration: ConfigurationAppIntent())
}
