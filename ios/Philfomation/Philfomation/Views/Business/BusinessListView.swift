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

struct BusinessListView: View {
    @EnvironmentObject var viewModel: BusinessViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var exchangeRateViewModel = ExchangeRateViewModel()
    @State private var showCategoryFilter = false
    @State private var viewMode: BusinessViewMode = .list

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

                Divider()

                // Business Content (List or Map)
                if viewMode == .list {
                    // Business List
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.filteredBusinesses.isEmpty {
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
                                ForEach(viewModel.filteredBusinesses) { business in
                                    NavigationLink(destination: BusinessDetailView(business: business)) {
                                        BusinessCard(business: business)
                                    }
                                    .buttonStyle(.plain)
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
    var onSearch: () -> Void

    @FocusState private var isFocused: Bool
    @ObservedObject private var historyManager = SearchHistoryManager.shared

    var body: some View {
        VStack(spacing: 0) {
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
        Button(action: action) {
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
        }
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

#Preview {
    BusinessListView()
        .environmentObject(BusinessViewModel())
}
