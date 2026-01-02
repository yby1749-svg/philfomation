//
//  ExchangeRateService.swift
//  Philfomation
//

import Foundation

// MARK: - Exchange Rate Service
class ExchangeRateService {
    static let shared = ExchangeRateService()

    // 무료 API: exchangerate-api.com (월 1500회 무료)
    // 대안: Open Exchange Rates, Fixer.io 등
    private let baseURL = "https://api.exchangerate-api.com/v4/latest"

    private let userDefaults = UserDefaults.standard
    private let cacheKeyPrefix = "exchangeRate_"

    private init() {}

    // MARK: - Fetch Exchange Rate
    func fetchExchangeRate(from base: Currency, to target: Currency) async throws -> ExchangeRate {
        // 1. 캐시 확인
        if let cached = getCachedRate(base: base, target: target), !cached.isExpired {
            return cached.rate
        }

        // 2. API 호출
        guard let url = URL(string: "\(baseURL)/\(base.rawValue)") else {
            throw ExchangeRateError.invalidResponse
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ExchangeRateError.invalidResponse
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ExchangeRateAPIResponse.self, from: data)

        guard let targetRate = apiResponse.conversion_rates[target.rawValue] else {
            throw ExchangeRateError.currencyNotFound
        }

        // 3. 이전 환율 가져오기
        let previousRate = getCachedRate(base: base, target: target)?.rate.rate

        // 4. ExchangeRate 생성
        let exchangeRate = ExchangeRate(
            base: base.rawValue,
            target: target.rawValue,
            rate: targetRate,
            previousRate: previousRate,
            lastUpdated: Date()
        )

        // 5. 캐시 저장
        cacheRate(exchangeRate, base: base, target: target)

        return exchangeRate
    }

    // MARK: - Fetch Both Directions
    func fetchBothDirections() async throws -> (krwToPhp: ExchangeRate, phpToKrw: ExchangeRate) {
        async let krwToPhp = fetchExchangeRate(from: .KRW, to: .PHP)
        async let phpToKrw = fetchExchangeRate(from: .PHP, to: .KRW)

        return try await (krwToPhp, phpToKrw)
    }

    // MARK: - Convert Currency
    func convert(amount: Double, from: Currency, to: Currency, rate: Double) -> Double {
        return amount * rate
    }

    // MARK: - Cache Management
    private func getCachedRate(base: Currency, target: Currency) -> ExchangeRateCache? {
        let key = cacheKeyPrefix + base.rawValue + "_" + target.rawValue

        guard let data = userDefaults.data(forKey: key) else { return nil }

        return try? JSONDecoder().decode(ExchangeRateCache.self, from: data)
    }

    private func cacheRate(_ rate: ExchangeRate, base: Currency, target: Currency) {
        let key = cacheKeyPrefix + base.rawValue + "_" + target.rawValue
        let cache = ExchangeRateCache(rate: rate, cachedAt: Date())

        if let data = try? JSONEncoder().encode(cache) {
            userDefaults.set(data, forKey: key)
        }
    }

    func clearCache() {
        for base in Currency.allCases {
            for target in Currency.allCases {
                let key = cacheKeyPrefix + base.rawValue + "_" + target.rawValue
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}

// MARK: - Errors
enum ExchangeRateError: LocalizedError {
    case invalidResponse
    case currencyNotFound
    case networkError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다."
        case .currencyNotFound:
            return "환율 정보를 찾을 수 없습니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .decodingError:
            return "데이터 처리 중 오류가 발생했습니다."
        }
    }
}
