//
//  ReviewFormView.swift
//  Philfomation
//

import SwiftUI
import PhotosUI
import FirebaseAuth

struct ReviewFormView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: BusinessViewModel
    @Environment(\.dismiss) private var dismiss

    let business: Business

    @State private var rating = 5
    @State private var comment = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                // Business Info
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(business.name)
                                .font(.headline)
                            Text(business.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                // Rating
                Section("평점") {
                    HStack {
                        Spacer()
                        ForEach(1...5, id: \.self) { index in
                            Button {
                                rating = index
                            } label: {
                                Image(systemName: index <= rating ? "star.fill" : "star")
                                    .font(.title)
                                    .foregroundStyle(Color(hex: "F59E0B"))
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Comment
                Section("리뷰 내용") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if comment.isEmpty {
                                Text("업소에 대한 솔직한 리뷰를 작성해주세요")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                // Photos
                Section("사진 첨부 (선택)") {
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        Button {
                                            selectedImages.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white, .red)
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                }
                            }
                        }
                    }

                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Label("사진 선택", systemImage: "photo.on.rectangle.angled")
                    }
                    .onChange(of: selectedPhotos) { newItems in
                        Task {
                            selectedImages = []
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    selectedImages.append(image)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("리뷰 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("등록") {
                        submitReview()
                    }
                    .disabled(comment.isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("등록 중...")
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                }
            }
        }
    }

    private func submitReview() {
        guard let businessId = business.id,
              let userId = authViewModel.firebaseUser?.uid,
              let userName = authViewModel.currentUser?.name ?? authViewModel.firebaseUser?.displayName else {
            return
        }

        isSubmitting = true

        Task {
            // Upload images first
            var photoURLs: [String] = []
            if !selectedImages.isEmpty {
                do {
                    let reviewId = UUID().uuidString
                    photoURLs = try await StorageService.shared.uploadReviewImages(
                        selectedImages,
                        reviewId: reviewId
                    )
                } catch {
                    print("Failed to upload images: \(error)")
                }
            }

            let review = Review(
                businessId: businessId,
                userId: userId,
                userName: userName,
                userPhotoURL: authViewModel.currentUser?.photoURL,
                rating: rating,
                comment: comment,
                photos: photoURLs
            )

            let success = await viewModel.addReview(review)

            await MainActor.run {
                isSubmitting = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ReviewFormView(business: Business(
        id: "test",
        name: "테스트 업소",
        category: .restaurant,
        address: "마닐라"
    ))
    .environmentObject(AuthViewModel())
    .environmentObject(BusinessViewModel())
}
