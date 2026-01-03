//
//  LiveActivity.swift
//  PhilfomationWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Attributes
struct ExchangeRateLiveActivity: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var krwToPhp: Double
        var phpToKrw: Double
        var trend: String // "up", "down", "stable"
        var lastUpdated: String
    }

    var baseCurrency: String
    var targetCurrency: String
}

// MARK: - Live Activity Widget
struct ExchangeRateLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ExchangeRateLiveActivity.self) { context in
            // Lock screen / banner view
            ExchangeRateLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Text("🇰🇷")
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                        Text("🇵🇭")
                    }
                    .font(.caption)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        Text("🇵🇭")
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                        Text("🇰🇷")
                    }
                    .font(.caption)
                }

                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 16) {
                        VStack {
                            Text("₩10,000")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(String(format: "₱%.0f", 10000 * context.state.krwToPhp))
                                .font(.headline)
                                .fontWeight(.bold)
                        }

                        VStack {
                            Text("₱1,000")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(String(format: "₩%.0f", 1000 * context.state.phpToKrw))
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: trendIcon(context.state.trend))
                            .foregroundStyle(trendColor(context.state.trend))
                        Text("업데이트: \(context.state.lastUpdated)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                HStack(spacing: 2) {
                    Image(systemName: "wonsign.circle.fill")
                        .foregroundStyle(.green)
                    Image(systemName: trendIcon(context.state.trend))
                        .font(.caption2)
                        .foregroundStyle(trendColor(context.state.trend))
                }
            } compactTrailing: {
                Text(String(format: "₱%.2f", context.state.krwToPhp * 1000))
                    .font(.caption)
                    .fontWeight(.semibold)
            } minimal: {
                Image(systemName: "wonsign.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private func trendIcon(_ trend: String) -> String {
        switch trend {
        case "up": return "arrow.up.right"
        case "down": return "arrow.down.right"
        default: return "arrow.right"
        }
    }

    private func trendColor(_ trend: String) -> Color {
        switch trend {
        case "up": return .red
        case "down": return .green
        default: return .gray
        }
    }
}

// MARK: - Lock Screen View
struct ExchangeRateLockScreenView: View {
    let context: ActivityViewContext<ExchangeRateLiveActivity>

    var body: some View {
        HStack(spacing: 16) {
            // KRW to PHP
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("🇰🇷")
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    Text("🇵🇭")
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("₩10,000")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "₱%.0f", 10000 * context.state.krwToPhp))
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }

            Divider()
                .frame(height: 50)

            // PHP to KRW
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("🇵🇭")
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    Text("🇰🇷")
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("₱1,000")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "₩%.0f", 1000 * context.state.phpToKrw))
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }

            Spacer()

            // Trend indicator
            VStack {
                Image(systemName: trendIcon)
                    .font(.title2)
                    .foregroundStyle(trendColor)
                Text(context.state.lastUpdated)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.8))
    }

    private var trendIcon: String {
        switch context.state.trend {
        case "up": return "arrow.up.right.circle.fill"
        case "down": return "arrow.down.right.circle.fill"
        default: return "arrow.right.circle.fill"
        }
    }

    private var trendColor: Color {
        switch context.state.trend {
        case "up": return .red
        case "down": return .green
        default: return .gray
        }
    }
}

// MARK: - Community Live Activity
struct NewPostLiveActivity: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var postTitle: String
        var authorName: String
        var category: String
        var categoryColor: String
        var likeCount: Int
        var commentCount: Int
    }

    var postId: String
}

struct NewPostLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NewPostLiveActivity.self) { context in
            // Lock screen view
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: "2563EB"))

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.state.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: context.state.categoryColor).opacity(0.2))
                        .foregroundStyle(Color(hex: context.state.categoryColor))
                        .clipShape(Capsule())

                    Text(context.state.postTitle)
                        .font(.headline)
                        .lineLimit(1)

                    Text("by \(context.state.authorName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                        Text("\(context.state.likeCount)")
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right.fill")
                        Text("\(context.state.commentCount)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.8))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(Color(hex: "2563EB"))
                }

                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 8) {
                        Label("\(context.state.likeCount)", systemImage: "heart.fill")
                        Label("\(context.state.commentCount)", systemImage: "bubble.right.fill")
                    }
                    .font(.caption)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.postTitle)
                        .font(.headline)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: context.state.categoryColor).opacity(0.2))
                            .foregroundStyle(Color(hex: context.state.categoryColor))
                            .clipShape(Capsule())

                        Spacer()

                        Text("by \(context.state.authorName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundStyle(Color(hex: "2563EB"))
            } compactTrailing: {
                Text("\(context.state.likeCount) ❤️")
                    .font(.caption)
            } minimal: {
                Image(systemName: "bubble.left.fill")
                    .foregroundStyle(Color(hex: "2563EB"))
            }
        }
    }
}
