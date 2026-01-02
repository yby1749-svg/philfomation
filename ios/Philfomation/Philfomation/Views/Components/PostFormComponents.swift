//
//  PostFormComponents.swift
//  Philfomation
//

import SwiftUI

// MARK: - Category Picker Section
struct PostCategoryPickerSection: View {
    @Binding var selectedCategory: PostCategory

    var body: some View {
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
    }
}

// MARK: - Title Section
struct PostTitleSection: View {
    @Binding var title: String
    let maxLength: Int

    init(title: Binding<String>, maxLength: Int = 100) {
        self._title = title
        self.maxLength = maxLength
    }

    var body: some View {
        Section {
            TextField("제목을 입력하세요", text: $title)
                .textInputAutocapitalization(.never)
        } header: {
            Text("제목")
        } footer: {
            if title.count > maxLength {
                Text("제목은 \(maxLength)자 이내로 작성해주세요")
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Content Section
struct PostContentSection: View {
    @Binding var content: String
    let maxLength: Int
    let minHeight: CGFloat

    init(content: Binding<String>, maxLength: Int = 5000, minHeight: CGFloat = 200) {
        self._content = content
        self.maxLength = maxLength
        self.minHeight = minHeight
    }

    var body: some View {
        Section {
            TextEditor(text: $content)
                .frame(minHeight: minHeight)
        } header: {
            Text("내용")
        } footer: {
            HStack {
                Spacer()
                Text("\(content.count)자")
                    .foregroundStyle(content.count > maxLength ? .red : .secondary)
            }
        }
    }
}

// MARK: - Image Picker Section
struct PostImagePickerSection: View {
    @Binding var selectedImages: [UIImage]
    @Binding var showImagePicker: Bool
    let maxImages: Int

    init(selectedImages: Binding<[UIImage]>, showImagePicker: Binding<Bool>, maxImages: Int = 5) {
        self._selectedImages = selectedImages
        self._showImagePicker = showImagePicker
        self.maxImages = maxImages
    }

    var body: some View {
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
                    Text(selectedImages.isEmpty ? "사진 추가" : "사진 추가 (\(selectedImages.count)/\(maxImages))")
                }
            }
            .disabled(selectedImages.count >= maxImages)
        } header: {
            Text("사진 (선택)")
        } footer: {
            Text("최대 \(maxImages)장까지 첨부 가능합니다")
        }
    }
}

// MARK: - Submitting Overlay
struct SubmittingOverlay: View {
    let isSubmitting: Bool
    let message: String

    var body: some View {
        Group {
            if isSubmitting {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView(message)
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

// MARK: - Post Validation
struct PostValidation {
    let title: String
    let content: String
    let maxTitleLength: Int
    let maxContentLength: Int

    init(title: String, content: String, maxTitleLength: Int = 100, maxContentLength: Int = 5000) {
        self.title = title
        self.content = content
        self.maxTitleLength = maxTitleLength
        self.maxContentLength = maxContentLength
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        title.count <= maxTitleLength &&
        content.count <= maxContentLength
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview("Category Picker") {
    Form {
        PostCategoryPickerSection(selectedCategory: .constant(.free))
    }
}

#Preview("Title Section") {
    Form {
        PostTitleSection(title: .constant("테스트 제목"))
    }
}

#Preview("Content Section") {
    Form {
        PostContentSection(content: .constant("테스트 내용입니다."))
    }
}
