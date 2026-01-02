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

    private var validation: PostValidation {
        PostValidation(title: title, content: content)
    }

    var body: some View {
        NavigationStack {
            Form {
                PostCategoryPickerSection(selectedCategory: $selectedCategory)
                PostTitleSection(title: $title)
                PostContentSection(content: $content)
                PostImagePickerSection(
                    selectedImages: $selectedImages,
                    showImagePicker: $showImagePicker
                )
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
                    .disabled(!validation.isValid || isSubmitting)
                }
            }
            .overlay {
                SubmittingOverlay(isSubmitting: isSubmitting, message: "등록 중...")
            }
            .alert("알림", isPresented: $showAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func submitPost() async {
        guard let user = authViewModel.currentUser else {
            alertMessage = "로그인이 필요합니다"
            showAlert = true
            return
        }

        isSubmitting = true

        let success = await viewModel.createPost(
            title: validation.trimmedTitle,
            content: validation.trimmedContent,
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
