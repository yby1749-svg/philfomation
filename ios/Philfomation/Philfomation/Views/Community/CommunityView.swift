//
//  CommunityView.swift
//  Philfomation
//

import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showCreatePost = false
    @State private var showNotifications = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter
                CategoryFilterBar(selectedCategory: $viewModel.selectedCategory) { category in
                    viewModel.setCategory(category)
                }

                // Search Bar & Sort
                HStack(spacing: 12) {
                    CommunitySearchBar(text: $viewModel.searchQuery) {
                        Task {
                            await viewModel.searchPosts()
                        }
                    }

                    SortPicker(selectedSort: $viewModel.selectedSort) { sort in
                        viewModel.setSort(sort)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // Post List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.filteredPosts.isEmpty {
                    Spacer()
                    EmptyPostsView()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.filteredPosts) { post in
                                NavigationLink(destination: PostDetailView(postId: post.id ?? "")) {
                                    PostRowView(post: post)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    // Load more when approaching the end
                                    if post.id == viewModel.filteredPosts.last?.id {
                                        Task {
                                            await viewModel.loadMorePosts()
                                        }
                                    }
                                }

                                Divider()
                                    .padding(.leading, 16)
                            }

                            // Loading more indicator
                            if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("커뮤니티")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NotificationBellButton(
                        viewModel: notificationViewModel,
                        showNotifications: $showNotifications
                    )
                    .foregroundStyle(Color(hex: "2563EB"))
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color(hex: "2563EB"))
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(viewModel: viewModel)
            }
            .sheet(isPresented: $showNotifications) {
                NotificationView()
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    notificationViewModel.setUserId(userId)
                    await viewModel.loadBlockedUsers(userId: userId)
                }
            }
            .refreshable {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.refreshBlockedUsers(userId: userId)
                }
                await viewModel.fetchPosts()
            }
        }
    }
}

// MARK: - Category Filter Bar
struct CategoryFilterBar: View {
    @Binding var selectedCategory: PostCategory?
    var onSelect: (PostCategory?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChipButton(
                    title: "전체",
                    isSelected: selectedCategory == nil,
                    color: Color(hex: "2563EB")
                ) {
                    onSelect(nil)
                }

                ForEach(PostCategory.allCases) { category in
                    FilterChipButton(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        color: Color(hex: category.color)
                    ) {
                        onSelect(category)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: 56)
    }
}

struct FilterChipButton: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sort Picker
struct SortPicker: View {
    @Binding var selectedSort: PostSortOption
    var onSelect: (PostSortOption) -> Void

    var body: some View {
        Menu {
            ForEach(PostSortOption.allCases) { option in
                Button {
                    onSelect(option)
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if selectedSort == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedSort == .latest ? "clock" : "flame.fill")
                    .font(.caption)
                Text(selectedSort.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Community Search Bar
struct CommunitySearchBar: View {
    @Binding var text: String
    var onSearch: () -> Void

    @FocusState private var isFocused: Bool
    @ObservedObject private var historyManager = SearchHistoryManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("게시글 검색", text: $text)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .focused($isFocused)
                    .onSubmit {
                        if !text.isEmpty {
                            historyManager.addSearch(text, type: .community)
                        }
                        onSearch()
                    }

                if !text.isEmpty {
                    Button {
                        text = ""
                        onSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Search History
            if isFocused && text.isEmpty {
                SearchHistoryView(searchType: .community) { query in
                    text = query
                    historyManager.addSearch(query, type: .community)
                    onSearch()
                    isFocused = false
                }
            }
        }
    }
}

// MARK: - Post Row View
struct PostRowView: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category Badge
            HStack {
                Text(post.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: post.category.color))
                    .clipShape(Capsule())

                Spacer()

                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Title
            Text(post.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Content Preview
            Text(post.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Author & Stats
            HStack {
                Text(post.authorName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 12) {
                    Label("\(post.viewCount)", systemImage: "eye")
                    Label("\(post.likeCount)", systemImage: "heart")
                    Label("\(post.commentCount)", systemImage: "bubble.right")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Empty Posts View
struct EmptyPostsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("게시글이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("첫 번째 게시글을 작성해보세요!")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    CommunityView()
        .environmentObject(AuthViewModel())
}
