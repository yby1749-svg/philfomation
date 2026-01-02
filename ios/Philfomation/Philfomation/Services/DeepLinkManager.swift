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
    case chat

    var path: String {
        switch self {
        case .post(let id): return "post/\(id)"
        case .business(let id): return "business/\(id)"
        case .profile(let id): return "profile/\(id)"
        case .community: return "community"
        case .businesses: return "businesses"
        case .chat: return "chat"
        }
    }
}

class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    @Published var pendingDestination: DeepLinkDestination?

    // URL Scheme: philfomation://
    // Universal Link: https://philfomation.com/app/
    private let urlScheme = "philfomation"
    private let universalLinkHost = "philfomation.com"

    private init() {}

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
                pendingDestination = .post(id: id)
                return true
            }
        case "business":
            if !id.isEmpty {
                pendingDestination = .business(id: id)
                return true
            }
        case "profile":
            if !id.isEmpty {
                pendingDestination = .profile(id: id)
                return true
            }
        case "community":
            pendingDestination = .community
            return true
        case "businesses":
            pendingDestination = .businesses
            return true
        case "chat":
            pendingDestination = .chat
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
                pendingDestination = .post(id: id)
                return true
            }
        case "business":
            if !id.isEmpty {
                pendingDestination = .business(id: id)
                return true
            }
        case "profile":
            if !id.isEmpty {
                pendingDestination = .profile(id: id)
                return true
            }
        case "community":
            pendingDestination = .community
            return true
        case "businesses":
            pendingDestination = .businesses
            return true
        case "chat":
            pendingDestination = .chat
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
