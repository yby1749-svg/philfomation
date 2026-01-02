//
//  PostDetailView.swift
//  Philfomation
//

import SwiftUI

struct PostDetailView: View {
    @StateObject private var viewModel: PostDetailViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @FocusState private var isCommentFocused: Bool
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showReportSheet = false
    @State private var showBlockAlert = false

    init(postId: String) {
        _viewModel = StateObject(wrappedValue: PostDetailViewModel(postId: postId))
    }

    private var isAuthor: Bool {
        guard let currentUserId = authViewModel.currentUser?.id,
              let postAuthorId = viewModel.post?.authorId else {
            return false
        }
        return currentUserId == postAuthorId
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let post = viewModel.post {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Post Content
                        PostContentView(post: post, viewModel: viewModel)

                        Divider()

                        // Comments Section
                        CommentsSection(comments: viewModel.comments, viewModel: viewModel)
                    }
                    .padding()
                }

                Divider()

                // Comment Input
                CommentInputView(
                    text: $commentText,
                    isFocused: $isCommentFocused
                ) {
                    Task {
                        await submitComment()
                    }
                }
            } else {
                Spacer()
                Text("게시글을 불러올 수 없습니다")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .navigationTitle("게시글")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if isAuthor {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("수정", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }

                        Divider()
                    }

                    Button {
                        showReportSheet = true
                    } label: {
                        Label("신고", systemImage: "exclamationmark.triangle")
                    }

                    if !isAuthor {
                        Button(role: .destructive) {
                            showBlockAlert = true
                        } label: {
                            Label("사용자 차단", systemImage: "person.fill.xmark")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let post = viewModel.post {
                EditPostView(post: post, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            if let post = viewModel.post {
                ReportView(
                    targetType: .post,
                    targetId: post.id ?? "",
                    targetAuthorId: post.authorId
                )
            }
        }
        .alert("게시글 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                Task {
                    let success = await viewModel.deletePost()
                    if success {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.")
        }
        .alert("사용자 차단", isPresented: $showBlockAlert) {
            Button("취소", role: .cancel) {}
            Button("차단", role: .destructive) {
                Task {
                    await blockUser()
                }
            }
        } message: {
            Text("\(viewModel.post?.authorName ?? "이 사용자")님을 차단하시겠습니까?\n차단된 사용자의 게시글과 댓글이 더 이상 표시되지 않습니다.")
        }
        .task {
            if let userId = authViewModel.currentUser?.id {
                await viewModel.checkLikeStatus(userId: userId)
                await viewModel.checkBookmarkStatus(userId: userId)
            }
        }
    }

    private func submitComment() async {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let user = authViewModel.currentUser else { return }

        let success = await viewModel.addComment(
            content: commentText,
            authorId: user.id ?? "",
            authorName: user.name
        )

        if success {
            commentText = ""
            isCommentFocused = false
        }
    }

    private func blockUser() async {
        guard let currentUserId = authViewModel.currentUser?.id,
              let post = viewModel.post else { return }

        // 차단할 사용자 정보 생성
        let blockedUser = AppUser(
            id: post.authorId,
            name: post.authorName,
            email: ""
        )

        do {
            try await BlockService.shared.blockUser(
                blockerId: currentUserId,
                blockedUser: blockedUser
            )
            dismiss()
        } catch {
            print("Error blocking user: \(error)")
        }
    }
}

// MARK: - Post Content View
struct PostContentView: View {
    let post: Post
    @ObservedObject var viewModel: PostDetailViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category & Time
            HStack {
                Text(post.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: post.category.color))
                    .clipShape(Capsule())

                Spacer()

                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Title
            Text(post.title)
                .font(.title3)
                .fontWeight(.bold)

            // Author Info
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.secondary)
                Text(post.authorName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("조회 \(post.viewCount)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            // Content
            Text(post.content)
                .font(.body)
                .lineSpacing(6)

            // Images
            if let imageURLs = post.imageURLs, !imageURLs.isEmpty {
                URLImageGridView(imageURLs: imageURLs)
                    .padding(.top, 8)
            }

            // Action Buttons
            HStack(spacing: 24) {
                Button {
                    Task {
                        if let user = authViewModel.currentUser, let userId = user.id {
                            await viewModel.toggleLike(userId: userId, userName: user.name)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(viewModel.isLiked ? .red : .secondary)
                        Text("\(viewModel.post?.likeCount ?? 0)")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.post?.commentCount ?? 0)")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        if let userId = authViewModel.currentUser?.id {
                            await viewModel.toggleBookmark(userId: userId)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(viewModel.isBookmarked ? Color(hex: "2563EB") : .secondary)
                }

                Button {
                    sharePost()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .padding(.top, 8)
        }
    }

    private func sharePost() {
        guard let postId = post.id else { return }

        let shareURL = DeepLinkManager.shared.universalShareURL(for: .post(id: postId))
        let text = """
        \(post.title)

        \(post.content)

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

// MARK: - Comments Section
struct CommentsSection: View {
    let comments: [Comment]
    @ObservedObject var viewModel: PostDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("댓글 \(comments.count)")
                .font(.headline)
                .fontWeight(.bold)

            if comments.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.title)
                            .foregroundStyle(.tertiary)
                        Text("첫 번째 댓글을 남겨주세요!")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                ForEach(comments) { comment in
                    CommentRowView(comment: comment)

                    if comment.id != comments.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Comment Row View
struct CommentRowView: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.secondary)

                Text(comment.authorName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(comment.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(comment.content)
                .font(.subheadline)
                .padding(.leading, 24)

            HStack {
                Spacer()

                Button {
                    // Like comment
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "heart")
                        Text("\(comment.likeCount)")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Comment Input View
struct CommentInputView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("댓글을 입력하세요", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .focused(isFocused)
                .lineLimit(1...4)

            Button(action: onSubmit) {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(text.isEmpty ? Color.gray : Color(hex: "2563EB"))
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
}

#Preview {
    NavigationStack {
        PostDetailView(postId: "sample")
            .environmentObject(AuthViewModel())
    }
}
