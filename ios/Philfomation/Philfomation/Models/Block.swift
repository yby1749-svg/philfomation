//
//  Block.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

struct Block: Identifiable, Codable {
    @DocumentID var id: String?
    let blockerId: String      // 차단한 사용자
    let blockedId: String      // 차단당한 사용자
    let blockedName: String    // 차단당한 사용자 이름
    let blockedPhotoURL: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case blockerId
        case blockedId
        case blockedName
        case blockedPhotoURL
        case createdAt
    }
}
