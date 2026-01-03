//
//  AdvancedSearchView.swift
//  Philfomation
//

import SwiftUI

// MARK: - Advanced Search Type
enum AdvancedSearchType: String, CaseIterable, Identifiable {
    case all = "전체"
    case posts = "게시글"
    case businesses = "업소"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "magnifyingglass"
        case .posts: return "doc.text"
        case .businesses: return "building.2"
        }
    }
}

// MARK: - Date Filter
enum DateFilter: String, CaseIterable, Identifiable {
    case all = "전체 기간"
    case today = "오늘"
    case week = "이번 주"
    case month = "이번 달"
    case year = "올해"

    var id: String { rawValue }

    var startDate: Date? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .all: return nil
        case .today: return calendar.startOfDay(for: now)
        case .week: return calendar.date(byAdding: .day, value: -7, to: now)
        case .month: return calendar.date(byAdding: .month, value: -1, to: now)
        case .year: return calendar.date(byAdding: .year, value: -1, to: now)
        }
    }
}

// MARK: - Rating Filter
enum RatingFilter: String, CaseIterable, Identifiable {
    case all = "전체"
    case fourPlus = "4.0+"
    case fourFivePlus = "4.5+"

    var id: String { rawValue }

    var minRating: Double {
        switch self {
        case .all: return 0
        case .fourPlus: return 4.0
        case .fourFivePlus: return 4.5
        }
    }
}

// MARK: - Advanced Search View
struct AdvancedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AdvancedSearchViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBarView(
                    searchText: $viewModel.searchQuery,
                    isSearching: $viewModel.isSearching,
                    onSubmit: {
                        viewModel.performSearch()
                    }
                )
                .focused($isSearchFocused)
                .padding()

                // Search Type Picker
                Picker("검색 유형", selection: $viewModel.searchType) {
                    ForEach(AdvancedSearchType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Filter Chips
                FilterChipsView(viewModel: viewModel)
                    .padding(.vertical, 12)

                Divider()

                // Results or Suggestions
                if viewModel.searchQuery.isEmpty && !viewModel.isSearching {
                    RecentSearchesView(viewModel: viewModel)
                } else if viewModel.isLoading {
                    LoadingView()
                } else {
                    SearchResultsView(viewModel: viewModel)
                }
            }
            .navigationTitle("검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showFilterSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showFilterSheet) {
                FilterSheetView(viewModel: viewModel)
            }
            .onAppear {
                isSearchFocused = true
            }
        }
    }
}

// MARK: - Search Bar View
struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("검색어를 입력하세요", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .onSubmit(onSubmit)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if isSearching {
                Button("취소") {
                    searchText = ""
                    isSearching = false
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearching)
    }
}

// MARK: - Filter Chips View
struct FilterChipsView: View {
    @ObservedObject var viewModel: AdvancedSearchViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Date Filter (for posts)
                if viewModel.searchType != .businesses {
                    FilterChip(
                        title: viewModel.dateFilter.rawValue,
                        isActive: viewModel.dateFilter != .all,
                        icon: "calendar"
                    ) {
                        viewModel.showDateFilterPicker = true
                    }
                }

                // Category Filter
                if let category = viewModel.selectedPostCategory {
                    FilterChip(
                        title: category.rawValue,
                        isActive: true,
                        icon: "tag"
                    ) {
                        viewModel.selectedPostCategory = nil
                    }
                } else if let category = viewModel.selectedBusinessCategory {
                    FilterChip(
                        title: category.rawValue,
                        isActive: true,
                        icon: "tag"
                    ) {
                        viewModel.selectedBusinessCategory = nil
                    }
                }

                // Rating Filter (for businesses)
                if viewModel.searchType != .posts && viewModel.ratingFilter != .all {
                    FilterChip(
                        title: viewModel.ratingFilter.rawValue,
                        isActive: true,
                        icon: "star"
                    ) {
                        viewModel.ratingFilter = .all
                    }
                }

                // Sort
                FilterChip(
                    title: viewModel.sortOption.rawValue,
                    isActive: false,
                    icon: "arrow.up.arrow.down"
                ) {
                    viewModel.showSortPicker = true
                }
            }
            .padding(.horizontal)
        }
        .confirmationDialog("기간 선택", isPresented: $viewModel.showDateFilterPicker) {
            ForEach(DateFilter.allCases) { filter in
                Button(filter.rawValue) {
                    viewModel.dateFilter = filter
                }
            }
        }
        .confirmationDialog("정렬", isPresented: $viewModel.showSortPicker) {
            Button("최신순") { viewModel.sortOption = .latest }
            Button("인기순") { viewModel.sortOption = .popular }
            if viewModel.searchType != .posts {
                Button("평점순") { viewModel.sortOption = .rating }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isActive: Bool
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                if isActive {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? Color(hex: "2563EB").opacity(0.1) : Color(.systemGray6))
            .foregroundStyle(isActive ? Color(hex: "2563EB") : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Recent Searches View
struct RecentSearchesView: View {
    @ObservedObject var viewModel: AdvancedSearchViewModel

    var body: some View {
        List {
            if !viewModel.recentSearches.isEmpty {
                Section {
                    ForEach(viewModel.recentSearches, id: \.self) { search in
                        Button {
                            viewModel.searchQuery = search
                            viewModel.performSearch()
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                                Text(search)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                    }
                    .onDelete { indexSet in
                        viewModel.deleteRecentSearch(at: indexSet)
                    }
                } header: {
                    HStack {
                        Text("최근 검색")
                        Spacer()
                        Button("전체 삭제") {
                            viewModel.clearRecentSearches()
                        }
                        .font(.caption)
                    }
                }
            }

            Section("인기 검색어") {
                ForEach(viewModel.popularSearches, id: \.self) { search in
                    Button {
                        viewModel.searchQuery = search
                        viewModel.performSearch()
                    } label: {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text(search)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    @ObservedObject var viewModel: AdvancedSearchViewModel

    var body: some View {
        List {
            // Posts Section
            if viewModel.searchType != .businesses && !viewModel.postResults.isEmpty {
                Section {
                    ForEach(viewModel.postResults) { post in
                        NavigationLink {
                            PostDetailView(postId: post.id ?? "")
                        } label: {
                            PostSearchResultRow(post: post, query: viewModel.searchQuery)
                        }
                    }
                } header: {
                    HStack {
                        Text("게시글")
                        Spacer()
                        Text("\(viewModel.postResults.count)개")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Businesses Section
            if viewModel.searchType != .posts && !viewModel.businessResults.isEmpty {
                Section {
                    ForEach(viewModel.businessResults) { business in
                        NavigationLink {
                            BusinessDetailView(business: business)
                        } label: {
                            BusinessSearchResultRow(business: business, query: viewModel.searchQuery)
                        }
                    }
                } header: {
                    HStack {
                        Text("업소")
                        Spacer()
                        Text("\(viewModel.businessResults.count)개")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // No Results
            if viewModel.postResults.isEmpty && viewModel.businessResults.isEmpty && !viewModel.isLoading {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("검색 결과가 없습니다")
                            .font(.headline)
                        Text("다른 검색어나 필터를 시도해보세요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Post Search Result Row
struct PostSearchResultRow: View {
    let post: Post
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: post.category.color).opacity(0.2))
                    .foregroundStyle(Color(hex: post.category.color))
                    .clipShape(Capsule())

                Spacer()

                Text(timeAgo(from: post.createdAt))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(highlightedText(post.title, query: query))
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label("\(post.likeCount)", systemImage: "heart")
                Label("\(post.commentCount)", systemImage: "bubble.right")
                Label("\(post.viewCount)", systemImage: "eye")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func highlightedText(_ text: String, query: String) -> AttributedString {
        var attributedString = AttributedString(text)
        if let range = attributedString.range(of: query, options: .caseInsensitive) {
            attributedString[range].backgroundColor = Color.yellow.opacity(0.3)
        }
        return attributedString
    }
}

// MARK: - Business Search Result Row
struct BusinessSearchResultRow: View {
    let business: Business
    let query: String

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(Color(hex: business.category.color).opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: business.category.icon)
                    .foregroundStyle(Color(hex: business.category.color))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(highlightedText(business.name, query: query))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(business.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", business.rating))
                        .fontWeight(.medium)
                    Text("(\(business.reviewCount))")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func highlightedText(_ text: String, query: String) -> AttributedString {
        var attributedString = AttributedString(text)
        if let range = attributedString.range(of: query, options: .caseInsensitive) {
            attributedString[range].backgroundColor = Color.yellow.opacity(0.3)
        }
        return attributedString
    }
}

// MARK: - Filter Sheet View
struct FilterSheetView: View {
    @ObservedObject var viewModel: AdvancedSearchViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Search Type
                Section("검색 대상") {
                    Picker("유형", selection: $viewModel.searchType) {
                        ForEach(AdvancedSearchType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Post Filters
                if viewModel.searchType != .businesses {
                    Section("게시글 필터") {
                        Picker("카테고리", selection: $viewModel.selectedPostCategory) {
                            Text("전체").tag(PostCategory?.none)
                            ForEach(PostCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(PostCategory?.some(category))
                            }
                        }

                        Picker("기간", selection: $viewModel.dateFilter) {
                            ForEach(DateFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                    }
                }

                // Business Filters
                if viewModel.searchType != .posts {
                    Section("업소 필터") {
                        Picker("카테고리", selection: $viewModel.selectedBusinessCategory) {
                            Text("전체").tag(BusinessCategory?.none)
                            ForEach(BusinessCategory.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(BusinessCategory?.some(category))
                            }
                        }

                        Picker("평점", selection: $viewModel.ratingFilter) {
                            ForEach(RatingFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                    }
                }

                // Sort
                Section("정렬") {
                    Picker("정렬 기준", selection: $viewModel.sortOption) {
                        Text("최신순").tag(SortOption.latest)
                        Text("인기순").tag(SortOption.popular)
                        if viewModel.searchType != .posts {
                            Text("평점순").tag(SortOption.rating)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Reset
                Section {
                    Button("필터 초기화", role: .destructive) {
                        viewModel.resetFilters()
                    }
                }
            }
            .navigationTitle("필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("적용") {
                        viewModel.performSearch()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("검색 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sort Option
enum SortOption: String {
    case latest = "최신순"
    case popular = "인기순"
    case rating = "평점순"
}

#Preview {
    AdvancedSearchView()
}
