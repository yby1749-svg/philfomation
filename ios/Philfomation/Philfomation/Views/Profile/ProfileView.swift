//
//  ProfileView.swift
//  Philfomation
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var viewModel: ProfileViewModel
    @State private var showEditProfile = false
    @State private var showMyReviews = false
    @State private var showBookmarks = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Header
                Section {
                    HStack(spacing: 16) {
                        AsyncProfileImage(url: viewModel.user?.photoURL, size: 70)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.user?.name ?? "이름 없음")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(viewModel.user?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let userType = viewModel.user?.userType {
                                Text(userType.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "2563EB").opacity(0.1))
                                    .foregroundStyle(Color(hex: "2563EB"))
                                    .clipShape(Capsule())
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Menu Items
                Section {
                    Button {
                        showEditProfile = true
                    } label: {
                        ProfileMenuItem(icon: "person.fill", title: "프로필 수정", color: .blue)
                    }

                    Button {
                        showMyReviews = true
                    } label: {
                        ProfileMenuItem(icon: "star.fill", title: "내가 쓴 리뷰", color: .orange)
                    }

                    NavigationLink {
                        BookmarksView()
                    } label: {
                        ProfileMenuItem(icon: "bookmark.fill", title: "저장한 글", color: Color(hex: "2563EB"))
                    }
                }

                Section {
                    Button {
                        showSettings = true
                    } label: {
                        ProfileMenuItem(icon: "gearshape.fill", title: "설정", color: .gray)
                    }
                }

                // Logout
                Section {
                    Button {
                        authViewModel.signOut()
                    } label: {
                        HStack {
                            Spacer()
                            Text("로그아웃")
                                .foregroundStyle(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("프로필")
            .refreshable {
                await viewModel.fetchUser()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showMyReviews) {
                MyReviewsView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var userType: UserType = .customer
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationStack {
            Form {
                // Photo Section
                Section {
                    HStack {
                        Spacer()

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                AsyncProfileImage(url: viewModel.user?.photoURL, size: 100)
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color(hex: "2563EB"))
                                .background(Circle().fill(.white))
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // Info Section
                Section("기본 정보") {
                    TextField("이름", text: $name)

                    TextField("전화번호", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("사용자 유형") {
                    Picker("유형", selection: $userType) {
                        ForEach(UserType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Error/Success Messages
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                if let success = viewModel.successMessage {
                    Section {
                        Text(success)
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty || viewModel.isLoading)
                }
            }
            .onAppear {
                name = viewModel.user?.name ?? ""
                phoneNumber = viewModel.user?.phoneNumber ?? ""
                userType = viewModel.user?.userType ?? .customer
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("저장 중...")
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                }
            }
        }
    }

    private func saveProfile() {
        Task {
            // Upload photo if changed
            if let image = selectedImage {
                let _ = await viewModel.updateProfilePhoto(image)
            }

            // Update profile info
            let success = await viewModel.updateProfile(
                name: name,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                userType: userType
            )

            if success {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}

struct MyReviewsView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var reviewToDelete: Review?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.myReviews.isEmpty {
                    EmptyStateView(
                        icon: "star",
                        title: "작성한 리뷰가 없습니다",
                        message: "업소를 방문하고 리뷰를 남겨보세요"
                    )
                } else {
                    List {
                        ForEach(viewModel.myReviews) { review in
                            ReviewCard(review: review, showDeleteButton: true) {
                                reviewToDelete = review
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("내가 쓴 리뷰")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                await viewModel.fetchMyReviews()
            }
            .alert("리뷰 삭제", isPresented: .init(
                get: { reviewToDelete != nil },
                set: { if !$0 { reviewToDelete = nil } }
            )) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    if let review = reviewToDelete, let id = review.id {
                        Task {
                            let _ = await viewModel.deleteMyReview(id: id)
                        }
                    }
                }
            } message: {
                Text("이 리뷰를 삭제하시겠습니까?")
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(ProfileViewModel())
}
