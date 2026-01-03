//
//  HomeView.swift
//  Philfomation
//

import SwiftUI

enum Tab: String, CaseIterable {
    case business = "업소"
    case community = "커뮤니티"
    case chat = "채팅"
    case profile = "프로필"

    var icon: String {
        switch self {
        case .business: return "building.2.fill"
        case .community: return "bubble.left.and.text.bubble.right.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @StateObject private var businessViewModel = BusinessViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    @State private var selectedTab: Tab = .business
    @State private var navigationPath = NavigationPath()
    @State private var communityNavigationPath = NavigationPath()

    var body: some View {
        VStack(spacing: 0) {
            OfflineBanner()

            TabView(selection: $selectedTab) {
            NavigationStack(path: $navigationPath) {
                BusinessListView()
                    .environmentObject(businessViewModel)
                    .navigationDestination(for: String.self) { businessId in
                        if let business = businessViewModel.businesses.first(where: { $0.id == businessId }) {
                            BusinessDetailView(business: business)
                        }
                    }
            }
            .tabItem {
                Label(Tab.business.rawValue, systemImage: Tab.business.icon)
            }
            .tag(Tab.business)

            NavigationStack(path: $communityNavigationPath) {
                CommunityView()
                    .navigationDestination(for: String.self) { postId in
                        PostDetailView(postId: postId)
                    }
            }
            .tabItem {
                Label(Tab.community.rawValue, systemImage: Tab.community.icon)
            }
            .tag(Tab.community)

            ChatTabView()
                .environmentObject(chatViewModel)
                .tabItem {
                    Label(Tab.chat.rawValue, systemImage: Tab.chat.icon)
                }
                .tag(Tab.chat)

            ProfileView()
                .environmentObject(profileViewModel)
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
            }
            .tint(Color(hex: "2563EB"))
            .onChange(of: deepLinkManager.pendingDestination) { destination in
                handleDeepLink(destination)
            }
            .onAppear {
                // Handle any pending deep link when view appears
                if let destination = deepLinkManager.pendingDestination {
                    handleDeepLink(destination)
                }
            }
        }
    }

    private func handleDeepLink(_ destination: DeepLinkDestination?) {
        guard let destination = destination else { return }

        switch destination {
        case .post(let id):
            selectedTab = .community
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                communityNavigationPath.append(id)
                deepLinkManager.clearDestination()
            }
        case .business(let id):
            selectedTab = .business
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                navigationPath.append(id)
                deepLinkManager.clearDestination()
            }
        case .community:
            selectedTab = .community
            deepLinkManager.clearDestination()
        case .businesses:
            selectedTab = .business
            deepLinkManager.clearDestination()
        case .chat:
            selectedTab = .chat
            deepLinkManager.clearDestination()
        case .profile:
            selectedTab = .profile
            deepLinkManager.clearDestination()
        case .notifications:
            selectedTab = .profile
            // TODO: Navigate to notifications view within profile
            deepLinkManager.clearDestination()
        }
    }
}

struct ChatTabView: View {
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("", selection: $selectedSegment) {
                    Text("1:1 채팅").tag(0)
                    Text("단톡방").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                if selectedSegment == 0 {
                    ChatListView()
                } else {
                    ChatRoomListView()
                }
            }
            .navigationTitle("채팅")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
