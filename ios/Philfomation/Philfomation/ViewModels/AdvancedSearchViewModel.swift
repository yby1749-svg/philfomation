//
//  AdvancedSearchViewModel.swift
//  Philfomation
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class AdvancedSearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchQuery = ""
    @Published var searchType: AdvancedSearchType = .all
    @Published var isSearching = false
    @Published var isLoading = false

    // Filters
    @Published var dateFilter: DateFilter = .all
    @Published var selectedPostCategory: PostCategory?
    @Published var selectedBusinessCategory: BusinessCategory?
    @Published var ratingFilter: RatingFilter = .all
    @Published var sortOption: SortOption = .latest

    // Results
    @Published var postResults: [Post] = []
    @Published var businessResults: [Business] = []

    // UI State
    @Published var showFilterSheet = false
    @Published var showDateFilterPicker = false
    @Published var showSortPicker = false

    // Recent & Popular Searches
    @Published var recentSearches: [String] = []
    @Published var popularSearches: [String] = [
        "마닐라 맛집",
        "세부 여행",
        "한인 마트",
        "마사지",
        "헤어샵"
    ]

    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let recentSearchesKey = "recentSearches"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        loadRecentSearches()
        setupSearchDebounce()
    }

    // MARK: - Search Methods
    func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            postResults = []
            businessResults = []
            return
        }

        isLoading = true
        isSearching = true
        saveRecentSearch(searchQuery)

        Task {
            async let posts = searchPosts()
            async let businesses = searchBusinesses()

            if searchType != .businesses {
                postResults = await posts
            } else {
                postResults = []
            }

            if searchType != .posts {
                businessResults = await businesses
            } else {
                businessResults = []
            }

            isLoading = false
        }
    }

    private func searchPosts() async -> [Post] {
        do {
            var query: Query = db.collection("posts")

            // Category filter
            if let category = selectedPostCategory {
                query = query.whereField("category", isEqualTo: category.rawValue)
            }

            // Date filter
            if let startDate = dateFilter.startDate {
                query = query.whereField("createdAt", isGreaterThan: Timestamp(date: startDate))
            }

            // Sort
            switch sortOption {
            case .latest:
                query = query.order(by: "createdAt", descending: true)
            case .popular:
                query = query.order(by: "likeCount", descending: true)
            case .rating:
                query = query.order(by: "likeCount", descending: true)
            }

            query = query.limit(to: 50)

            let snapshot = try await query.getDocuments()
            let searchLower = searchQuery.lowercased()

            return snapshot.documents.compactMap { doc -> Post? in
                guard let post = try? doc.data(as: Post.self) else { return nil }

                // Client-side text search
                if post.title.lowercased().contains(searchLower) ||
                   post.content.lowercased().contains(searchLower) ||
                   post.authorName.lowercased().contains(searchLower) {
                    return post
                }
                return nil
            }
        } catch {
            print("Error searching posts: \(error)")
            return []
        }
    }

    private func searchBusinesses() async -> [Business] {
        do {
            var query: Query = db.collection("businesses")

            // Category filter
            if let category = selectedBusinessCategory {
                query = query.whereField("category", isEqualTo: category.rawValue)
            }

            // Rating filter
            if ratingFilter != .all {
                query = query.whereField("rating", isGreaterThanOrEqualTo: ratingFilter.minRating)
            }

            // Sort
            switch sortOption {
            case .latest:
                query = query.order(by: "createdAt", descending: true)
            case .popular:
                query = query.order(by: "reviewCount", descending: true)
            case .rating:
                query = query.order(by: "rating", descending: true)
            }

            query = query.limit(to: 50)

            let snapshot = try await query.getDocuments()
            let searchLower = searchQuery.lowercased()

            return snapshot.documents.compactMap { doc -> Business? in
                guard let business = try? doc.data(as: Business.self) else { return nil }

                // Client-side text search
                if business.name.lowercased().contains(searchLower) ||
                   (business.description?.lowercased().contains(searchLower) ?? false) ||
                   business.address.lowercased().contains(searchLower) {
                    return business
                }
                return nil
            }
        } catch {
            print("Error searching businesses: \(error)")
            return []
        }
    }

    // MARK: - Filter Methods
    func resetFilters() {
        dateFilter = .all
        selectedPostCategory = nil
        selectedBusinessCategory = nil
        ratingFilter = .all
        sortOption = .latest
    }

    // MARK: - Recent Searches
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentSearchesKey) ?? []
    }

    private func saveRecentSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        // Remove if exists, add to front
        recentSearches.removeAll { $0 == trimmed }
        recentSearches.insert(trimmed, at: 0)

        // Keep only last 10
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }

        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }

    func deleteRecentSearch(at indexSet: IndexSet) {
        recentSearches.remove(atOffsets: indexSet)
        UserDefaults.standard.set(recentSearches, forKey: recentSearchesKey)
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }

    // MARK: - Debounce Setup
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.performSearch()
                }
            }
            .store(in: &cancellables)
    }
}
