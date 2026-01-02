//
//  ChatBubble.swift
//  Philfomation
//

import SwiftUI

struct ChatBubble: View {
    let message: Message
    let isCurrentUser: Bool
    var showSenderName: Bool = false

    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 2) {
                // Sender Name (for group chats)
                if showSenderName && !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }

                // Message Content
                HStack(alignment: .bottom, spacing: 4) {
                    if isCurrentUser {
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let imageUrl = message.imageUrl {
                        // Image Message
                        CachedAsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay { ProgressView() }
                        }
                        .frame(maxWidth: 200, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if let text = message.text {
                        // Text Message
                        Text(text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isCurrentUser ? Color(hex: "2563EB") : Color(.systemGray5))
                            .foregroundStyle(isCurrentUser ? .white : .primary)
                            .clipShape(ChatBubbleShape(isCurrentUser: isCurrentUser))
                    }

                    if !isCurrentUser {
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !isCurrentUser { Spacer(minLength: 60) }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

struct ChatBubbleShape: Shape {
    let isCurrentUser: Bool

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isCurrentUser
                ? [.topLeft, .topRight, .bottomLeft]
                : [.topLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack(spacing: 8) {
        ChatBubble(
            message: Message(
                senderId: "other",
                senderName: "상대방",
                text: "안녕하세요!"
            ),
            isCurrentUser: false
        )

        ChatBubble(
            message: Message(
                senderId: "me",
                senderName: "나",
                text: "네, 안녕하세요! 반갑습니다."
            ),
            isCurrentUser: true
        )

        ChatBubble(
            message: Message(
                senderId: "other",
                senderName: "다른사람",
                text: "단톡방 메시지입니다"
            ),
            isCurrentUser: false,
            showSenderName: true
        )
    }
    .padding()
}
