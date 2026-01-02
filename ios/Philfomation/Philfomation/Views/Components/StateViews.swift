//
//  StateViews.swift
//  Philfomation
//

import SwiftUI

// MARK: - Enhanced Empty State View (with action button)

struct EnhancedEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
                .scaleEffect(isAnimating ? 1 : 0.8)
                .opacity(isAnimating ? 1 : 0)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .offset(y: isAnimating ? 0 : 10)
            .opacity(isAnimating ? 1 : 0)

            if let actionTitle = actionTitle, let action = action {
                Button {
                    HapticManager.shared.lightImpactOccurred()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "2563EB"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.scale)
                .offset(y: isAnimating ? 0 : 20)
                .opacity(isAnimating ? 1 : 0)
            }
        }
        .padding(32)
        .onAppear {
            withAnimation(.smoothSpring.delay(0.1)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let title: String
    let message: String
    var retryAction: (() -> Void)? = nil

    @State private var shake = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
                .modifier(ShakeEffect(animatableData: shake ? 1 : 0))

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button {
                    HapticManager.shared.mediumImpactOccurred()
                    retryAction()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("다시 시도")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "2563EB"))
                    .clipShape(Capsule())
                }
                .buttonStyle(.scale)
            }
        }
        .padding(32)
        .onAppear {
            withAnimation(.default.delay(0.2)) {
                shake = true
            }
        }
    }
}

// MARK: - Network Error View

struct NetworkErrorView: View {
    var retryAction: (() -> Void)? = nil

    var body: some View {
        ErrorStateView(
            title: "네트워크 오류",
            message: "인터넷 연결을 확인해주세요",
            retryAction: retryAction
        )
    }
}

// MARK: - No Results View

struct NoResultsView: View {
    let searchQuery: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            VStack(spacing: 8) {
                Text("검색 결과 없음")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("'\(searchQuery)'에 대한 검색 결과가 없습니다")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .animatedAppear()
    }
}

// MARK: - Success Checkmark Animation

struct SuccessCheckmark: View {
    @State private var showCheckmark = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 80, height: 80)

            Circle()
                .stroke(Color.green, lineWidth: 3)
                .frame(width: 60, height: 60)

            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.green)
                .scaleEffect(showCheckmark ? 1 : 0)
                .opacity(showCheckmark ? 1 : 0)
        }
        .onAppear {
            HapticManager.shared.success()
            withAnimation(.bouncy.delay(0.2)) {
                showCheckmark = true
            }
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                RotatingLoader()

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Confirmation Dialog

struct ConfirmationDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    var isDestructive: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    HapticManager.shared.lightImpactOccurred()
                    cancelAction()
                } label: {
                    Text("취소")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.scale)

                Button {
                    HapticManager.shared.mediumImpactOccurred()
                    confirmAction()
                } label: {
                    Text(confirmTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isDestructive ? Color.red : Color(hex: "2563EB"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.scale)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        .padding(.horizontal, 32)
    }
}

// MARK: - Previews

#Preview("Empty State") {
    EnhancedEmptyStateView(
        icon: "doc.text",
        title: "게시글이 없습니다",
        message: "첫 번째 게시글을 작성해보세요!",
        actionTitle: "글쓰기"
    ) {
        print("Action tapped")
    }
}

#Preview("Error State") {
    ErrorStateView(
        title: "오류 발생",
        message: "데이터를 불러오는데 실패했습니다"
    ) {
        print("Retry tapped")
    }
}

#Preview("Success Checkmark") {
    SuccessCheckmark()
}

#Preview("Loading Overlay") {
    LoadingOverlay(message: "저장 중...")
}
