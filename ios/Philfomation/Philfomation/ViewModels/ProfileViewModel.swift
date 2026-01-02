//
//  ProfileViewModel.swift
//  Philfomation
//

import Foundation
import Combine
import UIKit

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var myReviews: [Review] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private var currentUserId: String? { AuthService.shared.currentUserId }

    init() {
        Task {
            await fetchUser()
        }
    }

    func fetchUser() async {
        guard let userId = currentUserId else { return }

        isLoading = true
        do {
            user = try await FirestoreService.shared.getUser(id: userId)
        } catch {
            errorMessage = "프로필을 불러오는데 실패했습니다."
            print("Error fetching user: \(error)")
        }
        isLoading = false
    }

    func updateProfile(name: String, phoneNumber: String?, userType: UserType) async -> Bool {
        guard var updatedUser = user else { return false }

        isLoading = true
        errorMessage = nil

        updatedUser.name = name
        updatedUser.phoneNumber = phoneNumber
        updatedUser.userType = userType
        updatedUser.updatedAt = Date()

        do {
            try await FirestoreService.shared.updateUser(updatedUser)
            try await AuthService.shared.updateDisplayName(name)
            user = updatedUser
            successMessage = "프로필이 업데이트되었습니다."
            isLoading = false
            return true
        } catch {
            errorMessage = "프로필 업데이트에 실패했습니다."
            print("Error updating profile: \(error)")
            isLoading = false
            return false
        }
    }

    func updateProfilePhoto(_ image: UIImage) async -> Bool {
        guard var updatedUser = user,
              let userId = currentUserId else { return false }

        isLoading = true
        errorMessage = nil

        do {
            let urlString = try await StorageService.shared.uploadProfileImage(
                image,
                userId: userId
            )

            updatedUser.photoURL = urlString
            updatedUser.updatedAt = Date()

            try await FirestoreService.shared.updateUser(updatedUser)
            if let photoURL = URL(string: urlString) {
                try await AuthService.shared.updatePhotoURL(photoURL)
            }

            user = updatedUser
            successMessage = "프로필 사진이 업데이트되었습니다."
            isLoading = false
            return true
        } catch {
            errorMessage = "프로필 사진 업데이트에 실패했습니다."
            print("Error updating profile photo: \(error)")
            isLoading = false
            return false
        }
    }

    func fetchMyReviews() async {
        guard let userId = currentUserId else { return }

        do {
            myReviews = try await FirestoreService.shared.getUserReviews(userId: userId)
        } catch {
            print("Error fetching my reviews: \(error)")
        }
    }

    func deleteMyReview(id: String) async -> Bool {
        do {
            try await FirestoreService.shared.deleteReview(id: id)
            await fetchMyReviews()
            successMessage = "리뷰가 삭제되었습니다."
            return true
        } catch {
            errorMessage = "리뷰 삭제에 실패했습니다."
            return false
        }
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
