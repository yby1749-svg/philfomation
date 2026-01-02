//
//  ReportService.swift
//  Philfomation
//

import Foundation
import FirebaseFirestore

class ReportService {
    static let shared = ReportService()

    private let db = Firestore.firestore()
    private let reportsCollection = "reports"

    private init() {}

    // MARK: - Create Report

    func createReport(_ report: Report) async throws -> String {
        let ref = try db.collection(reportsCollection).addDocument(from: report)
        return ref.documentID
    }

    func reportPost(
        postId: String,
        postAuthorId: String,
        reporterId: String,
        reporterName: String,
        reason: ReportReason,
        details: String?
    ) async throws {
        let report = Report(
            reporterId: reporterId,
            reporterName: reporterName,
            targetType: .post,
            targetId: postId,
            targetAuthorId: postAuthorId,
            reason: reason,
            details: details,
            status: .pending,
            createdAt: Date()
        )

        _ = try await createReport(report)
    }

    func reportComment(
        commentId: String,
        commentAuthorId: String,
        reporterId: String,
        reporterName: String,
        reason: ReportReason,
        details: String?
    ) async throws {
        let report = Report(
            reporterId: reporterId,
            reporterName: reporterName,
            targetType: .comment,
            targetId: commentId,
            targetAuthorId: commentAuthorId,
            reason: reason,
            details: details,
            status: .pending,
            createdAt: Date()
        )

        _ = try await createReport(report)
    }

    func reportUser(
        userId: String,
        reporterId: String,
        reporterName: String,
        reason: ReportReason,
        details: String?
    ) async throws {
        let report = Report(
            reporterId: reporterId,
            reporterName: reporterName,
            targetType: .user,
            targetId: userId,
            targetAuthorId: userId,
            reason: reason,
            details: details,
            status: .pending,
            createdAt: Date()
        )

        _ = try await createReport(report)
    }

    // MARK: - Check if already reported

    func hasUserReported(reporterId: String, targetId: String) async throws -> Bool {
        let snapshot = try await db.collection(reportsCollection)
            .whereField("reporterId", isEqualTo: reporterId)
            .whereField("targetId", isEqualTo: targetId)
            .limit(to: 1)
            .getDocuments()

        return !snapshot.documents.isEmpty
    }

    // MARK: - Fetch Reports (for admin)

    func fetchPendingReports() async throws -> [Report] {
        let snapshot = try await db.collection(reportsCollection)
            .whereField("status", isEqualTo: ReportStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Report.self) }
    }

    func fetchUserReports(userId: String) async throws -> [Report] {
        let snapshot = try await db.collection(reportsCollection)
            .whereField("reporterId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Report.self) }
    }

    // MARK: - Update Report Status (for admin)

    func updateReportStatus(
        reportId: String,
        status: ReportStatus,
        resolvedBy: String?,
        resolutionNote: String?
    ) async throws {
        var data: [String: Any] = [
            "status": status.rawValue
        ]

        if status == .resolved || status == .dismissed {
            data["resolvedAt"] = Timestamp(date: Date())
            if let resolvedBy = resolvedBy {
                data["resolvedBy"] = resolvedBy
            }
            if let note = resolutionNote {
                data["resolutionNote"] = note
            }
        }

        try await db.collection(reportsCollection).document(reportId).updateData(data)
    }
}
