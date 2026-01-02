//
//  EditPostView.swift
//  Philfomation
//

import SwiftUI

struct EditPostView: View {
    @ObservedObject var viewModel: PostDetailViewModel
    @Environment(\.dismiss) private var dismiss

    let post: Post

    @State private var title: String
    @State private var content: String
    @State private var selectedCategory: PostCategory
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    init(post: Post, viewModel: PostDetailViewModel) {
        self.post = post
        self.viewModel = viewModel
        _title = State(initialValue: post.title)
        _content = State(initialValue: post.content)
        _selectedCategory = State(initialValue: post.category)
    }

    private var validation: PostValidation {
        PostValidation(title: title, content: content)
    }

    private var hasChanges: Bool {
        title != post.title ||
        content != post.content ||
        selectedCategory != post.category
    }

    var body: some View {
        NavigationStack {
            Form {
                PostCategoryPickerSection(selectedCategory: $selectedCategory)
                PostTitleSection(title: $title)
                PostContentSection(content: $content)

                // Existing Images (read-only display)
                if let imageURLs = post.imageURLs, !imageURLs.isEmpty {
                    Section {
                        URLImageGridView(imageURLs: imageURLs)
                    } header: {
                        Text("첨부된 사진")
                    } footer: {
                        Text("기존 사진은 수정할 수 없습니다")
                    }
                }
            }
            .navigationTitle("게시글 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Task {
                            await updatePost()
                        }
                    }
                    .disabled(!validation.isValid || isSubmitting || !hasChanges)
                }
            }
            .overlay {
                SubmittingOverlay(isSubmitting: isSubmitting, message: "저장 중...")
            }
            .alert("알림", isPresented: $showAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func updatePost() async {
        isSubmitting = true

        let success = await viewModel.updatePost(
            title: validation.trimmedTitle,
            content: validation.trimmedContent,
            category: selectedCategory
        )

        isSubmitting = false

        if success {
            dismiss()
        } else {
            alertMessage = viewModel.errorMessage ?? "게시글 수정에 실패했습니다"
            showAlert = true
        }
    }
}

#Preview {
    EditPostView(
        post: Post.sample,
        viewModel: PostDetailViewModel(postId: "sample")
    )
}
