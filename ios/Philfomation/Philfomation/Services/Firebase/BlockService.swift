//
//  BlockService.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

class BlockService {
    static let shared = BlockService()

    private let db = Firestore.firestore()
    private let blocksCollection = "blocks"

    // 캐시된 차단 목록
    private var blockedUserIds: Set<String> = []
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 300 // 5분

    private init() {}

    // MARK: - Block User

    func blockUser(
        blockerId: String,
        blockedUser: AppUser
    ) async throws {
        guard let blockedId = blockedUser.id else { return }

        let blockId = "\(blockerId)_\(blockedId)"

        let block = Block(
            id: blockId,
            blockerId: blockerId,
            blockedId: blockedId,
            blockedName: blockedUser.name,
            blockedPhotoURL: blockedUser.photoURL,
            createdAt: Date()
        )

        try db.collection(blocksCollection).document(blockId).setData(from: block)

        // 캐시 업데이트
        blockedUserIds.insert(blockedId)
    }

    // MARK: - Unblock User

    func unblockUser(blockerId: String, blockedId: String) async throws {
        let blockId = "\(blockerId)_\(blockedId)"
        try await db.collection(blocksCollection).document(blockId).delete()

        // 캐시 업데이트
        blockedUserIds.remove(blockedId)
    }

    // MARK: - Check if Blocked

    func isBlocked(blockerId: String, blockedId: String) async throws -> Bool {
        let blockId = "\(blockerId)_\(blockedId)"
        let doc = try await db.collection(blocksCollection).document(blockId).getDocument()
        return doc.exists
    }

    // MARK: - Fetch Blocked Users

    func fetchBlockedUsers(userId: String) async throws -> [Block] {
        let snapshot = try await db.collection(blocksCollection)
            .whereField("blockerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Block.self) }
    }

    // MARK: - Fetch Blocked User IDs (with caching)

    func fetchBlockedUserIds(userId: String, forceRefresh: Bool = false) async -> Set<String> {
        // 캐시가 유효하면 캐시 반환
        if !forceRefresh,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheTimeout,
           !blockedUserIds.isEmpty {
            return blockedUserIds
        }

        do {
            let blocks = try await fetchBlockedUsers(userId: userId)
            blockedUserIds = Set(blocks.map { $0.blockedId })
            lastFetchTime = Date()
        } catch {
            print("Error fetching blocked users: \(error)")
        }

        return blockedUserIds
    }

    // MARK: - Clear Cache

    func clearCache() {
        blockedUserIds.removeAll()
        lastFetchTime = nil
    }

    // MARK: - Filter Blocked Content

    func filterBlockedPosts(_ posts: [Post], blockedIds: Set<String>) -> [Post] {
        posts.filter { !blockedIds.contains($0.authorId) }
    }

    func filterBlockedComments(_ comments: [Comment], blockedIds: Set<String>) -> [Comment] {
        comments.filter { !blockedIds.contains($0.authorId) }
    }

    func filterBlockedBusinesses(_ businesses: [Business], blockedIds: Set<String>) -> [Business] {
        businesses.filter { business in
            guard let ownerId = business.ownerId else { return true }
            return !blockedIds.contains(ownerId)
        }
    }
}
