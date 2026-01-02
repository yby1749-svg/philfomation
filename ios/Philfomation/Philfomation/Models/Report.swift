//
//  Report.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

// MARK: - Report Model
struct Report: Identifiable, Codable {
    @DocumentID var id: String?
    let reporterId: String
    let reporterName: String
    let targetType: ReportTargetType
    let targetId: String
    let targetAuthorId: String
    let reason: ReportReason
    let details: String?
    let status: ReportStatus
    let createdAt: Date
    var resolvedAt: Date?
    var resolvedBy: String?
    var resolutionNote: String?

    enum CodingKeys: String, CodingKey {
        case id
        case reporterId
        case reporterName
        case targetType
        case targetId
        case targetAuthorId
        case reason
        case details
        case status
        case createdAt
        case resolvedAt
        case resolvedBy
        case resolutionNote
    }
}

// MARK: - Report Target Type
enum ReportTargetType: String, Codable {
    case post
    case comment
    case user
    case business
    case review
}

// MARK: - Report Reason
enum ReportReason: String, Codable, CaseIterable, Identifiable {
    case spam = "스팸/광고"
    case inappropriate = "부적절한 내용"
    case harassment = "괴롭힘/욕설"
    case falseInfo = "허위 정보"
    case copyright = "저작권 침해"
    case other = "기타"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .spam: return "exclamationmark.bubble"
        case .inappropriate: return "eye.slash"
        case .harassment: return "person.fill.xmark"
        case .falseInfo: return "exclamationmark.triangle"
        case .copyright: return "doc.text"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Report Status
enum ReportStatus: String, Codable {
    case pending = "pending"
    case reviewing = "reviewing"
    case resolved = "resolved"
    case dismissed = "dismissed"

    var displayName: String {
        switch self {
        case .pending: return "대기 중"
        case .reviewing: return "검토 중"
        case .resolved: return "처리 완료"
        case .dismissed: return "기각"
        }
    }
}
