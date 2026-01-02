//
//  CommunityViewModel.swift
//  Philfomation
//

import Foundation
import SwiftUI
import Combine
import UIKit
import FirebaseFirestore

// MARK: - Post Sort Option
enum PostSortOption: String, CaseIterable, Identifiable {
    case latest = "최신순"
    case popular = "인기순"

    var id: String { rawValue }
}

@MainActor
class CommunityViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var posts: [Post] = []
    @Published var selectedCategory: PostCategory? = nil
    @Published var selectedSort: PostSortOption = .latest
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var isOfflineMode = false
    @Published var hasMoreData = true

    // MARK: - Private Properties
    private let service = PostService.shared
    private var blockedUserIds: Set<String> = []
    private let cacheManager = OfflineCacheManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20

    // MARK: - Computed Properties
    var filteredPosts: [Post] {
        var result = posts

        // 차단된 사용자 필터링
        if !blockedUserIds.isEmpty {
            result = result.filter { !blockedUserIds.contains($0.authorId) }
        }

        // 검색어 필터링
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.content.lowercased().contains(query)
            }
        }

        return result
    }

    // MARK: - Initialization
    init() {
        Task {
            await fetchPosts()
        }
    }

    // MARK: - Block Management
    func loadBlockedUsers(userId: String) async {
        blockedUserIds = await BlockService.shared.fetchBlockedUserIds(userId: userId)
    }

    func refreshBlockedUsers(userId: String) async {
        blockedUserIds = await BlockService.shared.fetchBlockedUserIds(userId: userId, forceRefresh: true)
    }

    // MARK: - Methods
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil
        isOfflineMode = false
        lastDocument = nil
        hasMoreData = true

        // Check network connectivity
        if !networkMonitor.isConnected {
            // Load from cache when offline
            if let cachedPosts = cacheManager.loadPosts() {
                posts = cachedPosts
                isOfflineMode = true
                errorMessage = nil
                hasMoreData = false
            } else {
                errorMessage = "오프라인 상태입니다. 캐시된 데이터가 없습니다."
            }
            isLoading = false
            return
        }

        do {
            let result = try await service.fetchPostsPaginated(
                category: selectedCategory,
                sortBy: selectedSort,
                limit: pageSize,
                lastDocument: nil
            )
            posts = result.posts
            lastDocument = result.lastDocument
            hasMoreData = result.posts.count == pageSize

            // Save to cache for offline use
            cacheManager.savePosts(posts)
            // Save popular posts to widget
            savePopularPostsToWidget()
        } catch {
            // Try to load from cache on error
            if let cachedPosts = cacheManager.loadPosts() {
                posts = cachedPosts
                isOfflineMode = true
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func loadMorePosts() async {
        guard !isLoadingMore, hasMoreData, !isOfflineMode else { return }

        isLoadingMore = true

        do {
            let result = try await service.fetchPostsPaginated(
                category: selectedCategory,
                sortBy: selectedSort,
                limit: pageSize,
                lastDocument: lastDocument
            )

            posts.append(contentsOf: result.posts)
            lastDocument = result.lastDocument
            hasMoreData = result.posts.count == pageSize
        } catch {
            print("Error loading more posts: \(error)")
        }

        isLoadingMore = false
    }

    func setCategory(_ category: PostCategory?) {
        selectedCategory = category
        Task {
            await fetchPosts()
        }
    }

    func setSort(_ sort: PostSortOption) {
        selectedSort = sort
        Task {
            await fetchPosts()
        }
    }

    func createPost(title: String, content: String, category: PostCategory, authorId: String, authorName: String, images: [UIImage] = []) async -> Bool {
        do {
            // Upload images first if any
            var imageURLs: [String]? = nil
            if !images.isEmpty {
                let tempPostId = UUID().uuidString
                imageURLs = try await StorageService.shared.uploadPostImages(images, postId: tempPostId)
            }

            let post = Post(
                authorId: authorId,
                authorName: authorName,
                category: category,
                title: title,
                content: content,
                imageURLs: imageURLs,
                likeCount: 0,
                commentCount: 0,
                viewCount: 0,
                createdAt: Date(),
                updatedAt: nil
            )

            _ = try await service.createPost(post)
            await fetchPosts()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deletePost(_ post: Post) async -> Bool {
        guard let id = post.id else { return false }

        do {
            try await service.deletePost(id: id)
            posts.removeAll { $0.id == id }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func searchPosts() async {
        guard !searchQuery.isEmpty else {
            await fetchPosts()
            return
        }

        isLoading = true

        do {
            posts = try await service.searchPosts(query: searchQuery)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Widget Data
    private func savePopularPostsToWidget() {
        // Get top 3 posts by like count
        let topPosts = posts
            .sorted { $0.likeCount > $1.likeCount }
            .prefix(3)
            .map { PopularPostData(
                id: $0.id ?? "",
                title: $0.title,
                category: $0.category.rawValue,
                likeCount: $0.likeCount
            )}

        WidgetDataManager.shared.savePopularPosts(Array(topPosts))
    }
}

// MARK: - Post Detail ViewModel
@MainActor
class PostDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var post: Post?
    @Published var comments: [Comment] = []
    @Published var isLiked = false
    @Published var isBookmarked = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let service = PostService.shared
    private let postId: String

    // MARK: - Initialization
    init(postId: String) {
        self.postId = postId
        Task {
            await loadPost()
        }
    }

    // MARK: - Methods
    func loadPost() async {
        isLoading = true

        do {
            post = try await service.fetchPost(id: postId)
            comments = try await service.fetchComments(postId: postId)
            try await service.incrementViewCount(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func checkLikeStatus(userId: String) async {
        do {
            isLiked = try await service.checkIfLiked(userId: userId, targetId: postId)
        } catch {
            print("Error checking like status: \(error)")
        }
    }

    func checkBookmarkStatus(userId: String) async {
        do {
            isBookmarked = try await BookmarkService.shared.isBookmarked(userId: userId, postId: postId)
        } catch {
            print("Error checking bookmark status: \(error)")
        }
    }

    func toggleBookmark(userId: String) async {
        guard let currentPost = post else { return }

        do {
            isBookmarked = try await BookmarkService.shared.toggleBookmark(userId: userId, post: currentPost)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleLike(userId: String, userName: String) async {
        do {
            isLiked = try await service.toggleLike(userId: userId, targetId: postId, targetType: .post)
            // Update local post like count
            if var currentPost = post {
                currentPost.likeCount += isLiked ? 1 : -1
                post = currentPost

                // Send notification only when liking (not unliking)
                if isLiked {
                    try? await NotificationService.shared.createLikeNotification(
                        targetAuthorId: currentPost.authorId,
                        targetType: .post,
                        targetId: postId,
                        likerName: userName,
                        likerId: userId
                    )
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addComment(content: String, authorId: String, authorName: String) async -> Bool {
        let comment = Comment(
            postId: postId,
            authorId: authorId,
            authorName: authorName,
            content: content,
            likeCount: 0,
            createdAt: Date(),
            updatedAt: nil
        )

        do {
            _ = try await service.createComment(comment)
            comments = try await service.fetchComments(postId: postId)
            // Update local post comment count
            if var currentPost = post {
                currentPost.commentCount += 1
                post = currentPost

                // Send notification to post author
                try? await NotificationService.shared.createCommentNotification(
                    postAuthorId: currentPost.authorId,
                    postId: postId,
                    commenterName: authorName,
                    commenterId: authorId
                )
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteComment(_ comment: Comment) async -> Bool {
        guard let id = comment.id else { return false }

        do {
            try await service.deleteComment(id: id, postId: postId)
            comments.removeAll { $0.id == id }
            // Update local post comment count
            if var currentPost = post {
                currentPost.commentCount -= 1
                post = currentPost
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updatePost(title: String, content: String, category: PostCategory) async -> Bool {
        guard var currentPost = post else { return false }

        currentPost = Post(
            id: currentPost.id,
            authorId: currentPost.authorId,
            authorName: currentPost.authorName,
            category: category,
            title: title,
            content: content,
            imageURLs: currentPost.imageURLs,
            likeCount: currentPost.likeCount,
            commentCount: currentPost.commentCount,
            viewCount: currentPost.viewCount,
            createdAt: currentPost.createdAt,
            updatedAt: Date()
        )

        do {
            try await service.updatePost(currentPost)
            post = currentPost
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deletePost() async -> Bool {
        guard let id = post?.id else { return false }

        do {
            // Delete images from storage if any
            if let imageURLs = post?.imageURLs, !imageURLs.isEmpty {
                try? await StorageService.shared.deletePostImages(postId: id)
            }
            try await service.deletePost(id: id)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
