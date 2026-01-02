//
//  CreatePostView.swift
//  Philfomation
//

import SwiftUI

struct CreatePostView: View {
    @ObservedObject var viewModel: CommunityViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: PostCategory = .free
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""

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

                // Images
                Section {
                    if !selectedImages.isEmpty {
                        ImageGridView(images: selectedImages) { index in
                            selectedImages.remove(at: index)
                        }
                    }

                    Button {
                        showImagePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text(selectedImages.isEmpty ? "사진 추가" : "사진 추가 (\(selectedImages.count)/5)")
                        }
                    }
                    .disabled(selectedImages.count >= 5)
                } header: {
                    Text("사진 (선택)")
                } footer: {
                    Text("최대 5장까지 첨부 가능합니다")
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $selectedImages, selectionLimit: 5 - selectedImages.count)
            }
            .navigationTitle("글쓰기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("등록") {
                        Task {
                            await submitPost()
                        }
                    }
                    .disabled(!isValidPost || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("등록 중...")
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

    private func submitPost() async {
        guard let user = authViewModel.currentUser else {
            alertMessage = "로그인이 필요합니다"
            showAlert = true
            return
        }

        isSubmitting = true

        let success = await viewModel.createPost(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            authorId: user.id ?? "",
            authorName: user.name,
            images: selectedImages
        )

        isSubmitting = false

        if success {
            dismiss()
        } else {
            alertMessage = viewModel.errorMessage ?? "게시글 등록에 실패했습니다"
            showAlert = true
        }
    }
}

#Preview {
    CreatePostView(viewModel: CommunityViewModel())
        .environmentObject(AuthViewModel())
}
