//
//  SettingsView.swift
//  Philfomation
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isSeedingData = false
    @State private var showSeedAlert = false
    @State private var isSendingTestNotification = false
    @State private var showNotificationAlert = false
    @State private var notificationAlertMessage = ""
    @State private var notificationPermissionStatus = ""
    @State private var fcmToken = ""

    var body: some View {
        NavigationStack {
            List {
                Section("알림") {
                    HStack {
                        Text("알림 권한")
                        Spacer()
                        Text(notificationPermissionStatus)
                            .foregroundStyle(.secondary)
                    }

                    if notificationPermissionStatus == "거부됨" {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("설정에서 알림 허용하기")
                                .foregroundStyle(Color(hex: "2563EB"))
                        }
                    }
                }

                Section("화면") {
                    Picker(selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Label(theme.displayName, systemImage: theme.icon)
                                .tag(theme)
                        }
                    } label: {
                        Label("테마", systemImage: "circle.lefthalf.filled")
                    }
                    .onChange(of: themeManager.currentTheme) { newTheme in
                        themeManager.setTheme(newTheme)
                    }

                    // Accent Color Picker
                    NavigationLink {
                        AccentColorPickerView(themeManager: themeManager)
                    } label: {
                        HStack {
                            Label("강조 색상", systemImage: "paintpalette.fill")
                            Spacer()
                            Circle()
                                .fill(themeManager.currentAccentColor)
                                .frame(width: 24, height: 24)
                        }
                    }

                    // Font Size Picker
                    NavigationLink {
                        FontSizePickerView(themeManager: themeManager)
                    } label: {
                        HStack {
                            Label("글자 크기", systemImage: "textformat.size")
                            Spacer()
                            Text(themeManager.fontSize.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("앱 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://philfomation.com/terms")!) {
                        HStack {
                            Text("이용약관")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Link(destination: URL(string: "https://philfomation.com/privacy")!) {
                        HStack {
                            Text("개인정보처리방침")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Section("지원") {
                    Link(destination: URL(string: "mailto:support@philfomation.com")!) {
                        HStack {
                            Text("문의하기")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Section("계정") {
                    NavigationLink {
                        BlockedUsersView()
                    } label: {
                        HStack {
                            Text("차단된 사용자")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Section("저장공간") {
                    HStack {
                        Text("오프라인 캐시")
                        Spacer()
                        Text(OfflineCacheManager.shared.formattedCacheSize)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        // Clear all caches
                        Task {
                            await ImageCache.shared.clearCache()
                            OfflineCacheManager.shared.clearAll()
                        }
                    } label: {
                        Text("캐시 삭제")
                            .foregroundStyle(.primary)
                    }

                    Button {
                        SearchHistoryManager.shared.clearAllHistory()
                    } label: {
                        Text("검색 기록 삭제")
                            .foregroundStyle(.primary)
                    }
                }

                #if DEBUG
                Section("개발자 옵션") {
                    Button {
                        isSeedingData = true
                        Task {
                            await SampleDataService.shared.seedAllData()
                            isSeedingData = false
                            showSeedAlert = true
                        }
                    } label: {
                        HStack {
                            Text("샘플 데이터 생성")
                                .foregroundStyle(.primary)
                            Spacer()
                            if isSeedingData {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isSeedingData)

                    Button {
                        sendTestNotification()
                    } label: {
                        HStack {
                            Text("푸시 알림 테스트")
                                .foregroundStyle(.primary)
                            Spacer()
                            if isSendingTestNotification {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isSendingTestNotification)

                    if !fcmToken.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FCM Token")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(fcmToken)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(2)
                        }

                        Button {
                            UIPasteboard.general.string = fcmToken
                            notificationAlertMessage = "FCM 토큰이 클립보드에 복사되었습니다"
                            showNotificationAlert = true
                        } label: {
                            Text("FCM 토큰 복사")
                                .foregroundStyle(.primary)
                        }
                    }
                }
                #endif

                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "network")
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex: "2563EB"))

                        Text("Philfomation")
                            .font(.headline)

                        Text("Philippine Community Hub")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("샘플 데이터 생성 완료", isPresented: $showSeedAlert) {
                Button("확인") {}
            } message: {
                Text("샘플 사용자 3명, 게시글 3개, 댓글 3개, 업소 3개가 생성되었습니다.")
            }
            .alert("알림", isPresented: $showNotificationAlert) {
                Button("확인") {}
            } message: {
                Text(notificationAlertMessage)
            }
            .task {
                await loadNotificationStatus()
            }
        }
    }

    // MARK: - Helper Methods

    private func loadNotificationStatus() async {
        let status = await PushNotificationService.shared.checkPermissionStatus()

        await MainActor.run {
            switch status {
            case .authorized:
                notificationPermissionStatus = "허용됨"
            case .denied:
                notificationPermissionStatus = "거부됨"
            case .notDetermined:
                notificationPermissionStatus = "미설정"
            case .provisional:
                notificationPermissionStatus = "임시 허용"
            case .ephemeral:
                notificationPermissionStatus = "임시"
            @unknown default:
                notificationPermissionStatus = "알 수 없음"
            }
        }

        // FCM 토큰 가져오기
        if let token = await PushNotificationService.shared.getCurrentToken() {
            await MainActor.run {
                fcmToken = token
            }
        }
    }

    private func sendTestNotification() {
        guard let userId = authViewModel.currentUser?.id else {
            notificationAlertMessage = "로그인이 필요합니다"
            showNotificationAlert = true
            return
        }

        isSendingTestNotification = true

        Task {
            let result = await PushNotificationService.shared.sendTestNotification(userId: userId)

            await MainActor.run {
                isSendingTestNotification = false

                switch result {
                case .success(let message):
                    notificationAlertMessage = "테스트 알림이 전송되었습니다!\n\(message)"
                case .failure(let error):
                    notificationAlertMessage = "알림 전송 실패: \(error.localizedDescription)"
                }

                showNotificationAlert = true
            }
        }
    }
}

// MARK: - Accent Color Picker View
struct AccentColorPickerView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(AccentColorOption.allCases) { color in
                    Button {
                        themeManager.setAccentColor(color)
                    } label: {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 32, height: 32)

                            Text(color.rawValue)
                                .foregroundStyle(.primary)

                            Spacer()

                            if themeManager.accentColor == color {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(color.color)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } header: {
                Text("앱 전체에 적용되는 강조 색상을 선택하세요")
            } footer: {
                Text("버튼, 링크, 아이콘 등에 적용됩니다")
            }

            Section("미리보기") {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Button("버튼") {}
                            .buttonStyle(.borderedProminent)
                            .tint(themeManager.currentAccentColor)

                        Button("보조 버튼") {}
                            .buttonStyle(.bordered)
                            .tint(themeManager.currentAccentColor)
                    }

                    HStack(spacing: 16) {
                        Label("좋아요", systemImage: "heart.fill")
                            .foregroundStyle(themeManager.currentAccentColor)

                        Label("북마크", systemImage: "bookmark.fill")
                            .foregroundStyle(themeManager.currentAccentColor)

                        Label("공유", systemImage: "square.and.arrow.up")
                            .foregroundStyle(themeManager.currentAccentColor)
                    }
                    .font(.callout)

                    Toggle("토글 예시", isOn: .constant(true))
                        .tint(themeManager.currentAccentColor)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("강조 색상")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeManager.currentAccentColor)
    }
}

// MARK: - Font Size Picker View
struct FontSizePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(FontSizeOption.allCases) { size in
                    Button {
                        themeManager.setFontSize(size)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(size.rawValue)
                                    .font(.system(size: size.bodySize))
                                    .foregroundStyle(.primary)

                                Text("예시 텍스트입니다")
                                    .font(.system(size: size.bodySize * 0.8))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if themeManager.fontSize == size {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(themeManager.currentAccentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } header: {
                Text("글자 크기를 선택하세요")
            } footer: {
                Text("일부 텍스트에 적용됩니다. 시스템 설정의 글자 크기도 함께 적용됩니다.")
            }

            Section("미리보기") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("제목 텍스트")
                        .font(.system(size: themeManager.fontSize.bodySize * 1.3, weight: .bold))

                    Text("본문 텍스트입니다. 이 텍스트는 선택한 글자 크기에 따라 변경됩니다.")
                        .font(.system(size: themeManager.fontSize.bodySize))

                    Text("보조 텍스트")
                        .font(.system(size: themeManager.fontSize.bodySize * 0.8))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("글자 크기")
        .navigationBarTitleDisplayMode(.inline)
        .tint(themeManager.currentAccentColor)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
