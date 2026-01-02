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

    var body: some View {
        NavigationStack {
            Form {
                // Category Selection
                Section {
                    Picker("카테고리", selection: $selectedCategory) {
                        ForEach(PostCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(Color(hex: category.color))
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("카테고리 선택")
                }

                // Title
                Section {
                    TextField("제목을 입력하세요", text: $title)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("제목")
                } footer: {
                    if title.count > 100 {
                        Text("제목은 100자 이내로 작성해주세요")
                            .foregroundStyle(.red)
                    }
                }

                // Content
                Section {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                } header: {
                    Text("내용")
                } footer: {
                    HStack {
                        Spacer()
                        Text("\(content.count)자")
                            .foregroundStyle(content.count > 5000 ? .red : .secondary)
                    }
                }

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
                    .disabled(!isValidPost || isSubmitting || !hasChanges)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("저장 중...")
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .alert("알림", isPresented: $showAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var isValidPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        title.count <= 100 &&
        content.count <= 5000
    }

    private var hasChanges: Bool {
        title != post.title ||
        content != post.content ||
        selectedCategory != post.category
    }

    private func updatePost() async {
        isSubmitting = true

        let success = await viewModel.updatePost(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
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
