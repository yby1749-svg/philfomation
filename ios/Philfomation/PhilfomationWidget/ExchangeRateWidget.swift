//
//  ExchangeRateWidget.swift
//  PhilfomationWidget
//

import WidgetKit
import SwiftUI

// MARK: - Exchange Rate Entry
struct ExchangeRateEntry: TimelineEntry {
    let date: Date
    let krwToPhp: Double
    let phpToKrw: Double
    let lastUpdated: String
    let trend: ExchangeTrend
}

enum ExchangeTrend {
    case up, down, stable

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .up: return .red
        case .down: return .green
        case .stable: return .gray
        }
    }
}

// MARK: - Exchange Rate Intent
struct ExchangeRateIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "환율 위젯"
    static var description = IntentDescription("KRW-PHP 환율을 확인하세요")
}

// MARK: - Timeline Provider
struct ExchangeRateProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ExchangeRateEntry {
        ExchangeRateEntry(date: Date(), krwToPhp: 0.042, phpToKrw: 23.8, lastUpdated: "방금 전", trend: .stable)
    }

    func snapshot(for configuration: ExchangeRateIntent, in context: Context) async -> ExchangeRateEntry {
        ExchangeRateEntry(date: Date(), krwToPhp: 0.042, phpToKrw: 23.8, lastUpdated: "방금 전", trend: .stable)
    }

    func timeline(for configuration: ExchangeRateIntent, in context: Context) async -> Timeline<ExchangeRateEntry> {
        let rate = await fetchExchangeRate()
        let entry = ExchangeRateEntry(
            date: Date(),
            krwToPhp: rate.krwToPhp,
            phpToKrw: rate.phpToKrw,
            lastUpdated: rate.lastUpdated,
            trend: rate.trend
        )

        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchExchangeRate() async -> (krwToPhp: Double, phpToKrw: Double, lastUpdated: String, trend: ExchangeTrend) {
        // Try to load from shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.philfomation.app") {
            let krwToPhp = sharedDefaults.double(forKey: "exchangeRate_KRW_PHP")
            let phpToKrw = sharedDefaults.double(forKey: "exchangeRate_PHP_KRW")
            let lastUpdated = sharedDefaults.string(forKey: "exchangeRate_lastUpdated") ?? "알 수 없음"
            let trendRaw = sharedDefaults.string(forKey: "exchangeRate_trend") ?? "stable"

            let trend: ExchangeTrend
            switch trendRaw {
            case "up": trend = .up
            case "down": trend = .down
            default: trend = .stable
            }

            if krwToPhp > 0 && phpToKrw > 0 {
                return (krwToPhp, phpToKrw, lastUpdated, trend)
            }
        }

        // Default values
        return (0.042, 23.8, "업데이트 필요", .stable)
    }
}

// MARK: - Widget Views
struct ExchangeRateWidgetEntryView: View {
    var entry: ExchangeRateProvider.Entry
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
    let entry: ExchangeRateEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "wonsign.circle.fill")
                    .foregroundStyle(Color(hex: "22C55E"))
                Text("환율")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: entry.trend.icon)
                    .font(.caption)
                    .foregroundStyle(entry.trend.color)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("₩1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("=")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(String(format: "₱%.3f", entry.krwToPhp))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "2563EB"))
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("₱1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("=")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(String(format: "₩%.1f", entry.phpToKrw))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            Text(entry.lastUpdated)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

struct MediumExchangeRateView: View {
    let entry: ExchangeRateEntry

    var body: some View {
        HStack(spacing: 16) {
            // KRW to PHP
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🇰🇷")
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    Text("🇵🇭")
                }
                .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("₩10,000")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "₱%.0f", 10000 * entry.krwToPhp))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "2563EB"))
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            // PHP to KRW
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🇵🇭")
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    Text("🇰🇷")
                }
                .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("₱1,000")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "₩%.0f", 1000 * entry.phpToKrw))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: "22C55E"))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 4) {
                Image(systemName: entry.trend.icon)
                    .foregroundStyle(entry.trend.color)
                Text(entry.lastUpdated)
                    .foregroundStyle(.tertiary)
            }
            .font(.caption2)
            .padding(8)
        }
    }
}

// MARK: - Widget Definition
struct ExchangeRateWidget: Widget {
    let kind: String = "ExchangeRateWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ExchangeRateIntent.self, provider: ExchangeRateProvider()) { entry in
            ExchangeRateWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("환율 계산기")
        .description("KRW-PHP 환율을 실시간으로 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ExchangeRateWidget()
} timeline: {
    ExchangeRateEntry(date: .now, krwToPhp: 0.042, phpToKrw: 23.8, lastUpdated: "1시간 전", trend: .up)
}
