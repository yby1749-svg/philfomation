//
//  OfflineCacheManager.swift
//  Philfomation
//

import Foundation

class OfflineCacheManager {
    static let shared = OfflineCacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsDirectory.appendingPathComponent("OfflineCache", isDirectory: true)

        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
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
}

// MARK: - Cache Keys

enum CacheKey: String {
    case businesses
    case posts
    case exchangeRates
    case userProfile
    case bookmarks
    case notifications
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
