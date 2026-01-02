//
//  BlockedUsersView.swift
//  Philfomation
//

import SwiftUI

struct BlockedUsersView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var blockedUsers: [Block] = []
    @State private var isLoading = false
    @State private var userToUnblock: Block?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if blockedUsers.isEmpty {
                EmptyBlockedUsersView()
            } else {
                List {
                    ForEach(blockedUsers) { block in
                        BlockedUserRow(block: block)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    userToUnblock = block
                                } label: {
                                    Label("차단 해제", systemImage: "person.badge.plus")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("차단된 사용자")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchBlockedUsers()
        }
        .refreshable {
            await fetchBlockedUsers()
        }
        .alert("차단 해제", isPresented: .init(
            get: { userToUnblock != nil },
            set: { if !$0 { userToUnblock = nil } }
        )) {
            Button("취소", role: .cancel) {}
            Button("해제") {
                if let block = userToUnblock {
                    Task {
                        await unblockUser(block)
                    }
                }
            }
        } message: {
            Text("\(userToUnblock?.blockedName ?? "")님의 차단을 해제하시겠습니까?")
        }
    }

    private func fetchBlockedUsers() async {
        guard let userId = authViewModel.currentUser?.id else { return }

        isLoading = true
        do {
            blockedUsers = try await BlockService.shared.fetchBlockedUsers(userId: userId)
        } catch {
            print("Error fetching blocked users: \(error)")
        }
        isLoading = false
    }

    private func unblockUser(_ block: Block) async {
        guard let userId = authViewModel.currentUser?.id else { return }

        do {
            try await BlockService.shared.unblockUser(
                blockerId: userId,
                blockedId: block.blockedId
            )
            blockedUsers.removeAll { $0.id == block.id }
        } catch {
            print("Error unblocking user: \(error)")
        }
    }
}

// MARK: - Blocked User Row
struct BlockedUserRow: View {
    let block: Block

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            AsyncProfileImage(url: block.blockedPhotoURL, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.blockedName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(block.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                + Text(" 전 차단됨")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Blocked Users View
struct EmptyBlockedUsersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("차단된 사용자가 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("게시글 메뉴에서 사용자를 차단할 수 있습니다")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        BlockedUsersView()
            .environmentObject(AuthViewModel())
    }
}
