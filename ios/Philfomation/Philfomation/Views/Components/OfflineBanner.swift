//
//  OfflineBanner.swift
//  Philfomation
//

import SwiftUI

struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.subheadline)

                Text("오프라인 모드")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("캐시된 데이터 표시 중")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.orange)
            .foregroundStyle(.white)
        }
    }
}

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

#Preview {
    VStack {
        OfflineBanner()
        OfflineIndicator(isOffline: true)
    }
}
