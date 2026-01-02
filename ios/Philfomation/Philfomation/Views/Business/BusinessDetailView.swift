//
//  BusinessDetailView.swift
//  Philfomation
//

import SwiftUI

struct BusinessDetailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = BusinessViewModel()
    @State private var showReviewForm = false
    @State private var showChat = false

    let business: Business

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Photo Gallery
                PhotoGallery(photos: business.photos)

                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            CategoryBadge(category: business.category)
                            Spacer()
                        }

                        Text(business.name)
                            .font(.title)
                            .fontWeight(.bold)

                        HStack(spacing: 4) {
                            RatingStars(rating: business.rating)
                            Text(String(format: "%.1f", business.rating))
                                .fontWeight(.semibold)
                            Text("(\(business.reviewCount))")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(icon: "mappin.circle.fill", text: business.address)

                        if let phone = business.phone {
                            InfoRow(icon: "phone.circle.fill", text: phone, isLink: true)
                        }

                        if let hours = business.openingHours {
                            InfoRow(icon: "clock.fill", text: hours)
                        }
                    }

                    if let description = business.description {
                        Divider()
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Action Buttons
                    HStack(spacing: 12) {
                        Button {
                            showChat = true
                        } label: {
                            Label("문의하기", systemImage: "bubble.left.fill")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color(hex: "2563EB"))

                        if let phone = business.phone,
                           let url = URL(string: "tel://\(phone.replacingOccurrences(of: "-", with: ""))") {
                            Link(destination: url) {
                                Label("전화하기", systemImage: "phone.fill")
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: "10B981"))
                        }
                    }

                    Divider()

                    // Reviews Section
                    ReviewSection(
                        reviews: viewModel.reviews,
                        onWriteReview: { showReviewForm = true }
                    )
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    shareBusiness()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task {
            if let id = business.id {
                await viewModel.fetchReviews(businessId: id)
            }
        }
        .sheet(isPresented: $showReviewForm) {
            ReviewFormView(business: business)
                .environmentObject(viewModel)
        }
    }

    private func shareBusiness() {
        guard let businessId = business.id else { return }

        let shareURL = DeepLinkManager.shared.universalShareURL(for: .business(id: businessId))
        let text = """
        \(business.name)
        \(business.category.rawValue) | \(business.address)

        Philfomation에서 보기: \(shareURL.absoluteString)
        """

        let activityVC = UIActivityViewController(
            activityItems: [text, shareURL],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct PhotoGallery: View {
    let photos: [String]

    var body: some View {
        if photos.isEmpty {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 250)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                }
        } else {
            TabView {
                ForEach(photos, id: \.self) { url in
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay { ProgressView() }
                    }
                }
            }
            .frame(height: 250)
            .tabViewStyle(.page)
        }
    }
}

struct CategoryBadge: View {
    let category: BusinessCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
            Text(category.rawValue)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "F59E0B").opacity(0.15))
        .foregroundStyle(Color(hex: "F59E0B"))
        .clipShape(Capsule())
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    var isLink: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "2563EB"))
                .frame(width: 24)

            if isLink, let url = URL(string: "tel://\(text.replacingOccurrences(of: "-", with: ""))") {
                Link(text, destination: url)
                    .foregroundStyle(.primary)
            } else {
                Text(text)
                    .foregroundStyle(.primary)
            }
        }
    }
}

struct RatingStars: View {
    let rating: Double
    let maxRating = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: starType(for: index))
                    .foregroundStyle(Color(hex: "F59E0B"))
                    .font(.caption)
            }
        }
    }

    private func starType(for index: Int) -> String {
        if Double(index) <= rating {
            return "star.fill"
        } else if Double(index) - 0.5 <= rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

struct ReviewSection: View {
    let reviews: [Review]
    let onWriteReview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("리뷰 (\(reviews.count))")
                    .font(.headline)

                Spacer()

                Button(action: onWriteReview) {
                    Label("리뷰 쓰기", systemImage: "square.and.pencil")
                        .font(.subheadline)
                }
            }

            if reviews.isEmpty {
                Text("아직 리뷰가 없습니다. 첫 리뷰를 작성해보세요!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(reviews) { review in
                    ReviewCard(review: review)
                    if review.id != reviews.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BusinessDetailView(business: Business(
            name: "테스트 업소",
            category: .restaurant,
            address: "마닐라 마카티",
            phone: "02-123-4567",
            rating: 4.5,
            reviewCount: 10
        ))
        .environmentObject(AuthViewModel())
    }
}
