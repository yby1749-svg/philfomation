//
//  BookmarksView.swift
//  Philfomation
//

import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var bookmarks: [Bookmark] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if bookmarks.isEmpty {
                EmptyBookmarksView()
            } else {
                List {
                    ForEach(bookmarks) { bookmark in
                        NavigationLink {
                            PostDetailView(postId: bookmark.postId)
                        } label: {
                            BookmarkRowView(bookmark: bookmark)
                        }
                    }
                    .onDelete(perform: deleteBookmark)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("저장한 글")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchBookmarks()
        }
        .refreshable {
            await fetchBookmarks()
        }
    }

    private func fetchBookmarks() async {
        guard let userId = authViewModel.currentUser?.id else { return }

        isLoading = true
        do {
            bookmarks = try await BookmarkService.shared.fetchUserBookmarks(userId: userId)
        } catch {
            print("Error fetching bookmarks: \(error)")
        }
        isLoading = false
    }

    private func deleteBookmark(at offsets: IndexSet) {
        guard let userId = authViewModel.currentUser?.id else { return }

        for index in offsets {
            let bookmark = bookmarks[index]
            Task {
                try? await BookmarkService.shared.removeBookmark(
                    userId: userId,
                    postId: bookmark.postId
                )
            }
        }
        bookmarks.remove(atOffsets: offsets)
    }
}

// MARK: - Bookmark Row View
struct BookmarkRowView: View {
    let bookmark: Bookmark

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(bookmark.postCategory.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: bookmark.postCategory.color))
                    .clipShape(Capsule())

                Spacer()

                Text(bookmark.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(bookmark.postTitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(bookmark.postAuthorName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Bookmarks View
struct EmptyBookmarksView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("저장한 글이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("관심있는 게시글을 저장해보세요")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        BookmarksView()
            .environmentObject(AuthViewModel())
    }
}
