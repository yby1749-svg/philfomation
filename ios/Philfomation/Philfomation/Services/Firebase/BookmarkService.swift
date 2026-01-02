//
//  BookmarkService.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

class BookmarkService {
    static let shared = BookmarkService()

    private let db = Firestore.firestore()
    private let bookmarksCollection = "bookmarks"

    private init() {}

    // MARK: - Toggle Bookmark

    func toggleBookmark(userId: String, post: Post) async throws -> Bool {
        guard let postId = post.id else { return false }

        let bookmarkId = "\(userId)_\(postId)"
        let bookmarkRef = db.collection(bookmarksCollection).document(bookmarkId)

        let bookmarkDoc = try await bookmarkRef.getDocument()

        if bookmarkDoc.exists {
            // Remove bookmark
            try await bookmarkRef.delete()
            return false
        } else {
            // Add bookmark
            let bookmark = Bookmark(
                id: bookmarkId,
                userId: userId,
                postId: postId,
                postTitle: post.title,
                postCategory: post.category,
                postAuthorName: post.authorName,
                createdAt: Date()
            )
            try bookmarkRef.setData(from: bookmark)
            return true
        }
    }

    // MARK: - Check if Bookmarked

    func isBookmarked(userId: String, postId: String) async throws -> Bool {
        let bookmarkId = "\(userId)_\(postId)"
        let bookmarkDoc = try await db.collection(bookmarksCollection).document(bookmarkId).getDocument()
        return bookmarkDoc.exists
    }

    // MARK: - Fetch User Bookmarks

    func fetchUserBookmarks(userId: String) async throws -> [Bookmark] {
        let snapshot = try await db.collection(bookmarksCollection)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Bookmark.self) }
    }

    // MARK: - Remove Bookmark

    func removeBookmark(userId: String, postId: String) async throws {
        let bookmarkId = "\(userId)_\(postId)"
        try await db.collection(bookmarksCollection).document(bookmarkId).delete()
    }

    // MARK: - Remove All Bookmarks for Post

    func removeAllBookmarksForPost(postId: String) async throws {
        let snapshot = try await db.collection(bookmarksCollection)
            .whereField("postId", isEqualTo: postId)
            .getDocuments()

        for doc in snapshot.documents {
            try await doc.reference.delete()
        }
    }
}
