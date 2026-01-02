//
//  FirestoreService.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Users

    func getUser(id: String) async throws -> AppUser? {
        let doc = try await db.collection("users").document(id).getDocument()
        return try doc.data(as: AppUser.self)
    }

    func updateUser(_ user: AppUser) async throws {
        guard let id = user.id else { return }
        try db.collection("users").document(id).setData(from: user, merge: true)
    }

    func updateFCMToken(userId: String, token: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "fcmToken": token,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Businesses

    func getBusinesses(category: BusinessCategory? = nil) async throws -> [Business] {
        var query: Query = db.collection("businesses")

        if let category = category {
            query = query.whereField("category", isEqualTo: category.rawValue)
        }

        let snapshot = try await query.order(by: "rating", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Business.self) }
    }

    // Paginated version
    func getBusinessesPaginated(
        category: BusinessCategory? = nil,
        limit: Int = 20,
        lastDocument: DocumentSnapshot? = nil
    ) async throws -> (businesses: [Business], lastDocument: DocumentSnapshot?) {
        var query: Query = db.collection("businesses")

        if let category = category {
            query = query.whereField("category", isEqualTo: category.rawValue)
        }

        query = query.order(by: "rating", descending: true).limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let businesses = snapshot.documents.compactMap { try? $0.data(as: Business.self) }
        let lastDoc = snapshot.documents.last

        return (businesses, lastDoc)
    }

    func getBusiness(id: String) async throws -> Business? {
        let doc = try await db.collection("businesses").document(id).getDocument()
        return try doc.data(as: Business.self)
    }

    func searchBusinesses(query: String) async throws -> [Business] {
        let snapshot = try await db.collection("businesses")
            .order(by: "name")
            .start(at: [query])
            .end(at: [query + "\u{f8ff}"])
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Business.self) }
    }

    // MARK: - Reviews

    func getReviews(businessId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("businessId", isEqualTo: businessId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Review.self) }
    }

    func addReview(_ review: Review) async throws -> String {
        let ref = try db.collection("reviews").addDocument(from: review)
        return ref.documentID
    }

    func updateReview(_ review: Review) async throws {
        guard let id = review.id else { return }
        try db.collection("reviews").document(id).setData(from: review, merge: true)
    }

    func deleteReview(id: String) async throws {
        try await db.collection("reviews").document(id).delete()
    }

    func getUserReviews(userId: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Review.self) }
    }

    // MARK: - Chats (1:1)

    func getOrCreateChat(with userId: String, currentUserId: String) async throws -> Chat {
        // Check if chat already exists
        let snapshot = try await db.collection("chats")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments()

        for doc in snapshot.documents {
            if let chat = try? doc.data(as: Chat.self),
               chat.participants.contains(userId) {
                return chat
            }
        }

        // Create new chat
        let newChat = Chat(participants: [currentUserId, userId])
        let ref = try db.collection("chats").addDocument(from: newChat)
        var chat = newChat
        chat.id = ref.documentID
        return chat
    }

    func getChats(userId: String) async throws -> [Chat] {
        let snapshot = try await db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageTime", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Chat.self) }
    }

    func sendMessage(chatId: String, message: Message) async throws {
        try db.collection("chats").document(chatId)
            .collection("messages").addDocument(from: message)

        try await db.collection("chats").document(chatId).updateData([
            "lastMessage": message.text ?? "[이미지]",
            "lastMessageTime": FieldValue.serverTimestamp()
        ])
    }

    func listenToMessages(chatId: String, onUpdate: @escaping ([Message]) -> Void) -> ListenerRegistration {
        db.collection("chats").document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, _ in
                let messages = snapshot?.documents.compactMap { try? $0.data(as: Message.self) } ?? []
                onUpdate(messages)
            }
    }

    // MARK: - Chat Rooms (Group)

    func getChatRooms(category: ChatRoomCategory? = nil) async throws -> [ChatRoom] {
        var query: Query = db.collection("chatRooms")

        if let category = category {
            query = query.whereField("category", isEqualTo: category.rawValue)
        }

        let snapshot = try await query.order(by: "lastMessageTime", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ChatRoom.self) }
    }

    func createChatRoom(_ room: ChatRoom, creator: ChatRoomMember) async throws -> String {
        let ref = try db.collection("chatRooms").addDocument(from: room)
        var member = creator
        member.role = .admin
        try db.collection("chatRooms").document(ref.documentID)
            .collection("members").document(creator.userId).setData(from: member)
        return ref.documentID
    }

    func joinChatRoom(roomId: String, member: ChatRoomMember) async throws {
        try db.collection("chatRooms").document(roomId)
            .collection("members").document(member.userId).setData(from: member)
    }

    func leaveChatRoom(roomId: String, userId: String) async throws {
        try await db.collection("chatRooms").document(roomId)
            .collection("members").document(userId).delete()
    }

    func getChatRoomMembers(roomId: String) async throws -> [ChatRoomMember] {
        let snapshot = try await db.collection("chatRooms").document(roomId)
            .collection("members").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: ChatRoomMember.self) }
    }

    func isUserMemberOfRoom(roomId: String, userId: String) async throws -> Bool {
        let doc = try await db.collection("chatRooms").document(roomId)
            .collection("members").document(userId).getDocument()
        return doc.exists
    }

    func sendRoomMessage(roomId: String, message: Message) async throws {
        try db.collection("chatRooms").document(roomId)
            .collection("messages").addDocument(from: message)

        try await db.collection("chatRooms").document(roomId).updateData([
            "lastMessage": message.text ?? "[이미지]",
            "lastMessageTime": FieldValue.serverTimestamp()
        ])
    }

    func listenToRoomMessages(roomId: String, onUpdate: @escaping ([Message]) -> Void) -> ListenerRegistration {
        db.collection("chatRooms").document(roomId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, _ in
                let messages = snapshot?.documents.compactMap { try? $0.data(as: Message.self) } ?? []
                onUpdate(messages)
            }
    }
}
