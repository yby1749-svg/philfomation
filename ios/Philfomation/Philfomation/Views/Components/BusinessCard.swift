//
//  BusinessCard.swift
//  Philfomation
//

import SwiftUI

struct BusinessCard: View {
    let business: Business

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let firstPhoto = business.photos.first {
                CachedAsyncImage(url: firstPhoto) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: business.category.icon)
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: business.category.icon)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(business.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "F59E0B").opacity(0.15))
                        .foregroundStyle(Color(hex: "F59E0B"))
                        .clipShape(Capsule())

                    Spacer()
                }

                Text(business.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "F59E0B"))

                    Text(String(format: "%.1f", business.rating))
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("(\(business.reviewCount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(business.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    VStack {
        BusinessCard(business: Business(
            name: "마닐라 한식당",
            category: .restaurant,
            address: "마카티 레가스피 빌리지",
            rating: 4.5,
            reviewCount: 128
        ))

        BusinessCard(business: Business(
            name: "필리핀 마사지",
            category: .massage,
            address: "보니파시오 글로벌 시티",
            rating: 4.2,
            reviewCount: 56
        ))
    }
    .padding()
    .background(Color(.systemGray6))
}
