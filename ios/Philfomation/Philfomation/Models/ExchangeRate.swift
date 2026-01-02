//
//  ExchangeRate.swift
//  Philfomation
//

import Foundation

// MARK: - Exchange Rate Model
struct ExchangeRate: Codable, Identifiable {
    var id: String { base + target }
    let base: String           // 기준 통화 (예: KRW)
    let target: String         // 대상 통화 (예: PHP)
    let rate: Double           // 환율
    let previousRate: Double?  // 이전 환율 (변동 계산용)
    let lastUpdated: Date      // 마지막 업데이트 시간

    // 환율 변동 계산
    var change: Double? {
        guard let previous = previousRate else { return nil }
        return rate - previous
    }

    // 환율 변동률 (%)
    var changePercent: Double? {
        guard let previous = previousRate, previous != 0 else { return nil }
        return ((rate - previous) / previous) * 100
    }

    // 상승/하락/변동없음
    var trend: ExchangeRateTrend {
        guard let change = change else { return .unchanged }
        if change > 0 { return .up }
        if change < 0 { return .down }
        return .unchanged
    }
}

// MARK: - Exchange Rate Trend
enum ExchangeRateTrend {
    case up
    case down
    case unchanged

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .unchanged: return "minus"
        }
    }

    var color: String {
        switch self {
        case .up: return "E53935"      // 빨간색 (환율 상승 = 원화 약세)
        case .down: return "43A047"    // 초록색 (환율 하락 = 원화 강세)
        case .unchanged: return "757575"
        }
    }
}

// MARK: - Currency
enum Currency: String, CaseIterable, Identifiable {
    case KRW = "KRW"
    case PHP = "PHP"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .KRW: return "한국 원"
        case .PHP: return "필리핀 페소"
        }
    }

    var symbol: String {
        switch self {
        case .KRW: return "₩"
        case .PHP: return "₱"
        }
    }

    var flag: String {
        switch self {
        case .KRW: return "🇰🇷"
        case .PHP: return "🇵🇭"
        }
    }
}

// MARK: - API Response Models
struct ExchangeRateAPIResponse: Codable {
    let result: String
    let base_code: String
    let conversion_rates: [String: Double]
    let time_last_update_utc: String?
}

// MARK: - Exchange Rate Cache
struct ExchangeRateCache: Codable {
    let rate: ExchangeRate
    let cachedAt: Date

    var isExpired: Bool {
        // 캐시 만료 시간: 30분
        let expirationInterval: TimeInterval = 30 * 60
        return Date().timeIntervalSince(cachedAt) > expirationInterval
    }
}
