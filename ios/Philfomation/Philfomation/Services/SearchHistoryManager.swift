//
//  SearchHistoryManager.swift
//  Philfomation
//

import Foundation
import Combine

enum SearchType: String {
    case business
    case community
}

class SearchHistoryManager: ObservableObject {
    static let shared = SearchHistoryManager()

    private let maxHistoryCount = 10
    private let businessHistoryKey = "businessSearchHistory"
    private let communityHistoryKey = "communitySearchHistory"

    @Published var businessHistory: [String] = []
    @Published var communityHistory: [String] = []

    private init() {
        loadHistory()
    }

    // MARK: - Load History

    private func loadHistory() {
        businessHistory = UserDefaults.standard.stringArray(forKey: businessHistoryKey) ?? []
        communityHistory = UserDefaults.standard.stringArray(forKey: communityHistoryKey) ?? []
    }

    // MARK: - Add Search Query

    func addSearch(_ query: String, type: SearchType) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        switch type {
        case .business:
            // Remove if already exists (to move to top)
            businessHistory.removeAll { $0.lowercased() == trimmedQuery.lowercased() }
            // Insert at beginning
            businessHistory.insert(trimmedQuery, at: 0)
            // Limit count
            if businessHistory.count > maxHistoryCount {
                businessHistory = Array(businessHistory.prefix(maxHistoryCount))
            }
            UserDefaults.standard.set(businessHistory, forKey: businessHistoryKey)

        case .community:
            communityHistory.removeAll { $0.lowercased() == trimmedQuery.lowercased() }
            communityHistory.insert(trimmedQuery, at: 0)
            if communityHistory.count > maxHistoryCount {
                communityHistory = Array(communityHistory.prefix(maxHistoryCount))
            }
            UserDefaults.standard.set(communityHistory, forKey: communityHistoryKey)
        }
    }

    // MARK: - Remove Single Item

    func removeSearch(_ query: String, type: SearchType) {
        switch type {
        case .business:
            businessHistory.removeAll { $0 == query }
            UserDefaults.standard.set(businessHistory, forKey: businessHistoryKey)

        case .community:
            communityHistory.removeAll { $0 == query }
            UserDefaults.standard.set(communityHistory, forKey: communityHistoryKey)
        }
    }

    // MARK: - Clear History

    func clearHistory(type: SearchType) {
        switch type {
        case .business:
            businessHistory.removeAll()
            UserDefaults.standard.removeObject(forKey: businessHistoryKey)

        case .community:
            communityHistory.removeAll()
            UserDefaults.standard.removeObject(forKey: communityHistoryKey)
        }
    }

    func clearAllHistory() {
        businessHistory.removeAll()
        communityHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: businessHistoryKey)
        UserDefaults.standard.removeObject(forKey: communityHistoryKey)
    }

    // MARK: - Get History

    func getHistory(for type: SearchType) -> [String] {
        switch type {
        case .business:
            return businessHistory
        case .community:
            return communityHistory
        }
    }
}
