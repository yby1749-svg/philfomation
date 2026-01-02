//
//  ChatRoomView.swift
//  Philfomation
//

import SwiftUI

struct ChatRoomView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var isMember = false
    @State private var isJoining = false
    @State private var showMembers = false

    let room: ChatRoom

    private var currentUserId: String {
        AuthService.shared.currentUserId ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            if !isMember {
                // Join Prompt
                VStack(spacing: 16) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color(hex: "2563EB").opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: room.category.icon)
                            .font(.system(size: 36))
                            .foregroundStyle(Color(hex: "2563EB"))
                    }

                    Text(room.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let description = room.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text("\(room.memberCount)명 참여 중")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Button {
                        joinRoom()
                    } label: {
                        if isJoining {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("참여하기")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "2563EB"))
                    .disabled(isJoining)

                    Spacer()
                }
                .padding()
            } else {
                // Chat Room
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.roomMessages) { message in
                                ChatBubble(
                                    message: message,
                                    isCurrentUser: message.senderId == currentUserId,
                                    showSenderName: true
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.roomMessages.count) { _ in
                        if let lastId = viewModel.roomMessages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Input Bar
                HStack(spacing: 12) {
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
                    .disabled(messageText.isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isMember {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showMembers = true
                    } label: {
                        Image(systemName: "person.2")
                    }
                }
            }
        }
        .sheet(isPresented: $showMembers) {
            ChatRoomMembersView(room: room)
        }
        .task {
            isMember = await viewModel.isUserMember(roomId: room.id ?? "")
            if isMember, let roomId = room.id {
                viewModel.selectedChatRoom = room
                viewModel.listenToRoomMessages(roomId: roomId)
            }
        }
        .onDisappear {
            viewModel.stopListening()
            viewModel.clearMessages()
        }
    }

    private func joinRoom() {
        guard let roomId = room.id else { return }
        isJoining = true

        Task {
            let success = await viewModel.joinChatRoom(roomId: roomId)
            await MainActor.run {
                isJoining = false
                if success {
                    isMember = true
                    viewModel.selectedChatRoom = room
                    viewModel.listenToRoomMessages(roomId: roomId)
                }
            }
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""

        Task {
            await viewModel.sendRoomMessage(text: text)
        }
    }
}

struct ChatRoomMembersView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    let room: ChatRoom

    var body: some View {
        NavigationStack {
            List(viewModel.roomMembers) { member in
                HStack(spacing: 12) {
                    AsyncProfileImage(url: member.userPhotoURL, size: 40)

                    VStack(alignment: .leading) {
                        HStack {
                            Text(member.userName)
                                .font(.headline)

                            if member.role == .admin {
                                Text("방장")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "F59E0B"))
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(formatDate(member.joinedAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("멤버 (\(viewModel.roomMembers.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                if let roomId = room.id {
                    await viewModel.fetchRoomMembers(roomId: roomId)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.M.d 가입"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ChatRoomView(room: ChatRoom(
            name: "테스트 톡방",
            category: .general,
            ownerId: "owner",
            ownerName: "방장"
        ))
        .environmentObject(ChatViewModel())
    }
}
