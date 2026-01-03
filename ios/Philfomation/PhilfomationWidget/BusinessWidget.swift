//
//  BusinessWidget.swift
//  PhilfomationWidget
//

import WidgetKit
import SwiftUI

// MARK: - Business Widget Entry
struct BusinessEntry: TimelineEntry {
    let date: Date
    let businesses: [WidgetBusiness]
}

struct WidgetBusiness: Identifiable {
    let id: String
    let name: String
    let category: String
    let categoryIcon: String
    let categoryColor: String
    let rating: Double
    let reviewCount: Int
    let distance: String?
}

// MARK: - Business Intent
struct BusinessWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "업소 위젯"
    static var description = IntentDescription("인기 업소를 확인하세요")
}

// MARK: - Timeline Provider
struct BusinessProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> BusinessEntry {
        BusinessEntry(date: Date(), businesses: sampleBusinesses)
    }

    func snapshot(for configuration: BusinessWidgetIntent, in context: Context) async -> BusinessEntry {
        BusinessEntry(date: Date(), businesses: sampleBusinesses)
    }

    func timeline(for configuration: BusinessWidgetIntent, in context: Context) async -> Timeline<BusinessEntry> {
        let businesses = await fetchBusinesses()
        let entry = BusinessEntry(date: Date(), businesses: businesses)

        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchBusinesses() async -> [WidgetBusiness] {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.philfomation.app"),
           let data = sharedDefaults.data(forKey: "popularBusinesses"),
           let businesses = try? JSONDecoder().decode([WidgetBusinessData].self, from: data) {
            return businesses.map { b in
                WidgetBusiness(
                    id: b.id,
                    name: b.name,
                    category: b.category,
                    categoryIcon: b.categoryIcon,
                    categoryColor: b.categoryColor,
                    rating: b.rating,
                    reviewCount: b.reviewCount,
                    distance: b.distance
                )
            }
        }
        return sampleBusinesses
    }

    private var sampleBusinesses: [WidgetBusiness] {
        [
            WidgetBusiness(id: "1", name: "코리안 헤어샵", category: "미용실", categoryIcon: "scissors", categoryColor: "8B5CF6", rating: 4.7, reviewCount: 62, distance: "1.2km"),
            WidgetBusiness(id: "2", name: "한식당 서울", category: "음식점", categoryIcon: "fork.knife", categoryColor: "F97316", rating: 4.5, reviewCount: 28, distance: "0.8km"),
            WidgetBusiness(id: "3", name: "K-마트", category: "마트", categoryIcon: "cart.fill", categoryColor: "22C55E", rating: 4.2, reviewCount: 45, distance: "2.5km")
        ]
    }
}

// MARK: - Shared Data Model
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

// MARK: - Widget Views
struct BusinessWidgetEntryView: View {
    var entry: BusinessProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallBusinessView(business: entry.businesses.first)
        case .systemMedium:
            MediumBusinessView(businesses: Array(entry.businesses.prefix(2)))
        case .systemLarge:
            LargeBusinessView(businesses: Array(entry.businesses.prefix(4)))
        default:
            SmallBusinessView(business: entry.businesses.first)
        }
    }
}

struct SmallBusinessView: View {
    let business: WidgetBusiness?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(Color(hex: "7C3AED"))
                Text("업소")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            if let business = business {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: business.categoryIcon)
                            .font(.caption2)
                            .foregroundStyle(Color(hex: business.categoryColor))
                        Text(business.category)
                            .font(.caption2)
                            .foregroundStyle(Color(hex: business.categoryColor))
                    }

                    Text(business.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    Spacer()

                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", business.rating))
                            .fontWeight(.medium)
                        Text("(\(business.reviewCount))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
    }
}

struct MediumBusinessView: View {
    let businesses: [WidgetBusiness]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(Color(hex: "7C3AED"))
                Text("인기 업소")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                ForEach(businesses) { business in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: business.categoryIcon)
                                .font(.caption2)
                            Text(business.category)
                                .font(.caption2)
                        }
                        .foregroundStyle(Color(hex: business.categoryColor))

                        Text(business.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", business.rating))
                                .fontWeight(.medium)
                            if let distance = business.distance {
                                Text("• \(distance)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if business.id != businesses.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
    }
}

struct LargeBusinessView: View {
    let businesses: [WidgetBusiness]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(Color(hex: "7C3AED"))
                Text("인기 업소")
                    .font(.headline)
                Spacer()
                Text("Top \(businesses.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(businesses.enumerated()), id: \.element.id) { index, business in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(index < 3 ? .yellow : .secondary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(business.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Image(systemName: business.categoryIcon)
                            Text(business.category)
                        }
                        .font(.caption2)
                        .foregroundStyle(Color(hex: business.categoryColor))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", business.rating))
                                .fontWeight(.medium)
                        }
                        .font(.caption)

                        if let distance = business.distance {
                            Text(distance)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if index < businesses.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
    }
}

// MARK: - Widget Definition
struct BusinessWidget: Widget {
    let kind: String = "BusinessWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: BusinessWidgetIntent.self, provider: BusinessProvider()) { entry in
            BusinessWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("인기 업소")
        .description("인기 업소를 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    BusinessWidget()
} timeline: {
    BusinessEntry(date: .now, businesses: [
        WidgetBusiness(id: "1", name: "코리안 헤어샵", category: "미용실", categoryIcon: "scissors", categoryColor: "8B5CF6", rating: 4.7, reviewCount: 62, distance: "1.2km"),
        WidgetBusiness(id: "2", name: "한식당 서울", category: "음식점", categoryIcon: "fork.knife", categoryColor: "F97316", rating: 4.5, reviewCount: 28, distance: "0.8km")
    ])
}
