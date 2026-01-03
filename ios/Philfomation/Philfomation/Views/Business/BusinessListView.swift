//
//  BusinessListView.swift
//  Philfomation
//

import SwiftUI

enum BusinessViewMode: String, CaseIterable {
    case list = "list"
    case map = "map"

    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .map: return "map"
        }
    }
}

enum BusinessSortOption: String, CaseIterable {
    case recent = "최신순"
    case rating = "평점순"
    case nearby = "거리순"

    var icon: String {
        switch self {
        case .recent: return "clock"
        case .rating: return "star.fill"
        case .nearby: return "location.fill"
        }
    }
}

struct BusinessListView: View {
    @EnvironmentObject var viewModel: BusinessViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var exchangeRateViewModel = ExchangeRateViewModel()
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var showCategoryFilter = false
    @State private var viewMode: BusinessViewMode = .list
    @State private var sortOption: BusinessSortOption = .recent

    private var sortedBusinesses: [Business] {
        switch sortOption {
        case .recent:
            return viewModel.filteredBusinesses
        case .rating:
            return viewModel.filteredBusinesses.sorted { $0.rating > $1.rating }
        case .nearby:
            return locationManager.sortByDistance(viewModel.filteredBusinesses)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Logo Header
                LogoHeader()

                // Quick Info Cards
                QuickInfoSection(exchangeRateViewModel: exchangeRateViewModel)

                // Search Bar
                SearchBar(text: $viewModel.searchQuery) {
                    Task {
                        await viewModel.searchBusinesses()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Category Filter with View Mode Toggle
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(
                                title: "전체",
                                isSelected: viewModel.selectedCategory == nil
                            ) {
                                viewModel.setCategory(nil)
                            }

                            ForEach(BusinessCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    viewModel.setCategory(category)
                                }
                            }
                        }
                        .padding(.leading)
                        .padding(.vertical, 12)
                    }

                    // View Mode Toggle
                    ViewModeToggle(viewMode: $viewMode)
                        .padding(.trailing)
                }

                // Sort Options Bar
                SortOptionsBar(selectedOption: $sortOption)

                Divider()

                // Business Content (List or Map)
                if viewMode == .list {
                    // Business List
                    if viewModel.isLoading {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(0..<5, id: \.self) { index in
                                    BusinessCardSkeleton()
                                        .staggeredAnimation(index: index)
                                }
                            }
                            .padding()
                        }
                    } else if sortedBusinesses.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "building.2",
                            title: "등록된 업소가 없습니다",
                            message: "조건에 맞는 업소를 찾을 수 없습니다"
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(sortedBusinesses) { business in
                                    NavigationLink(destination: BusinessDetailView(business: business)) {
                                        BusinessCard(business: business)
                                    }
                                    .buttonStyle(.plain)
                                    .onAppear {
                                        // Load more when approaching the end
                                        if business.id == sortedBusinesses.last?.id {
                                            Task {
                                                await viewModel.loadMoreBusinesses()
                                            }
                                        }
                                    }
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
                            .padding()
                        }
                    }
                } else {
                    // Business Map
                    BusinessMapView()
                }
            }
            .navigationBarHidden(true)
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.loadBlockedUsers(userId: userId)
                }
            }
            .refreshable {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.refreshBlockedUsers(userId: userId)
                }
                await viewModel.fetchBusinesses()
            }
        }
    }
}

// MARK: - View Mode Toggle
struct ViewModeToggle: View {
    @Binding var viewMode: BusinessViewMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BusinessViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = mode
                    }
                } label: {
                    Image(systemName: mode.icon)
                        .font(.subheadline)
                        .foregroundStyle(viewMode == mode ? .white : .primary)
                        .frame(width: 36, height: 32)
                        .background(viewMode == mode ? Color(hex: "2563EB") : Color.clear)
                }
            }
        }
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "업소명, 주소 검색"
    var searchType: SearchType = .business
    var showAdvancedSearch: Bool = true
    var onSearch: () -> Void

    @FocusState private var isFocused: Bool
    @ObservedObject private var historyManager = SearchHistoryManager.shared
    @State private var showAdvancedSearchView = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .submitLabel(.search)
                        .focused($isFocused)
                        .onSubmit {
                            if !text.isEmpty {
                                historyManager.addSearch(text, type: searchType)
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
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Advanced Search Button
                if showAdvancedSearch {
                    Button {
                        showAdvancedSearchView = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundStyle(Color(hex: "2563EB"))
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "2563EB").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .sheet(isPresented: $showAdvancedSearchView) {
                AdvancedSearchView()
            }

            // Search History
            if isFocused && text.isEmpty {
                SearchHistoryView(searchType: searchType) { query in
                    text = query
                    historyManager.addSearch(query, type: searchType)
                    onSearch()
                    isFocused = false
                }
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.selectionChanged()
            action()
        } label: {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "2563EB") : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .animation(.quickSpring, value: isSelected)
        }
        .buttonStyle(.scale)
    }
}

// MARK: - Quick Info Section
struct QuickInfoSection: View {
    @ObservedObject var exchangeRateViewModel: ExchangeRateViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                NavigationLink(destination: ExchangeRateView()) {
                    QuickInfoCard(
                        icon: "wonsign.circle.fill",
                        title: "환율 계산기",
                        subtitle: "PHP ↔ KRW 변환",
                        color: Color(hex: "2563EB")
                    )
                }

                NavigationLink(destination: TravelInfoView()) {
                    QuickInfoCard(
                        icon: "book.fill",
                        title: "여행 지침서",
                        subtitle: "필리핀 여행 가이드",
                        color: .blue
                    )
                }

                NavigationLink(destination: FlightScheduleView()) {
                    QuickInfoCard(
                        icon: "airplane",
                        title: "항공 스케줄",
                        subtitle: "한국 ↔ 필리핀",
                        color: .purple
                    )
                }

                NavigationLink(destination: LivingInfoView()) {
                    QuickInfoCard(
                        icon: "house.fill",
                        title: "생활 정보",
                        subtitle: "은행, 통신, 교통",
                        color: .green
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct QuickInfoCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Logo Header
struct LogoHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 0) {
                Text("Philfomation")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("Philippine Community Hub")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "2563EB"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

// MARK: - Sort Options Bar
struct SortOptionsBar: View {
    @Binding var selectedOption: BusinessSortOption
    @ObservedObject private var locationManager = LocationManager.shared

    var body: some View {
        HStack(spacing: 0) {
            // Location status
            if locationManager.authorizationStatus.isAuthorized {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    if locationManager.currentLocation != nil {
                        Text("위치 활성화")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else {
                        Text("위치 확인 중...")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.leading, 16)
            } else {
                Button {
                    locationManager.requestAuthorization()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "location.slash")
                            .font(.caption2)
                        Text("위치 활성화")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color(hex: "2563EB"))
                }
                .padding(.leading, 16)
            }

            Spacer()

            // Sort options
            HStack(spacing: 4) {
                ForEach(BusinessSortOption.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            // If selecting nearby and location not authorized, request it
                            if option == .nearby && !locationManager.authorizationStatus.isAuthorized {
                                locationManager.requestAuthorization()
                            }
                            selectedOption = option
                            HapticManager.shared.selectionChanged()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: option.icon)
                                .font(.caption2)
                            Text(option.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedOption == option ? Color(hex: "2563EB") : Color(.systemGray6))
                        .foregroundStyle(selectedOption == option ? .white : .primary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    BusinessListView()
        .environmentObject(BusinessViewModel())
}
