//
//  ExchangeRateViewModel.swift
//  Philfomation
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ExchangeRateViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var krwToPhpRate: ExchangeRate?
    @Published var phpToKrwRate: ExchangeRate?

    @Published var isLoading = false
    @Published var errorMessage: String?

    // 계산기 입력값
    @Published var krwAmount: String = ""
    @Published var phpAmount: String = ""

    // 현재 선택된 방향
    @Published var selectedDirection: ConversionDirection = .krwToPhp

    // MARK: - Private Properties
    private let service = ExchangeRateService.shared

    // MARK: - Computed Properties
    var currentRate: ExchangeRate? {
        selectedDirection == .krwToPhp ? krwToPhpRate : phpToKrwRate
    }

    var formattedKrwToPhpRate: String {
        guard let rate = krwToPhpRate else { return "-" }
        return String(format: "%.4f", rate.rate)
    }

    var formattedPhpToKrwRate: String {
        guard let rate = phpToKrwRate else { return "-" }
        return String(format: "%.2f", rate.rate)
    }

    var lastUpdatedText: String {
        guard let rate = krwToPhpRate else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: rate.lastUpdated, relativeTo: Date())
    }

    // MARK: - Initialization
    init() {
        Task {
            await fetchRates()
        }
    }

    // MARK: - Methods
    func fetchRates() async {
        isLoading = true
        errorMessage = nil

        do {
            let rates = try await service.fetchBothDirections()
            krwToPhpRate = rates.krwToPhp
            phpToKrwRate = rates.phpToKrw

            // Save to widget data
            if let phpToKrw = phpToKrwRate?.rate, let krwToPhp = krwToPhpRate?.rate {
                WidgetDataManager.shared.saveExchangeRate(phpToKrw: phpToKrw, krwToPhp: krwToPhp)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        service.clearCache()
        await fetchRates()
    }

    // MARK: - Conversion Methods
    func convertKrwToPhp() {
        guard let rate = krwToPhpRate?.rate,
              let amount = Double(krwAmount.replacingOccurrences(of: ",", with: "")) else {
            phpAmount = ""
            return
        }

        let result = amount * rate
        phpAmount = formatNumber(result, decimals: 2)
    }

    func convertPhpToKrw() {
        guard let rate = phpToKrwRate?.rate,
              let amount = Double(phpAmount.replacingOccurrences(of: ",", with: "")) else {
            krwAmount = ""
            return
        }

        let result = amount * rate
        krwAmount = formatNumber(result, decimals: 0)
    }

    func updateKrwAmount(_ value: String) {
        krwAmount = value
        if selectedDirection == .krwToPhp {
            convertKrwToPhp()
        }
    }

    func updatePhpAmount(_ value: String) {
        phpAmount = value
        if selectedDirection == .phpToKrw {
            convertPhpToKrw()
        }
    }

    func swapDirection() {
        selectedDirection = selectedDirection == .krwToPhp ? .phpToKrw : .krwToPhp
        // 값 초기화
        krwAmount = ""
        phpAmount = ""
    }

    func clearInputs() {
        krwAmount = ""
        phpAmount = ""
    }

    // MARK: - Helper Methods
    private func formatNumber(_ number: Double, decimals: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }

    func formatCurrency(_ amount: Double, currency: Currency) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue

        switch currency {
        case .KRW:
            formatter.maximumFractionDigits = 0
        case .PHP:
            formatter.maximumFractionDigits = 2
        }

        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }
}

// MARK: - Conversion Direction
enum ConversionDirection {
    case krwToPhp
    case phpToKrw

    var title: String {
        switch self {
        case .krwToPhp: return "원 → 페소"
        case .phpToKrw: return "페소 → 원"
        }
    }
}
