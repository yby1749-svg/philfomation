//
//  NotificationViewModel.swift
//  Philfomation
//

import Foundation
import SwiftUI
import Combine

@MainActor
class NotificationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let service = NotificationService.shared
    private var userId: String?

    // MARK: - Computed Properties
    var unreadNotifications: [AppNotification] {
        notifications.filter { !$0.isRead }
    }

    var readNotifications: [AppNotification] {
        notifications.filter { $0.isRead }
    }

    // MARK: - Methods

    func setUserId(_ userId: String) {
        self.userId = userId
        Task {
            await fetchNotifications()
            await fetchUnreadCount()
        }
    }

    func fetchNotifications() async {
        guard let userId = userId else { return }

        isLoading = true
        errorMessage = nil

        do {
            notifications = try await service.fetchNotifications(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func fetchUnreadCount() async {
        guard let userId = userId else { return }

        do {
            unreadCount = try await service.fetchUnreadCount(userId: userId)
        } catch {
            print("Error fetching unread count: \(error)")
        }
    }

    func markAsRead(_ notification: AppNotification) async {
        guard let id = notification.id else { return }

        do {
            try await service.markAsRead(notificationId: id)
            if let index = notifications.firstIndex(where: { $0.id == id }) {
                notifications[index].isRead = true
            }
            await fetchUnreadCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markAllAsRead() async {
        guard let userId = userId else { return }

        do {
            try await service.markAllAsRead(userId: userId)
            for index in notifications.indices {
                notifications[index].isRead = true
            }
            unreadCount = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteNotification(_ notification: AppNotification) async {
        guard let id = notification.id else { return }

        do {
            try await service.deleteNotification(id: id)
            notifications.removeAll { $0.id == id }
            await fetchUnreadCount()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAllNotifications() async {
        guard let userId = userId else { return }

        do {
            try await service.deleteAllNotifications(userId: userId)
            notifications.removeAll()
            unreadCount = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
