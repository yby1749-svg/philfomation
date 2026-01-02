//
//  PostService.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

class PostService {
    static let shared = PostService()

    private let db = Firestore.firestore()
    private let postsCollection = "posts"
    private let commentsCollection = "comments"
    private let likesCollection = "likes"

    private init() {}

    // MARK: - Posts

    func fetchPosts(category: PostCategory? = nil, sortBy: PostSortOption = .latest, limit: Int = 20) async throws -> [Post] {
        let orderField = sortBy == .latest ? "createdAt" : "likeCount"

        var query: Query

        if let category = category {
            query = db.collection(postsCollection)
                .whereField("category", isEqualTo: category.rawValue)
                .order(by: orderField, descending: true)
                .limit(to: limit)
        } else {
            query = db.collection(postsCollection)
                .order(by: orderField, descending: true)
                .limit(to: limit)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Post.self) }
    }

    // Paginated version
    func fetchPostsPaginated(
        category: PostCategory? = nil,
        sortBy: PostSortOption = .latest,
        limit: Int = 20,
        lastDocument: DocumentSnapshot? = nil
    ) async throws -> (posts: [Post], lastDocument: DocumentSnapshot?) {
        let orderField = sortBy == .latest ? "createdAt" : "likeCount"

        var query: Query

        if let category = category {
            query = db.collection(postsCollection)
                .whereField("category", isEqualTo: category.rawValue)
                .order(by: orderField, descending: true)
                .limit(to: limit)
        } else {
            query = db.collection(postsCollection)
                .order(by: orderField, descending: true)
                .limit(to: limit)
        }

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()
        let posts = snapshot.documents.compactMap { try? $0.data(as: Post.self) }
        let lastDoc = snapshot.documents.last

        return (posts, lastDoc)
    }

    func fetchPost(id: String) async throws -> Post? {
        let document = try await db.collection(postsCollection).document(id).getDocument()
        return try? document.data(as: Post.self)
    }

    func createPost(_ post: Post) async throws -> String {
        let ref = try db.collection(postsCollection).addDocument(from: post)
        return ref.documentID
    }

    func updatePost(_ post: Post) async throws {
        guard let id = post.id else { return }
        try db.collection(postsCollection).document(id).setData(from: post, merge: true)
    }

    func deletePost(id: String) async throws {
        try await db.collection(postsCollection).document(id).delete()
        // Also delete associated comments
        let comments = try await db.collection(commentsCollection)
            .whereField("postId", isEqualTo: id)
            .getDocuments()

        for doc in comments.documents {
            try await doc.reference.delete()
        }
    }

    func incrementViewCount(postId: String) async throws {
        try await db.collection(postsCollection).document(postId).updateData([
            "viewCount": FieldValue.increment(Int64(1))
        ])
    }

    // MARK: - Comments

    func fetchComments(postId: String) async throws -> [Comment] {
        let snapshot = try await db.collection(commentsCollection)
            .whereField("postId", isEqualTo: postId)
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
    }

    func createComment(_ comment: Comment) async throws -> String {
        let ref = try db.collection(commentsCollection).addDocument(from: comment)

        // Update comment count on post
        try await db.collection(postsCollection).document(comment.postId).updateData([
            "commentCount": FieldValue.increment(Int64(1))
        ])

        return ref.documentID
    }

    func deleteComment(id: String, postId: String) async throws {
        try await db.collection(commentsCollection).document(id).delete()

        // Decrement comment count on post
        try await db.collection(postsCollection).document(postId).updateData([
            "commentCount": FieldValue.increment(Int64(-1))
        ])
    }

    // MARK: - Likes

    func toggleLike(userId: String, targetId: String, targetType: LikeTargetType) async throws -> Bool {
        let likeId = "\(userId)_\(targetId)"
        let likeRef = db.collection(likesCollection).document(likeId)

        let likeDoc = try await likeRef.getDocument()

        if likeDoc.exists {
            // Unlike
            try await likeRef.delete()
            try await updateLikeCount(targetId: targetId, targetType: targetType, increment: false)
            return false
        } else {
            // Like
            let like = Like(
                id: likeId,
                userId: userId,
                targetId: targetId,
                targetType: targetType,
                createdAt: Date()
            )
            try likeRef.setData(from: like)
            try await updateLikeCount(targetId: targetId, targetType: targetType, increment: true)
            return true
        }
    }

    func checkIfLiked(userId: String, targetId: String) async throws -> Bool {
        let likeId = "\(userId)_\(targetId)"
        let likeDoc = try await db.collection(likesCollection).document(likeId).getDocument()
        return likeDoc.exists
    }

    private func updateLikeCount(targetId: String, targetType: LikeTargetType, increment: Bool) async throws {
        let collection = targetType == .post ? postsCollection : commentsCollection
        let value: Int64 = increment ? 1 : -1
        try await db.collection(collection).document(targetId).updateData([
            "likeCount": FieldValue.increment(value)
        ])
    }

    // MARK: - Search

    func searchPosts(query: String) async throws -> [Post] {
        // Simple title search - for more advanced search, consider Algolia or similar
        let snapshot = try await db.collection(postsCollection)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        let posts = snapshot.documents.compactMap { try? $0.data(as: Post.self) }
        let lowercasedQuery = query.lowercased()

        return posts.filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            $0.content.lowercased().contains(lowercasedQuery)
        }
    }
}
