//
//  ShareService.swift
//  Philfomation
//

import SwiftUI
import Combine
import LinkPresentation
import UniformTypeIdentifiers

// MARK: - Shareable Content Type
enum ShareableContentType {
    case post(Post)
    case business(Business)
    case exchangeRate(rate: Double, currency: String)
    case app

    var title: String {
        switch self {
        case .post(let post):
            return post.title
        case .business(let business):
            return business.name
        case .exchangeRate:
            return "환율 정보"
        case .app:
            return "Philfomation"
        }
    }

    var subtitle: String {
        switch self {
        case .post(let post):
            return "\(post.authorName) • \(post.category.rawValue)"
        case .business(let business):
            return "\(business.category.rawValue) • \(business.address)"
        case .exchangeRate(let rate, let currency):
            return "1 \(currency) = \(String(format: "%.2f", rate)) KRW"
        case .app:
            return "Philippine Community Hub"
        }
    }

    var description: String {
        switch self {
        case .post(let post):
            let preview = String(post.content.prefix(100))
            return preview + (post.content.count > 100 ? "..." : "")
        case .business(let business):
            return business.description ?? "필리핀 한인 업소 정보"
        case .exchangeRate:
            return "Philfomation에서 실시간 환율을 확인하세요"
        case .app:
            return "필리핀 거주 한국인을 위한 커뮤니티 앱"
        }
    }

    var deepLinkURL: URL? {
        switch self {
        case .post(let post):
            guard let id = post.id else { return nil }
            return URL(string: "philfomation://post/\(id)")
        case .business(let business):
            guard let id = business.id else { return nil }
            return URL(string: "philfomation://business/\(id)")
        case .exchangeRate:
            return URL(string: "philfomation://exchange")
        case .app:
            return URL(string: "https://apps.apple.com/app/philfomation/id123456789")
        }
    }

    var universalLinkURL: URL? {
        switch self {
        case .post(let post):
            guard let id = post.id else { return nil }
            return URL(string: "https://philfomation.com/app/post/\(id)")
        case .business(let business):
            guard let id = business.id else { return nil }
            return URL(string: "https://philfomation.com/app/business/\(id)")
        case .exchangeRate:
            return URL(string: "https://philfomation.com/app/exchange")
        case .app:
            return URL(string: "https://philfomation.com")
        }
    }

    var icon: String {
        switch self {
        case .post: return "doc.text"
        case .business: return "building.2"
        case .exchangeRate: return "wonsign.circle"
        case .app: return "square.and.arrow.up"
        }
    }
}

// MARK: - Share Service
class ShareService: ObservableObject {
    static let shared = ShareService()

    @Published var isSharing = false

    private init() {}

    // MARK: - Generate Share Text

    func generateShareText(for content: ShareableContentType) -> String {
        var text = ""

        switch content {
        case .post(let post):
            text = """
            📝 \(post.title)

            \(String(post.content.prefix(200)))\(post.content.count > 200 ? "..." : "")

            ✍️ \(post.authorName) • \(post.category.rawValue)
            """

        case .business(let business):
            text = """
            🏢 \(business.name)

            📍 \(business.address)
            📞 \(business.phone)
            ⭐️ \(String(format: "%.1f", business.rating)) (\(business.reviewCount)개 리뷰)

            \(business.description ?? "")
            """

        case .exchangeRate(let rate, let currency):
            text = """
            💱 환율 정보

            1 \(currency) = \(String(format: "%.2f", rate)) KRW

            Philfomation에서 실시간 환율을 확인하세요!
            """

        case .app:
            text = """
            🌏 Philfomation - Philippine Community Hub

            필리핀 거주 한국인을 위한 종합 커뮤니티 앱!
            • 한인 업소 정보
            • 커뮤니티
            • 실시간 환율
            • 여행 정보
            """
        }

        // Add app link
        if let url = content.universalLinkURL {
            text += "\n\n🔗 \(url.absoluteString)"
        }

        text += "\n\n📱 Philfomation 앱에서 더 많은 정보를 확인하세요!"

        return text
    }

    // MARK: - Generate Share Items

    func generateShareItems(for content: ShareableContentType) -> [Any] {
        var items: [Any] = []

        // Add text
        items.append(generateShareText(for: content))

        // Add URL if available
        if let url = content.universalLinkURL {
            items.append(url)
        }

        return items
    }

    // MARK: - Copy Link

    func copyLink(for content: ShareableContentType) -> Bool {
        guard let url = content.universalLinkURL else { return false }
        UIPasteboard.general.string = url.absoluteString
        HapticManager.shared.success()
        return true
    }

    // MARK: - Share via System Sheet

    func share(_ content: ShareableContentType, from viewController: UIViewController? = nil) {
        let items = generateShareItems(for: content)

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        // Exclude certain activity types
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]

        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        // Present
        if let vc = viewController {
            vc.present(activityVC, animated: true)
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Share Button View
struct ShareButton: View {
    let content: ShareableContentType
    var style: ShareButtonStyle = .icon

    @State private var showShareSheet = false
    @State private var showCopiedToast = false

    enum ShareButtonStyle {
        case icon
        case label
        case menu
    }

    var body: some View {
        switch style {
        case .icon:
            Button {
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheetView(items: ShareService.shared.generateShareItems(for: content))
            }

        case .label:
            Button {
                showShareSheet = true
            } label: {
                Label("공유", systemImage: "square.and.arrow.up")
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheetView(items: ShareService.shared.generateShareItems(for: content))
            }

        case .menu:
            Menu {
                Button {
                    showShareSheet = true
                } label: {
                    Label("공유하기", systemImage: "square.and.arrow.up")
                }

                Button {
                    if ShareService.shared.copyLink(for: content) {
                        showCopiedToast = true
                    }
                } label: {
                    Label("링크 복사", systemImage: "doc.on.doc")
                }

                if case .post = content {
                    ShareMenu {
                        Button {
                            shareToKakao()
                        } label: {
                            Label("카카오톡", systemImage: "message")
                        }
                    }
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheetView(items: ShareService.shared.generateShareItems(for: content))
            }
            .overlay(alignment: .top) {
                if showCopiedToast {
                    CopiedToast()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCopiedToast = false
                                }
                            }
                        }
                }
            }
        }
    }

    private func shareToKakao() {
        // Kakao sharing would be implemented here
        // Requires KakaoSDK integration
    }
}

// MARK: - Share Menu (Helper)
struct ShareMenu<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Section("SNS 공유") {
            content
        }
    }
}

// MARK: - Share Sheet View
struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

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

// MARK: - Copied Toast
struct CopiedToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("링크가 복사되었습니다")
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(radius: 4)
        .transition(.move(edge: .top).combined(with: .opacity))
        .padding(.top, 60)
    }
}

// MARK: - Share Preview Card
struct SharePreviewCard: View {
    let content: ShareableContentType
    var onShare: (() -> Void)?
    var onCopyLink: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: content.icon)
                    .font(.title2)
                    .foregroundStyle(Color(hex: "2563EB"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "2563EB").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(content.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(content.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            // Description
            Text(content.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // URL Preview
            if let url = content.universalLinkURL {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.caption)
                    Text(url.host ?? "philfomation.com")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
            }

            Divider()

            // Action Buttons
            HStack(spacing: 16) {
                Button {
                    onShare?()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("공유하기")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "2563EB"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    onCopyLink?()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("링크 복사")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(hex: "2563EB"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "2563EB").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Quick Share Bar
struct QuickShareBar: View {
    let content: ShareableContentType
    @State private var showShareSheet = false
    @State private var showCopiedToast = false

    var body: some View {
        HStack(spacing: 0) {
            // Like/Bookmark buttons would go here (passed from parent)

            Spacer()

            // Share Button
            Button {
                showShareSheet = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                    Text("공유")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)

            // Copy Link Button
            Button {
                if ShareService.shared.copyLink(for: content) {
                    showCopiedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopiedToast = false
                    }
                }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "link")
                        .font(.title3)
                    Text("링크")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: ShareService.shared.generateShareItems(for: content))
        }
        .overlay {
            if showCopiedToast {
                CopiedToast()
                    .animation(.spring(), value: showCopiedToast)
            }
        }
    }
}
