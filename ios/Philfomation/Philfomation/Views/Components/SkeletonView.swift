//
//  SkeletonView.swift
//  Philfomation
//

import SwiftUI

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.4),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Shape

struct SkeletonShape: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Business Card Skeleton

struct BusinessCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail skeleton
            SkeletonShape(width: 80, height: 80, cornerRadius: 12)

            // Info skeleton
            VStack(alignment: .leading, spacing: 8) {
                SkeletonShape(width: 60, height: 20, cornerRadius: 10)
                SkeletonShape(height: 18)
                SkeletonShape(width: 100, height: 14)
                SkeletonShape(width: 150, height: 12)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Post Row Skeleton

struct PostRowSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SkeletonShape(width: 50, height: 22, cornerRadius: 11)
                Spacer()
                SkeletonShape(width: 40, height: 12)
            }

            SkeletonShape(height: 18)
            SkeletonShape(width: 250, height: 14)

            HStack {
                SkeletonShape(width: 60, height: 12)
                Spacer()
                HStack(spacing: 12) {
                    SkeletonShape(width: 30, height: 12)
                    SkeletonShape(width: 30, height: 12)
                    SkeletonShape(width: 30, height: 12)
                }
            }
        }
        .padding()
    }
}

// MARK: - Profile Skeleton

struct ProfileSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 100, height: 100)
                .shimmer()

            // Name
            SkeletonShape(width: 120, height: 24)

            // Email
            SkeletonShape(width: 180, height: 16)

            // Stats
            HStack(spacing: 40) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 4) {
                        SkeletonShape(width: 40, height: 24)
                        SkeletonShape(width: 50, height: 14)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Detail Skeleton

struct DetailSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Image
            SkeletonShape(height: 200, cornerRadius: 0)

            VStack(alignment: .leading, spacing: 12) {
                SkeletonShape(width: 80, height: 24, cornerRadius: 12)
                SkeletonShape(height: 28)
                SkeletonShape(width: 200, height: 16)

                Divider()

                ForEach(0..<4, id: \.self) { _ in
                    SkeletonShape(height: 16)
                }
                SkeletonShape(width: 180, height: 16)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Skeleton List

struct SkeletonList<Skeleton: View>: View {
    let count: Int
    let skeleton: () -> Skeleton

    init(count: Int = 5, @ViewBuilder skeleton: @escaping () -> Skeleton) {
        self.count = count
        self.skeleton = skeleton
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                skeleton()
            }
        }
    }
}

// MARK: - Loading State View

struct LoadingStateView<Content: View, Loading: View>: View {
    let isLoading: Bool
    let content: () -> Content
    let loading: () -> Loading

    init(
        isLoading: Bool,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder loading: @escaping () -> Loading
    ) {
        self.isLoading = isLoading
        self.content = content
        self.loading = loading
    }

    var body: some View {
        if isLoading {
            loading()
        } else {
            content()
        }
    }
}

// MARK: - Previews

#Preview("Business Card Skeleton") {
    VStack(spacing: 12) {
        BusinessCardSkeleton()
        BusinessCardSkeleton()
    }
    .padding()
    .background(Color(.systemGray6))
}

#Preview("Post Row Skeleton") {
    VStack(spacing: 0) {
        PostRowSkeleton()
        Divider()
        PostRowSkeleton()
        Divider()
        PostRowSkeleton()
    }
}

#Preview("Profile Skeleton") {
    ProfileSkeleton()
}
