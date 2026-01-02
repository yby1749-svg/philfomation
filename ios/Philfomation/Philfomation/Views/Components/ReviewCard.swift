//
//  ReviewCard.swift
//  Philfomation
//

import SwiftUI

struct ReviewCard: View {
    let review: Review
    var showDeleteButton: Bool = false
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                AsyncProfileImage(url: review.userPhotoURL, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= review.rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "F59E0B"))
                        }

                        Text(formatDate(review.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if showDeleteButton {
                    Button {
                        onDelete?()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }

            // Comment
            Text(review.comment)
                .font(.subheadline)
                .lineLimit(nil)

            // Photos
            if !review.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(review.photos, id: \.self) { url in
                            CachedAsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay { ProgressView() }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.M.d"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        ReviewCard(review: Review(
            businessId: "1",
            userId: "user1",
            userName: "홍길동",
            rating: 5,
            comment: "정말 맛있어요! 다음에 또 방문할게요. 서비스도 친절하고 분위기도 좋았습니다."
        ))

        Divider()

        ReviewCard(review: Review(
            businessId: "1",
            userId: "user2",
            userName: "김철수",
            rating: 4,
            comment: "음식은 좋았는데 대기시간이 조금 길었어요.",
            photos: ["https://example.com/photo1.jpg"]
        ), showDeleteButton: true)
    }
    .padding()
}
