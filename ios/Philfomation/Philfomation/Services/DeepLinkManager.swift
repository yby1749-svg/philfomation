//
//  DeepLinkManager.swift
//  Philfomation
//

import SwiftUI
import Combine

enum DeepLinkDestination: Equatable {
    case post(id: String)
    case business(id: String)
    case profile(id: String)
    case community
    case businesses
    case chat(id: String? = nil)
    case notifications

    var path: String {
        switch self {
        case .post(let id): return "post/\(id)"
        case .business(let id): return "business/\(id)"
        case .profile(let id): return "profile/\(id)"
        case .community: return "community"
        case .businesses: return "businesses"
        case .chat(let id):
            if let id = id {
                return "chat/\(id)"
            }
            return "chat"
        case .notifications: return "notifications"
        }
    }

    // Tab index for tab-based navigation
    var tabIndex: Int? {
        switch self {
        case .businesses, .business: return 0
        case .community, .post: return 1
        case .chat: return 2
        case .profile, .notifications: return 3
        default: return nil
        }
    }
}

class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    @Published var pendingDestination: DeepLinkDestination?
    @Published var selectedTab: Int = 0

    // URL Scheme: philfomation://
    // Universal Link: https://philfomation.com/app/
    private let urlScheme = "philfomation"
    private let universalLinkHost = "philfomation.com"

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupNotificationObservers()
    }

    // MARK: - Setup Notification Observers

    private func setupNotificationObservers() {
        // Navigate to post
        NotificationCenter.default.publisher(for: .navigateToPost)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let postId = notification.userInfo?["postId"] as? String {
                    self?.navigate(to: .post(id: postId))
                }
            }
            .store(in: &cancellables)

        // Navigate to chat
        NotificationCenter.default.publisher(for: .navigateToChat)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let chatId = notification.userInfo?["chatId"] as? String {
                    self?.navigate(to: .chat(id: chatId))
                } else {
                    self?.navigate(to: .chat())
                }
            }
            .store(in: &cancellables)

        // Navigate to business
        NotificationCenter.default.publisher(for: .navigateToBusiness)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let businessId = notification.userInfo?["businessId"] as? String {
                    self?.navigate(to: .business(id: businessId))
                }
            }
            .store(in: &cancellables)

        // Navigate to notifications
        NotificationCenter.default.publisher(for: .navigateToNotifications)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.navigate(to: .notifications)
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigate Helper

    func navigate(to destination: DeepLinkDestination) {
        // Update tab if needed
        if let tabIndex = destination.tabIndex {
            selectedTab = tabIndex
        }

        // Set pending destination for detail navigation
        pendingDestination = destination
    }

    // MARK: - Handle URL

    func handleURL(_ url: URL) -> Bool {
        // Handle URL scheme (philfomation://post/abc123)
        if url.scheme == urlScheme {
            return parseDeepLink(url)
        }

        // Handle universal link (https://philfomation.com/app/post/abc123)
        if url.host == universalLinkHost {
            return parseUniversalLink(url)
        }

        return false
    }

    private func parseDeepLink(_ url: URL) -> Bool {
        guard let host = url.host else { return false }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let id = pathComponents.first ?? ""

        switch host {
        case "post":
            if !id.isEmpty {
                navigate(to: .post(id: id))
                return true
            }
        case "business":
            if !id.isEmpty {
                navigate(to: .business(id: id))
                return true
            }
        case "profile":
            if !id.isEmpty {
                navigate(to: .profile(id: id))
                return true
            }
        case "community":
            navigate(to: .community)
            return true
        case "businesses":
            navigate(to: .businesses)
            return true
        case "chat":
            if !id.isEmpty {
                navigate(to: .chat(id: id))
            } else {
                navigate(to: .chat())
            }
            return true
        case "notifications":
            navigate(to: .notifications)
            return true
        default:
            break
        }

        return false
    }

    private func parseUniversalLink(_ url: URL) -> Bool {
        let pathComponents = url.pathComponents.filter { $0 != "/" && $0 != "app" }

        guard pathComponents.count >= 1 else { return false }

        let type = pathComponents[0]
        let id = pathComponents.count > 1 ? pathComponents[1] : ""

        switch type {
        case "post":
            if !id.isEmpty {
                navigate(to: .post(id: id))
                return true
            }
        case "business":
            if !id.isEmpty {
                navigate(to: .business(id: id))
                return true
            }
        case "profile":
            if !id.isEmpty {
                navigate(to: .profile(id: id))
                return true
            }
        case "community":
            navigate(to: .community)
            return true
        case "businesses":
            navigate(to: .businesses)
            return true
        case "chat":
            if !id.isEmpty {
                navigate(to: .chat(id: id))
            } else {
                navigate(to: .chat())
            }
            return true
        case "notifications":
            navigate(to: .notifications)
            return true
        default:
            break
        }

        return false
    }

    // MARK: - Generate Share URLs

    func shareURL(for destination: DeepLinkDestination) -> URL? {
        // Use URL scheme for sharing (works within app ecosystem)
        let urlString = "\(urlScheme)://\(destination.path)"
        return URL(string: urlString)
    }

    func universalShareURL(for destination: DeepLinkDestination) -> URL? {
        // Use universal link for sharing (works on web and app)
        let urlString = "https://\(universalLinkHost)/app/\(destination.path)"
        return URL(string: urlString)
    }

    // MARK: - Clear Destination

    func clearDestination() {
        pendingDestination = nil
    }
}

// MARK: - Share Helper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?

    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Share Item

struct ShareItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let url: URL

    var shareText: String {
        var text = title
        if let description = description {
            text += "\n\n\(description)"
        }
        text += "\n\n\(url.absoluteString)"
        return text
    }
}
