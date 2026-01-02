//
//  ChatViewModel.swift
//  Philfomation
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class ChatViewModel: ObservableObject {
    // 1:1 Chat
    @Published var chats: [Chat] = []
    @Published var selectedChat: Chat?
    @Published var chatMessages: [Message] = []

    // Chat Rooms (Group)
    @Published var chatRooms: [ChatRoom] = []
    @Published var selectedChatRoom: ChatRoom?
    @Published var roomMessages: [Message] = []
    @Published var roomMembers: [ChatRoomMember] = []
    @Published var selectedRoomCategory: ChatRoomCategory?

    @Published var isLoading = false
    @Published var errorMessage: String?

    private var messageListener: ListenerRegistration?
    private var currentUserId: String? { AuthService.shared.currentUserId }

    // MARK: - 1:1 Chat Methods

    func fetchChats() async {
        guard let userId = currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            chats = try await FirestoreService.shared.getChats(userId: userId)
        } catch {
            errorMessage = "채팅 목록을 불러오는데 실패했습니다."
            print("Error fetching chats: \(error)")
        }
        isLoading = false
    }

    func startChat(with userId: String) async -> Chat? {
        guard let currentUserId = currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return nil
        }

        do {
            let chat = try await FirestoreService.shared.getOrCreateChat(
                with: userId,
                currentUserId: currentUserId
            )
            selectedChat = chat
            return chat
        } catch {
            errorMessage = "채팅을 시작할 수 없습니다."
            print("Error starting chat: \(error)")
            return nil
        }
    }

    func listenToMessages(chatId: String) {
        messageListener?.remove()
        messageListener = FirestoreService.shared.listenToMessages(chatId: chatId) { [weak self] messages in
            Task { @MainActor in
                self?.chatMessages = messages
            }
        }
    }

    func sendMessage(text: String) async {
        guard let chatId = selectedChat?.id else {
            errorMessage = "채팅방을 찾을 수 없습니다."
            return
        }

        guard let userId = currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return
        }

        do {
            guard let user = try await FirestoreService.shared.getUser(id: userId) else {
                errorMessage = "사용자 정보를 불러올 수 없습니다."
                return
            }

            let message = Message(
                senderId: userId,
                senderName: user.name,
                text: text
            )

            try await FirestoreService.shared.sendMessage(chatId: chatId, message: message)
        } catch {
            errorMessage = "메시지 전송에 실패했습니다."
            print("Error sending message: \(error)")
        }
    }

    func sendImageMessage(imageUrl: String) async {
        guard let chatId = selectedChat?.id else {
            errorMessage = "채팅방을 찾을 수 없습니다."
            return
        }

        guard let userId = currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return
        }

        do {
            guard let user = try await FirestoreService.shared.getUser(id: userId) else {
                errorMessage = "사용자 정보를 불러올 수 없습니다."
                return
            }

            let message = Message(
                senderId: userId,
                senderName: user.name,
                imageUrl: imageUrl
            )

            try await FirestoreService.shared.sendMessage(chatId: chatId, message: message)
        } catch {
            errorMessage = "이미지 전송에 실패했습니다."
            print("Error sending image message: \(error)")
        }
    }

    // MARK: - Chat Room Methods

    func fetchChatRooms() async {
        isLoading = true
        errorMessage = nil

        do {
            chatRooms = try await FirestoreService.shared.getChatRooms(category: selectedRoomCategory)
        } catch {
            errorMessage = "단톡방 목록을 불러오는데 실패했습니다."
            print("Error fetching chat rooms: \(error)")
        }
        isLoading = false
    }

    func createChatRoom(name: String, description: String?, category: ChatRoomCategory) async -> String? {
        guard let userId = currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return nil
        }

        do {
            guard let user = try await FirestoreService.shared.getUser(id: userId) else {
                errorMessage = "사용자 정보를 불러올 수 없습니다."
                return nil
            }

            let room = ChatRoom(
                name: name,
                description: description,
                category: category,
                ownerId: userId,
                ownerName: user.name
            )

            let member = ChatRoomMember(
                userId: userId,
                userName: user.name,
                userPhotoURL: user.photoURL,
                role: .admin
            )

            let roomId = try await FirestoreService.shared.createChatRoom(room, creator: member)
            await fetchChatRooms()
            return roomId
        } catch {
            errorMessage = "단톡방 생성에 실패했습니다."
            print("Error creating chat room: \(error)")
            return nil
        }
    }

    func joinChatRoom(roomId: String) async -> Bool {
        guard let userId = currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return false
        }

        do {
            guard let user = try await FirestoreService.shared.getUser(id: userId) else {
                errorMessage = "사용자 정보를 불러올 수 없습니다."
                return false
            }

            let member = ChatRoomMember(
                userId: userId,
                userName: user.name,
                userPhotoURL: user.photoURL
            )

            try await FirestoreService.shared.joinChatRoom(roomId: roomId, member: member)
            await fetchChatRooms()
            return true
        } catch {
            errorMessage = "단톡방 참가에 실패했습니다."
            print("Error joining chat room: \(error)")
            return false
        }
    }

    func leaveChatRoom(roomId: String) async -> Bool {
        guard let userId = currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return false
        }

        do {
            try await FirestoreService.shared.leaveChatRoom(roomId: roomId, userId: userId)
            await fetchChatRooms()
            return true
        } catch {
            errorMessage = "단톡방 퇴장에 실패했습니다."
            print("Error leaving chat room: \(error)")
            return false
        }
    }

    func fetchRoomMembers(roomId: String) async {
        do {
            roomMembers = try await FirestoreService.shared.getChatRoomMembers(roomId: roomId)
        } catch {
            errorMessage = "멤버 목록을 불러오는데 실패했습니다."
            print("Error fetching room members: \(error)")
        }
    }

    func isUserMember(roomId: String) async -> Bool {
        guard let userId = currentUserId else { return false }

        do {
            return try await FirestoreService.shared.isUserMemberOfRoom(roomId: roomId, userId: userId)
        } catch {
            print("Error checking membership: \(error)")
            return false
        }
    }

    func listenToRoomMessages(roomId: String) {
        messageListener?.remove()
        messageListener = FirestoreService.shared.listenToRoomMessages(roomId: roomId) { [weak self] messages in
            Task { @MainActor in
                self?.roomMessages = messages
            }
        }
    }

    func sendRoomMessage(text: String) async {
        guard let roomId = selectedChatRoom?.id else {
            errorMessage = "단톡방을 찾을 수 없습니다."
            return
        }

        guard let userId = currentUserId else {
            errorMessage = "로그인이 필요합니다."
            return
        }

        do {
            guard let user = try await FirestoreService.shared.getUser(id: userId) else {
                errorMessage = "사용자 정보를 불러올 수 없습니다."
                return
            }

            let message = Message(
                senderId: userId,
                senderName: user.name,
                text: text
            )

            try await FirestoreService.shared.sendRoomMessage(roomId: roomId, message: message)
        } catch {
            errorMessage = "메시지 전송에 실패했습니다."
            print("Error sending room message: \(error)")
        }
    }

    func setRoomCategory(_ category: ChatRoomCategory?) {
        selectedRoomCategory = category
        Task {
            await fetchChatRooms()
        }
    }

    // MARK: - Error Handling

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Cleanup

    func stopListening() {
        messageListener?.remove()
        messageListener = nil
    }

    func clearMessages() {
        chatMessages = []
        roomMessages = []
    }
}
