//
//  SyncManager.swift
//  Philfomation
//

import Foundation
import Combine
import FirebaseFirestore

// MARK: - Offline Action Type
enum OfflineActionType: String, Codable {
    case createPost = "create_post"
    case updatePost = "update_post"
    case deletePost = "delete_post"
    case createComment = "create_comment"
    case deleteComment = "delete_comment"
    case toggleLike = "toggle_like"
    case toggleBookmark = "toggle_bookmark"
    case sendMessage = "send_message"
}

// MARK: - Offline Action
struct OfflineAction: Codable, Identifiable {
    let id: String
    let type: OfflineActionType
    let payload: Data
    let createdAt: Date
    var retryCount: Int = 0
    var lastError: String?

    init(type: OfflineActionType, payload: Encodable) {
        self.id = UUID().uuidString
        self.type = type
        self.payload = (try? JSONEncoder().encode(AnyEncodable(payload))) ?? Data()
        self.createdAt = Date()
    }

    func decode<T: Decodable>(_ type: T.Type) -> T? {
        try? JSONDecoder().decode(type, from: payload)
    }
}

// MARK: - Type Erasure Helper
struct AnyEncodable: Encodable {
    private let encodable: Encodable

    init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

// MARK: - Sync Status
enum SyncStatus: Equatable {
    case idle
    case syncing(progress: Double)
    case completed
    case failed(error: String)

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }
}

// MARK: - Draft
struct Draft: Codable, Identifiable {
    let id: String
    let type: DraftType
    var title: String
    var content: String
    var imageURLs: [String]
    var category: String?
    var relatedId: String?  // postId for comments
    let createdAt: Date
    var updatedAt: Date

    init(type: DraftType, title: String = "", content: String = "", category: String? = nil, relatedId: String? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.title = title
        self.content = content
        self.imageURLs = []
        self.category = category
        self.relatedId = relatedId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum DraftType: String, Codable {
    case post
    case comment
    case message
}

// MARK: - Sync Manager
@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var pendingActionsCount: Int = 0
    @Published var draftsCount: Int = 0
    @Published var lastSyncDate: Date?

    private let networkMonitor = NetworkMonitor.shared
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    private let actionsKey = "offlineActions"
    private let draftsKey = "offlineDrafts"
    private let lastSyncKey = "lastSyncDate"
    private let maxRetries = 3

    private init() {
        loadLastSyncDate()
        updateCounts()
        setupNetworkObserver()
    }

    // MARK: - Setup

    private func setupNetworkObserver() {
        networkMonitor.$isConnected
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.syncPendingActions()
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Queue Management

    func queueAction(_ action: OfflineAction) {
        var actions = loadActions()
        actions.append(action)
        saveActions(actions)
        updateCounts()

        // Try to sync immediately if online
        if networkMonitor.isConnected {
            Task {
                await syncPendingActions()
            }
        }
    }

    func queuePostCreation(title: String, content: String, category: PostCategory, authorId: String, authorName: String, imageURLs: [String] = []) {
        let payload = CreatePostPayload(
            title: title,
            content: content,
            category: category.rawValue,
            authorId: authorId,
            authorName: authorName,
            imageURLs: imageURLs
        )
        let action = OfflineAction(type: .createPost, payload: payload)
        queueAction(action)
    }

    func queueCommentCreation(postId: String, content: String, authorId: String, authorName: String) {
        let payload = CreateCommentPayload(
            postId: postId,
            content: content,
            authorId: authorId,
            authorName: authorName
        )
        let action = OfflineAction(type: .createComment, payload: payload)
        queueAction(action)
    }

    func queueLikeToggle(targetId: String, targetType: String, userId: String) {
        let payload = LikeTogglePayload(
            targetId: targetId,
            targetType: targetType,
            userId: userId
        )
        let action = OfflineAction(type: .toggleLike, payload: payload)
        queueAction(action)
    }

    func queueMessageSend(chatId: String, senderId: String, senderName: String, content: String) {
        let payload = SendMessagePayload(
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            content: content
        )
        let action = OfflineAction(type: .sendMessage, payload: payload)
        queueAction(action)
    }

    // MARK: - Sync

    func syncPendingActions() async {
        guard networkMonitor.isConnected else { return }
        guard !syncStatus.isSyncing else { return }

        var actions = loadActions()
        guard !actions.isEmpty else { return }

        syncStatus = .syncing(progress: 0)

        var failedActions: [OfflineAction] = []
        let total = Double(actions.count)

        for (index, action) in actions.enumerated() {
            let success = await executeAction(action)

            if !success {
                var failedAction = action
                failedAction.retryCount += 1

                if failedAction.retryCount < maxRetries {
                    failedActions.append(failedAction)
                }
                // If max retries exceeded, discard the action
            }

            syncStatus = .syncing(progress: Double(index + 1) / total)
        }

        // Save failed actions for retry
        saveActions(failedActions)
        updateCounts()

        lastSyncDate = Date()
        saveLastSyncDate()

        if failedActions.isEmpty {
            syncStatus = .completed
        } else {
            syncStatus = .failed(error: "\(failedActions.count)개의 작업이 실패했습니다")
        }

        // Reset to idle after delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        syncStatus = .idle
    }

    private func executeAction(_ action: OfflineAction) async -> Bool {
        do {
            switch action.type {
            case .createPost:
                if let payload = action.decode(CreatePostPayload.self) {
                    try await createPost(payload)
                }
            case .createComment:
                if let payload = action.decode(CreateCommentPayload.self) {
                    try await createComment(payload)
                }
            case .toggleLike:
                if let payload = action.decode(LikeTogglePayload.self) {
                    try await toggleLike(payload)
                }
            case .sendMessage:
                if let payload = action.decode(SendMessagePayload.self) {
                    try await sendMessage(payload)
                }
            default:
                break
            }
            return true
        } catch {
            print("Failed to execute action \(action.type): \(error)")
            return false
        }
    }

    // MARK: - Action Execution

    private func createPost(_ payload: CreatePostPayload) async throws {
        let postData: [String: Any] = [
            "authorId": payload.authorId,
            "authorName": payload.authorName,
            "category": payload.category,
            "title": payload.title,
            "content": payload.content,
            "imageURLs": payload.imageURLs,
            "likeCount": 0,
            "commentCount": 0,
            "viewCount": 0,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]

        try await db.collection("posts").addDocument(data: postData)
    }

    private func createComment(_ payload: CreateCommentPayload) async throws {
        let comment: [String: Any] = [
            "postId": payload.postId,
            "authorId": payload.authorId,
            "authorName": payload.authorName,
            "content": payload.content,
            "createdAt": Timestamp(date: Date()),
            "likeCount": 0
        ]

        try await db.collection("comments").addDocument(data: comment)

        // Update post comment count
        try await db.collection("posts").document(payload.postId).updateData([
            "commentCount": FieldValue.increment(Int64(1))
        ])
    }

    private func toggleLike(_ payload: LikeTogglePayload) async throws {
        let likeRef = db.collection("likes")
            .whereField("userId", isEqualTo: payload.userId)
            .whereField("targetId", isEqualTo: payload.targetId)

        let snapshot = try await likeRef.getDocuments()

        if snapshot.documents.isEmpty {
            // Add like
            try await db.collection("likes").addDocument(data: [
                "userId": payload.userId,
                "targetId": payload.targetId,
                "targetType": payload.targetType,
                "createdAt": Timestamp(date: Date())
            ])

            // Update like count
            let collection = payload.targetType == "post" ? "posts" : "comments"
            try await db.collection(collection).document(payload.targetId).updateData([
                "likeCount": FieldValue.increment(Int64(1))
            ])
        } else {
            // Remove like
            for doc in snapshot.documents {
                try await doc.reference.delete()
            }

            // Update like count
            let collection = payload.targetType == "post" ? "posts" : "comments"
            try await db.collection(collection).document(payload.targetId).updateData([
                "likeCount": FieldValue.increment(Int64(-1))
            ])
        }
    }

    private func sendMessage(_ payload: SendMessagePayload) async throws {
        let message: [String: Any] = [
            "chatId": payload.chatId,
            "senderId": payload.senderId,
            "senderName": payload.senderName,
            "content": payload.content,
            "createdAt": Timestamp(date: Date()),
            "isRead": false
        ]

        try await db.collection("messages").addDocument(data: message)

        // Update chat last message
        try await db.collection("chats").document(payload.chatId).updateData([
            "lastMessage": payload.content,
            "lastMessageAt": Timestamp(date: Date())
        ])
    }

    // MARK: - Drafts

    func saveDraft(_ draft: Draft) {
        var drafts = loadDrafts()
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            var updated = draft
            updated.updatedAt = Date()
            drafts[index] = updated
        } else {
            drafts.append(draft)
        }
        saveDrafts(drafts)
        updateCounts()
    }

    func getDrafts(type: DraftType? = nil) -> [Draft] {
        let drafts = loadDrafts()
        if let type = type {
            return drafts.filter { $0.type == type }
        }
        return drafts
    }

    func deleteDraft(_ id: String) {
        var drafts = loadDrafts()
        drafts.removeAll { $0.id == id }
        saveDrafts(drafts)
        updateCounts()
    }

    func clearDrafts(type: DraftType? = nil) {
        if let type = type {
            var drafts = loadDrafts()
            drafts.removeAll { $0.type == type }
            saveDrafts(drafts)
        } else {
            saveDrafts([])
        }
        updateCounts()
    }

    // MARK: - Persistence

    private func loadActions() -> [OfflineAction] {
        guard let data = UserDefaults.standard.data(forKey: actionsKey),
              let actions = try? JSONDecoder().decode([OfflineAction].self, from: data) else {
            return []
        }
        return actions
    }

    private func saveActions(_ actions: [OfflineAction]) {
        if let data = try? JSONEncoder().encode(actions) {
            UserDefaults.standard.set(data, forKey: actionsKey)
        }
    }

    private func loadDrafts() -> [Draft] {
        guard let data = UserDefaults.standard.data(forKey: draftsKey),
              let drafts = try? JSONDecoder().decode([Draft].self, from: data) else {
            return []
        }
        return drafts
    }

    private func saveDrafts(_ drafts: [Draft]) {
        if let data = try? JSONEncoder().encode(drafts) {
            UserDefaults.standard.set(data, forKey: draftsKey)
        }
    }

    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
    }

    private func updateCounts() {
        pendingActionsCount = loadActions().count
        draftsCount = loadDrafts().count
    }

    // MARK: - Manual Sync Trigger

    func forceSync() async {
        guard networkMonitor.isConnected else { return }
        await syncPendingActions()
    }

    // MARK: - Clear All

    func clearPendingActions() {
        saveActions([])
        updateCounts()
    }
}

// MARK: - Payload Models

struct CreatePostPayload: Codable {
    let title: String
    let content: String
    let category: String
    let authorId: String
    let authorName: String
    let imageURLs: [String]
}

struct CreateCommentPayload: Codable {
    let postId: String
    let content: String
    let authorId: String
    let authorName: String
}

struct LikeTogglePayload: Codable {
    let targetId: String
    let targetType: String
    let userId: String
}

struct SendMessagePayload: Codable {
    let chatId: String
    let senderId: String
    let senderName: String
    let content: String
}
