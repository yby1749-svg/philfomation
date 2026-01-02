//
//  ChatListView.swift
//  Philfomation
//

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var otherUsers: [String: AppUser] = [:]

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.chats.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "채팅이 없습니다",
                    message: "업소에 문의하시면 채팅이 시작됩니다"
                )
            } else {
                List(viewModel.chats) { chat in
                    NavigationLink(destination: ChatView(chat: chat)) {
                        ChatListRow(
                            chat: chat,
                            otherUser: otherUsers[chat.otherParticipantId(currentUserId: AuthService.shared.currentUserId ?? "") ?? ""]
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.fetchChats()
            await loadOtherUsers()
        }
        .refreshable {
            await viewModel.fetchChats()
            await loadOtherUsers()
        }
    }

    private func loadOtherUsers() async {
        for chat in viewModel.chats {
            if let otherId = chat.otherParticipantId(currentUserId: AuthService.shared.currentUserId ?? ""),
               otherUsers[otherId] == nil {
                if let user = try? await FirestoreService.shared.getUser(id: otherId) {
                    otherUsers[otherId] = user
                }
            }
        }
    }
}

struct ChatListRow: View {
    let chat: Chat
    let otherUser: AppUser?

    private var currentUserId: String {
        AuthService.shared.currentUserId ?? ""
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncProfileImage(url: otherUser?.photoURL, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherUser?.name ?? "알 수 없음")
                        .font(.headline)

                    Spacer()

                    if let time = chat.lastMessageTime {
                        Text(formatDate(time))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text(chat.lastMessage ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    if let unread = chat.unreadCount[currentUserId], unread > 0 {
                        Text("\(unread)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "a h:mm"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    NavigationStack {
        ChatListView()
            .environmentObject(ChatViewModel())
    }
}
