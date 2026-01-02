//
//  StorageService.swift
//  Philfomation
//

import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    static let shared = StorageService()

    private let storage = Storage.storage()
    private let maxImageSize: Int64 = 5 * 1024 * 1024 // 5MB

    private init() {}

    // MARK: - Upload Image

    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImage
        }

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()

        return downloadURL.absoluteString
    }

    func uploadPostImages(_ images: [UIImage], postId: String) async throws -> [String] {
        var urls: [String] = []

        for (index, image) in images.enumerated() {
            let path = "posts/\(postId)/image_\(index)_\(UUID().uuidString).jpg"
            let url = try await uploadImage(image, path: path)
            urls.append(url)
        }

        return urls
    }

    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> String {
        let path = "profiles/\(userId)/profile_\(UUID().uuidString).jpg"
        return try await uploadImage(image, path: path)
    }

    func uploadChatImage(_ image: UIImage) async throws -> String {
        let path = "chats/\(UUID().uuidString).jpg"
        return try await uploadImage(image, path: path)
    }

    func uploadReviewImages(_ images: [UIImage], reviewId: String) async throws -> [String] {
        var urls: [String] = []

        for (index, image) in images.enumerated() {
            let path = "reviews/\(reviewId)/image_\(index)_\(UUID().uuidString).jpg"
            let url = try await uploadImage(image, path: path)
            urls.append(url)
        }

        return urls
    }

    // MARK: - Delete Image

    func deleteImage(url: String) async throws {
        let ref = storage.reference(forURL: url)
        try await ref.delete()
    }

    func deletePostImages(postId: String) async throws {
        let ref = storage.reference().child("posts/\(postId)")

        do {
            let result = try await ref.listAll()
            for item in result.items {
                try await item.delete()
            }
        } catch {
            print("Error deleting post images: \(error)")
        }
    }
}

// MARK: - Storage Error
enum StorageError: LocalizedError {
    case invalidImage
    case uploadFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "이미지를 처리할 수 없습니다"
        case .uploadFailed:
            return "이미지 업로드에 실패했습니다"
        case .downloadFailed:
            return "이미지 다운로드에 실패했습니다"
        }
    }
}
