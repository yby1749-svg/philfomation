//
//  ReportView.swift
//  Philfomation
//

import SwiftUI

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    let targetType: ReportTargetType
    let targetId: String
    let targetAuthorId: String

    @State private var selectedReason: ReportReason?
    @State private var details = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var alreadyReported = false

    var body: some View {
        NavigationStack {
            Form {
                if alreadyReported {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("이미 신고한 콘텐츠입니다")
                        }
                    }
                } else {
                    // Reason Selection
                    Section {
                        ForEach(ReportReason.allCases) { reason in
                            Button {
                                selectedReason = reason
                            } label: {
                                HStack {
                                    Image(systemName: reason.icon)
                                        .foregroundStyle(Color(hex: "2563EB"))
                                        .frame(width: 24)

                                    Text(reason.rawValue)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if selectedReason == reason {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color(hex: "2563EB"))
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("신고 사유 선택")
                    }

                    // Details
                    Section {
                        TextEditor(text: $details)
                            .frame(minHeight: 100)
                    } header: {
                        Text("상세 내용 (선택)")
                    } footer: {
                        Text("신고 내용을 자세히 설명해주시면 검토에 도움이 됩니다")
                    }
                }
            }
            .navigationTitle("신고하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                if !alreadyReported {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("신고") {
                            Task {
                                await submitReport()
                            }
                        }
                        .disabled(selectedReason == nil || isSubmitting)
                    }
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("신고 접수 중...")
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .alert("신고 완료", isPresented: $showSuccessAlert) {
                Button("확인") {
                    dismiss()
                }
            } message: {
                Text("신고가 접수되었습니다.\n검토 후 적절한 조치가 이루어집니다.")
            }
            .alert("오류", isPresented: $showErrorAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await checkIfAlreadyReported()
            }
        }
    }

    private func checkIfAlreadyReported() async {
        guard let userId = authViewModel.currentUser?.id else { return }

        do {
            alreadyReported = try await ReportService.shared.hasUserReported(
                reporterId: userId,
                targetId: targetId
            )
        } catch {
            print("Error checking report status: \(error)")
        }
    }

    private func submitReport() async {
        guard let reason = selectedReason,
              let user = authViewModel.currentUser,
              let userId = user.id else {
            errorMessage = "로그인이 필요합니다"
            showErrorAlert = true
            return
        }

        isSubmitting = true

        do {
            switch targetType {
            case .post:
                try await ReportService.shared.reportPost(
                    postId: targetId,
                    postAuthorId: targetAuthorId,
                    reporterId: userId,
                    reporterName: user.name,
                    reason: reason,
                    details: details.isEmpty ? nil : details
                )
            case .comment:
                try await ReportService.shared.reportComment(
                    commentId: targetId,
                    commentAuthorId: targetAuthorId,
                    reporterId: userId,
                    reporterName: user.name,
                    reason: reason,
                    details: details.isEmpty ? nil : details
                )
            case .user:
                try await ReportService.shared.reportUser(
                    userId: targetId,
                    reporterId: userId,
                    reporterName: user.name,
                    reason: reason,
                    details: details.isEmpty ? nil : details
                )
            default:
                break
            }

            isSubmitting = false
            showSuccessAlert = true
        } catch {
            isSubmitting = false
            errorMessage = "신고 접수에 실패했습니다"
            showErrorAlert = true
        }
    }
}

#Preview {
    ReportView(
        targetType: .post,
        targetId: "sample",
        targetAuthorId: "author1"
    )
    .environmentObject(AuthViewModel())
}
