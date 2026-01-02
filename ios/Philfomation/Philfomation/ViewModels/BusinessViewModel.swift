//
//  BusinessViewModel.swift
//  Philfomation
//

import Foundation
import Combine

@MainActor
class BusinessViewModel: ObservableObject {
    @Published var businesses: [Business] = []
    @Published var selectedBusiness: Business?
    @Published var reviews: [Review] = []
    @Published var selectedCategory: BusinessCategory?
    @Published var searchQuery = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOfflineMode = false

    // MARK: - Private Properties
    private var blockedUserIds: Set<String> = []
    private let cacheManager = OfflineCacheManager.shared
    private let networkMonitor = NetworkMonitor.shared

    init() {
        Task {
            await fetchBusinesses()
        }
    }

    func fetchBusinesses() async {
        isLoading = true
        errorMessage = nil
        isOfflineMode = false

        // Check network connectivity
        if !networkMonitor.isConnected {
            // Load from cache when offline
            if let cachedBusinesses = cacheManager.loadBusinesses() {
                businesses = cachedBusinesses
                isOfflineMode = true
                errorMessage = nil
            } else {
                errorMessage = "오프라인 상태입니다. 캐시된 데이터가 없습니다."
            }
            isLoading = false
            return
        }

        do {
            businesses = try await FirestoreService.shared.getBusinesses(category: selectedCategory)
            // Save to cache for offline use
            cacheManager.saveBusinesses(businesses)
        } catch {
            // Try to load from cache on error
            if let cachedBusinesses = cacheManager.loadBusinesses() {
                businesses = cachedBusinesses
                isOfflineMode = true
            } else {
                errorMessage = "업소 목록을 불러오는데 실패했습니다."
            }
            print("Error fetching businesses: \(error)")
        }

        isLoading = false
    }

    func searchBusinesses() async {
        guard !searchQuery.isEmpty else {
            await fetchBusinesses()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            businesses = try await FirestoreService.shared.searchBusinesses(query: searchQuery)
        } catch {
            errorMessage = "검색에 실패했습니다."
            print("Error searching businesses: \(error)")
        }

        isLoading = false
    }

    func fetchBusiness(id: String) async {
        isLoading = true

        do {
            selectedBusiness = try await FirestoreService.shared.getBusiness(id: id)
        } catch {
            errorMessage = "업소 정보를 불러오는데 실패했습니다."
            print("Error fetching business: \(error)")
        }

        isLoading = false
    }

    func fetchReviews(businessId: String) async {
        do {
            reviews = try await FirestoreService.shared.getReviews(businessId: businessId)
        } catch {
            print("Error fetching reviews: \(error)")
        }
    }

    func addReview(_ review: Review) async -> Bool {
        isLoading = true

        do {
            _ = try await FirestoreService.shared.addReview(review)
            await fetchReviews(businessId: review.businessId)
            isLoading = false
            return true
        } catch {
            errorMessage = "리뷰 작성에 실패했습니다."
            print("Error adding review: \(error)")
            isLoading = false
            return false
        }
    }

    func deleteReview(id: String, businessId: String) async -> Bool {
        do {
            try await FirestoreService.shared.deleteReview(id: id)
            await fetchReviews(businessId: businessId)
            return true
        } catch {
            errorMessage = "리뷰 삭제에 실패했습니다."
            print("Error deleting review: \(error)")
            return false
        }
    }

    func setCategory(_ category: BusinessCategory?) {
        selectedCategory = category
        Task {
            await fetchBusinesses()
        }
    }

    var filteredBusinesses: [Business] {
        var result = businesses

        // 차단된 사용자 필터링
        if !blockedUserIds.isEmpty {
            result = BlockService.shared.filterBlockedBusinesses(result, blockedIds: blockedUserIds)
        }

        // 검색어 필터링
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.address.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        return result
    }

    // MARK: - Block Management
    func loadBlockedUsers(userId: String) async {
        blockedUserIds = await BlockService.shared.fetchBlockedUserIds(userId: userId)
    }

    func refreshBlockedUsers(userId: String) async {
        blockedUserIds = await BlockService.shared.fetchBlockedUserIds(userId: userId, forceRefresh: true)
    }
}
