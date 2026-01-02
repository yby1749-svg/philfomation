//
//  NotificationView.swift
//  Philfomation
//

import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.notifications.isEmpty {
                    EmptyNotificationView()
                } else {
                    notificationList
                }
            }
            .navigationTitle("알림")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }

                if !viewModel.notifications.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                Task {
                                    await viewModel.markAllAsRead()
                                }
                            } label: {
                                Label("모두 읽음 처리", systemImage: "checkmark.circle")
                            }

                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteAllNotifications()
                                }
                            } label: {
                                Label("모두 삭제", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.fetchNotifications()
            }
        }
        .onAppear {
            if let userId = authViewModel.currentUser?.id {
                viewModel.setUserId(userId)
            }
        }
    }

    private var notificationList: some View {
        List {
            if !viewModel.unreadNotifications.isEmpty {
                Section {
                    ForEach(viewModel.unreadNotifications) { notification in
                        NotificationRowView(notification: notification)
                            .onTapGesture {
                                Task {
                                    await viewModel.markAsRead(notification)
                                }
                            }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await viewModel.deleteNotification(viewModel.unreadNotifications[index])
                            }
                        }
                    }
                } header: {
                    Text("읽지 않음")
                }
            }

            if !viewModel.readNotifications.isEmpty {
                Section {
                    ForEach(viewModel.readNotifications) { notification in
                        NotificationRowView(notification: notification)
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await viewModel.deleteNotification(viewModel.readNotifications[index])
                            }
                        }
                    }
                } header: {
                    Text("읽음")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notification: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: notification.type.color).opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: notification.type.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: notification.type.color))
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                    .foregroundStyle(notification.isRead ? .secondary : .primary)

                Text(notification.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(notification.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(Color(hex: "2563EB"))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Empty Notification View
struct EmptyNotificationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)

            Text("알림이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("새로운 활동이 있으면 여기에 표시됩니다")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Notification Bell Button
struct NotificationBellButton: View {
    @ObservedObject var viewModel: NotificationViewModel
    @Binding var showNotifications: Bool

    var body: some View {
        Button {
            showNotifications = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 18))

                if viewModel.unreadCount > 0 {
                    Text(viewModel.unreadCount > 99 ? "99+" : "\(viewModel.unreadCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
}

#Preview {
    NotificationView()
        .environmentObject(AuthViewModel())
}
