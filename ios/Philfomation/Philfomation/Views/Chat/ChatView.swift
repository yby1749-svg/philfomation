//
//  ChatView.swift
//  Philfomation
//

import SwiftUI
import PhotosUI

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var otherUser: AppUser?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false

    let chat: Chat

    private var currentUserId: String {
        AuthService.shared.currentUserId ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.chatMessages) { message in
                            ChatBubble(
                                message: message,
                                isCurrentUser: message.senderId == currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.chatMessages.count) { _ in
                    if let lastId = viewModel.chatMessages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input Bar
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(Color(hex: "2563EB"))
                }
                .disabled(isUploading)

                TextField("메시지 입력", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundStyle(messageText.isEmpty ? .secondary : Color(hex: "2563EB"))
                }
                .disabled(messageText.isEmpty || isUploading)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(otherUser?.name ?? "채팅")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let chatId = chat.id {
                viewModel.selectedChat = chat
                viewModel.listenToMessages(chatId: chatId)
            }
            await loadOtherUser()
        }
        .onDisappear {
            viewModel.stopListening()
            viewModel.clearMessages()
        }
        .onChange(of: selectedPhoto) { newItem in
            if let item = newItem {
                Task {
                    await uploadImage(item)
                }
            }
        }
        .overlay {
            if isUploading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView("이미지 전송 중...")
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
            }
        }
    }

    private func loadOtherUser() async {
        if let otherId = chat.otherParticipantId(currentUserId: currentUserId) {
            otherUser = try? await FirestoreService.shared.getUser(id: otherId)
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""

        Task {
            await viewModel.sendMessage(text: text)
        }
    }

    private func uploadImage(_ item: PhotosPickerItem) async {
        isUploading = true

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let urlString = try await StorageService.shared.uploadChatImage(image)
                await viewModel.sendImageMessage(imageUrl: urlString)
            }
        } catch {
            print("Failed to upload image: \(error)")
        }

        selectedPhoto = nil
        isUploading = false
    }
}

#Preview {
    NavigationStack {
        ChatView(chat: Chat(participants: ["user1", "user2"]))
            .environmentObject(ChatViewModel())
    }
}
