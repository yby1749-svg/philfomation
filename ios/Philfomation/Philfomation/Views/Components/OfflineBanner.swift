//
//  OfflineBanner.swift
//  Philfomation
//

import SwiftUI

struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    @ObservedObject var syncManager = SyncManager.shared
    @ObservedObject var cacheManager = OfflineCacheManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Offline Banner
            if !networkMonitor.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.subheadline)

                    Text("오프라인 모드")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    if let lastUpdate = cacheManager.lastUpdateFormatted {
                        Text("\(lastUpdate) 업데이트")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    } else {
                        Text("캐시된 데이터 표시 중")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange)
                .foregroundStyle(.white)
            }

            // Sync Status Banner
            if syncManager.pendingActionsCount > 0 {
                SyncStatusBanner()
            }
        }
    }
}

// MARK: - Sync Status Banner
struct SyncStatusBanner: View {
    @ObservedObject var syncManager = SyncManager.shared
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    var body: some View {
        HStack(spacing: 8) {
            switch syncManager.syncStatus {
            case .idle:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Text("\(syncManager.pendingActionsCount)개 대기 중")
                    .font(.caption)

            case .syncing(let progress):
                ProgressView(value: progress)
                    .frame(width: 60)
                Text("동기화 중...")
                    .font(.caption)

            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text("동기화 완료")
                    .font(.caption)

            case .failed(let error):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                Text(error)
                    .font(.caption)
                    .lineLimit(1)
            }

            Spacer()

            if networkMonitor.isConnected && syncManager.syncStatus.isIdle && syncManager.pendingActionsCount > 0 {
                Button {
                    Task {
                        await syncManager.forceSync()
                    }
                } label: {
                    Text("지금 동기화")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .foregroundStyle(.secondary)
    }
}

// MARK: - Offline Indicator
struct OfflineIndicator: View {
    var isOffline: Bool

    var body: some View {
        if isOffline {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise.icloud")
                    .font(.caption2)
                Text("오프라인")
                    .font(.caption2)
            }
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Pending Actions Badge
struct PendingActionsBadge: View {
    @ObservedObject var syncManager = SyncManager.shared

    var body: some View {
        if syncManager.pendingActionsCount > 0 {
            Text("\(syncManager.pendingActionsCount)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Draft Badge
struct DraftBadge: View {
    @ObservedObject var syncManager = SyncManager.shared

    var body: some View {
        if syncManager.draftsCount > 0 {
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.caption2)
                Text("\(syncManager.draftsCount)")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Last Sync Time View
struct LastSyncTimeView: View {
    @ObservedObject var syncManager = SyncManager.shared

    var body: some View {
        if let date = syncManager.lastSyncDate {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption2)

                Text(formatDate(date))
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack {
        OfflineBanner()
        SyncStatusBanner()
        OfflineIndicator(isOffline: true)
        PendingActionsBadge()
        DraftBadge()
        LastSyncTimeView()
    }
}
