//
//  SettingsView.swift
//  Philfomation
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @State private var isSeedingData = false
    @State private var showSeedAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("알림") {
                    Toggle("푸시 알림", isOn: .constant(true))
                    Toggle("채팅 알림", isOn: .constant(true))
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
        }
    }
}

#Preview {
    SettingsView()
}
