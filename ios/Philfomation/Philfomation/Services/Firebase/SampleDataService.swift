//
//  SampleDataService.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

class SampleDataService {
    static let shared = SampleDataService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Seed All Sample Data

    func seedAllData() async {
        print("Starting to seed sample data...")

        do {
            // Create sample users first
            let userIds = try await seedSampleUsers()

            // Create sample posts
            let postIds = try await seedSamplePosts(authorIds: userIds)

            // Create sample comments
            try await seedSampleComments(postIds: postIds, authorIds: userIds)

            // Create sample businesses
            try await seedSampleBusinesses()

            print("Sample data seeding completed!")
        } catch {
            print("Error seeding sample data: \(error)")
        }
    }

    // MARK: - Sample Users

    private func seedSampleUsers() async throws -> [String] {
        let users = [
            AppUser(
                id: "sample_user_1",
                name: "김민준",
                email: "kim@example.com",
                phoneNumber: "+63-917-123-4567",
                userType: .customer
            ),
            AppUser(
                id: "sample_user_2",
                name: "이서연",
                email: "lee@example.com",
                phoneNumber: "+63-918-234-5678",
                userType: .customer
            ),
            AppUser(
                id: "sample_user_3",
                name: "박지훈",
                email: "park@example.com",
                phoneNumber: "+63-919-345-6789",
                userType: .business
            )
        ]

        for user in users {
            if let userId = user.id {
                try db.collection("users").document(userId).setData(from: user)
            }
        }

        print("✓ 3 sample users created")
        return users.compactMap { $0.id }
    }

    // MARK: - Sample Posts

    private func seedSamplePosts(authorIds: [String]) async throws -> [String] {
        let posts = [
            Post(
                authorId: authorIds[0],
                authorName: "김민준",
                category: .qna,
                title: "마닐라 환전소 추천해주세요!",
                content: """
                다음 주에 마닐라 여행 가는데 환전소 어디가 좋을까요?
                공항보다 시내가 좋다고 들었는데, 말라테나 마카티 쪽에 괜찮은 곳 있으면 알려주세요.
                환율도 중요하지만 안전한 곳으로 추천 부탁드립니다!
                """,
                imageURLs: nil,
                likeCount: 12,
                commentCount: 3,
                viewCount: 156,
                createdAt: Date().addingTimeInterval(-86400), // 1 day ago
                updatedAt: nil
            ),
            Post(
                authorId: authorIds[1],
                authorName: "이서연",
                category: .experience,
                title: "보라카이 3박4일 여행 후기",
                content: """
                저번 주에 보라카이 다녀왔어요! 정말 아름다운 곳이었습니다.

                화이트비치가 정말 유명한데, 아침 일찍 가면 사람도 적고 사진 찍기 좋아요.
                저녁에는 디몰에서 씨푸드 먹었는데 신선하고 맛있었습니다.

                다만 성수기라 호텔 가격이 비쌌어요. 미리 예약하시는 걸 추천드려요!
                """,
                imageURLs: nil,
                likeCount: 45,
                commentCount: 8,
                viewCount: 523,
                createdAt: Date().addingTimeInterval(-172800), // 2 days ago
                updatedAt: nil
            ),
            Post(
                authorId: authorIds[2],
                authorName: "박지훈",
                category: .tip,
                title: "필리핀 그랩(Grab) 사용 꿀팁 공유",
                content: """
                필리핀에서 이동할 때 그랩 많이 쓰시죠? 제가 3년간 사용하면서 터득한 팁 공유합니다!

                1. 출퇴근 시간(7-9시, 17-19시)은 피하세요. 요금이 2-3배 뛰어요.
                2. GrabCar보다 GrabShare가 저렴해요. 단, 합승이라 시간이 더 걸릴 수 있어요.
                3. 목적지를 정확하게 입력하세요. 랜드마크 이름으로 검색하면 편해요.
                4. 현금 결제시 잔돈 준비하세요. 기사님들 큰 돈 거스름돈 없는 경우 많아요.

                도움이 되셨으면 좋겠네요!
                """,
                imageURLs: nil,
                likeCount: 89,
                commentCount: 15,
                viewCount: 1024,
                createdAt: Date().addingTimeInterval(-259200), // 3 days ago
                updatedAt: nil
            )
        ]

        var postIds: [String] = []

        for post in posts {
            let ref = try db.collection("posts").addDocument(from: post)
            postIds.append(ref.documentID)
        }

        print("✓ 3 sample posts created")
        return postIds
    }

    // MARK: - Sample Comments

    private func seedSampleComments(postIds: [String], authorIds: [String]) async throws {
        // Comments for first post (환전소 추천)
        let comments = [
            Comment(
                postId: postIds[0],
                authorId: authorIds[1],
                authorName: "이서연",
                content: "말라테 로빈슨 근처에 Sanry's 환전소 추천해요! 환율 좋고 안전해요.",
                likeCount: 5,
                createdAt: Date().addingTimeInterval(-43200),
                updatedAt: nil
            ),
            Comment(
                postId: postIds[0],
                authorId: authorIds[2],
                authorName: "박지훈",
                content: "마카티 그린벨트 쪽 환전소도 괜찮아요. 쇼핑하면서 환전하기 편해요.",
                likeCount: 3,
                createdAt: Date().addingTimeInterval(-21600),
                updatedAt: nil
            ),
            Comment(
                postId: postIds[1],
                authorId: authorIds[0],
                authorName: "김민준",
                content: "보라카이 저도 가고 싶었는데! 숙소 어디 묵으셨어요?",
                likeCount: 2,
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: nil
            )
        ]

        for comment in comments {
            _ = try db.collection("comments").addDocument(from: comment)
        }

        print("✓ 3 sample comments created")
    }

    // MARK: - Sample Businesses

    private func seedSampleBusinesses() async throws {
        let businesses = [
            Business(
                name: "한식당 서울",
                category: .restaurant,
                description: "마카티 중심부에 위치한 정통 한식당입니다. 삼겹살, 불고기, 김치찌개 등 다양한 한식 메뉴를 제공합니다.",
                address: "123 Makati Ave, Makati City",
                phone: "+63-2-8888-1234",
                photos: [],
                rating: 4.5,
                reviewCount: 28,
                latitude: 14.5547,
                longitude: 121.0244,
                openingHours: "월-토: 11:00-22:00, 일: 12:00-21:00"
            ),
            Business(
                name: "K-마트",
                category: .mart,
                description: "한국 식품, 과자, 라면, 화장품 등 다양한 한국 제품을 판매하는 마트입니다.",
                address: "456 BGC, Taguig City",
                phone: "+63-2-7777-5678",
                photos: [],
                rating: 4.2,
                reviewCount: 45,
                latitude: 14.5505,
                longitude: 121.0455,
                openingHours: "매일: 09:00-21:00"
            ),
            Business(
                name: "코리안 헤어샵",
                category: .salon,
                description: "한국 스타일 헤어컷과 펌, 염색 전문 미용실입니다. 한국어 상담 가능합니다.",
                address: "789 Ortigas Center, Pasig City",
                phone: "+63-2-6666-9012",
                photos: [],
                rating: 4.7,
                reviewCount: 62,
                latitude: 14.5873,
                longitude: 121.0615,
                openingHours: "화-일: 10:00-20:00, 월요일 휴무"
            )
        ]

        for business in businesses {
            _ = try db.collection("businesses").addDocument(from: business)
        }

        print("✓ 3 sample businesses created")
    }
}
