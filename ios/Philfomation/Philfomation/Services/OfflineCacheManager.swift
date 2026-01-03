//
//  OfflineCacheManager.swift
//  Philfomation
//

import Foundation
import Combine

class OfflineCacheManager: ObservableObject {
    static let shared = OfflineCacheManager()

    @Published var isOfflineMode = false
    @Published var lastCacheUpdate: Date?

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let networkMonitor = NetworkMonitor.shared
    private var cancellables = Set<AnyCancellable>()

    // Cache settings
    private let maxCacheSize: Int64 = 100 * 1024 * 1024  // 100 MB
    private let defaultCacheAge: TimeInterval = 24 * 3600  // 24 hours

    private init() {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access document directory")
        }
        cacheDirectory = documentsDirectory.appendingPathComponent("OfflineCache", isDirectory: true)

        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }

        setupNetworkObserver()
        loadLastCacheUpdate()
    }

    // MARK: - Network Observer

    private func setupNetworkObserver() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOfflineMode = !isConnected
            }
            .store(in: &cancellables)

        isOfflineMode = !networkMonitor.isConnected
    }

    private func loadLastCacheUpdate() {
        lastCacheUpdate = UserDefaults.standard.object(forKey: "lastCacheUpdate") as? Date
    }

    private func saveLastCacheUpdate() {
        lastCacheUpdate = Date()
        UserDefaults.standard.set(lastCacheUpdate, forKey: "lastCacheUpdate")
    }

    // MARK: - Generic Cache Methods

    func save<T: Encodable>(_ data: T, forKey key: CacheKey) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.rawValue).json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: fileURL)

            // Save timestamp
            saveTimestamp(for: key)
        } catch {
            print("Failed to save cache for \(key.rawValue): \(error)")
        }
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: CacheKey) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.rawValue).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: jsonData)
        } catch {
            print("Failed to load cache for \(key.rawValue): \(error)")
            return nil
        }
    }

    func remove(forKey key: CacheKey) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.rawValue).json")
        try? fileManager.removeItem(at: fileURL)
        removeTimestamp(for: key)
    }

    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        UserDefaults.standard.removeObject(forKey: "cacheTimestamps")
    }

    // MARK: - Cache Validity

    func isCacheValid(forKey key: CacheKey, maxAge: TimeInterval = 3600) -> Bool {
        guard let timestamp = getTimestamp(for: key) else {
            return false
        }
        return Date().timeIntervalSince(timestamp) < maxAge
    }

    private func saveTimestamp(for key: CacheKey) {
        var timestamps = UserDefaults.standard.dictionary(forKey: "cacheTimestamps") as? [String: Date] ?? [:]
        timestamps[key.rawValue] = Date()
        UserDefaults.standard.set(timestamps, forKey: "cacheTimestamps")
    }

    private func getTimestamp(for key: CacheKey) -> Date? {
        let timestamps = UserDefaults.standard.dictionary(forKey: "cacheTimestamps") as? [String: Date]
        return timestamps?[key.rawValue]
    }

    private func removeTimestamp(for key: CacheKey) {
        var timestamps = UserDefaults.standard.dictionary(forKey: "cacheTimestamps") as? [String: Date] ?? [:]
        timestamps.removeValue(forKey: key.rawValue)
        UserDefaults.standard.set(timestamps, forKey: "cacheTimestamps")
    }

    // MARK: - Cache Size

    var cacheSize: Int64 {
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            totalSize += Int64(fileSize)
        }
        return totalSize
    }

    var formattedCacheSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: cacheSize)
    }

    // MARK: - Automatic Cache Cleanup

    func cleanupIfNeeded() {
        if cacheSize > maxCacheSize {
            cleanupOldestFiles(targetSize: maxCacheSize / 2)
        }
    }

    private func cleanupOldestFiles(targetSize: Int64) {
        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else { return }

        var files: [(url: URL, date: Date, size: Int64)] = []

        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
               let date = values.contentModificationDate,
               let size = values.fileSize {
                files.append((fileURL, date, Int64(size)))
            }
        }

        // Sort by date (oldest first)
        files.sort { $0.date < $1.date }

        var currentSize = cacheSize
        for file in files {
            if currentSize <= targetSize { break }
            try? fileManager.removeItem(at: file.url)
            currentSize -= file.size
        }
    }

    func cleanupExpiredCache(maxAge: TimeInterval? = nil) {
        let age = maxAge ?? defaultCacheAge
        let expiredDate = Date().addingTimeInterval(-age)

        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }

        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
               let date = values.contentModificationDate,
               date < expiredDate {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    // MARK: - Cache Status

    var lastUpdateFormatted: String? {
        guard let date = lastCacheUpdate else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func getCacheInfo(forKey key: CacheKey) -> CacheInfo? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.rawValue).json")

        guard fileManager.fileExists(atPath: fileURL.path),
              let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path) else {
            return nil
        }

        let size = (attributes[.size] as? Int64) ?? 0
        let modDate = (attributes[.modificationDate] as? Date) ?? Date()

        return CacheInfo(
            key: key,
            size: size,
            lastModified: modDate,
            isValid: isCacheValid(forKey: key)
        )
    }

    var allCacheInfo: [CacheInfo] {
        CacheKey.allCases.compactMap { getCacheInfo(forKey: $0) }
    }

    // MARK: - Prefetch Data for Offline

    func prefetchForOffline() async {
        guard networkMonitor.isConnected else { return }

        // Save update time
        saveLastCacheUpdate()

        // Cleanup old cache first
        cleanupExpiredCache()
        cleanupIfNeeded()
    }
}

// MARK: - Cache Info

struct CacheInfo: Identifiable {
    let key: CacheKey
    let size: Int64
    let lastModified: Date
    let isValid: Bool

    var id: String { key.rawValue }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var lastModifiedFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.localizedString(for: lastModified, relativeTo: Date())
    }
}

// MARK: - Cache Keys

enum CacheKey: String, CaseIterable {
    case businesses
    case posts
    case exchangeRates
    case userProfile
    case bookmarks
    case notifications
    case comments
    case messages

    var displayName: String {
        switch self {
        case .businesses: return "업소 정보"
        case .posts: return "게시글"
        case .exchangeRates: return "환율 정보"
        case .userProfile: return "프로필"
        case .bookmarks: return "북마크"
        case .notifications: return "알림"
        case .comments: return "댓글"
        case .messages: return "메시지"
        }
    }
}

// MARK: - Convenience Extensions

extension OfflineCacheManager {
    // Businesses
    func saveBusinesses(_ businesses: [Business]) {
        save(businesses, forKey: .businesses)
    }

    func loadBusinesses() -> [Business]? {
        load([Business].self, forKey: .businesses)
    }

    // Posts
    func savePosts(_ posts: [Post]) {
        save(posts, forKey: .posts)
    }

    func loadPosts() -> [Post]? {
        load([Post].self, forKey: .posts)
    }

    // Exchange Rates
    func saveExchangeRates(_ rates: ExchangeRate) {
        save(rates, forKey: .exchangeRates)
    }

    func loadExchangeRates() -> ExchangeRate? {
        load(ExchangeRate.self, forKey: .exchangeRates)
    }

    // User Profile
    func saveUserProfile(_ user: AppUser) {
        save(user, forKey: .userProfile)
    }

    func loadUserProfile() -> AppUser? {
        load(AppUser.self, forKey: .userProfile)
    }
}
