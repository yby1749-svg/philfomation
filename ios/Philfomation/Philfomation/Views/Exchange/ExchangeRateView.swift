//
//  ExchangeRateView.swift
//  Philfomation
//

import SwiftUI

struct ExchangeRateView: View {
    @StateObject private var viewModel = ExchangeRateViewModel()
    @FocusState private var focusedField: Field?

    enum Field {
        case krw, php
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 현재 환율 카드
                CurrentRateCard(viewModel: viewModel)

                // 환율 계산기
                CalculatorSection(viewModel: viewModel, focusedField: $focusedField)

                // 환율 정보
                RateInfoSection(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("환율 계산기")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") {
                    focusedField = nil
                }
            }
        }
    }
}

// MARK: - Current Rate Card
struct CurrentRateCard: View {
    @ObservedObject var viewModel: ExchangeRateViewModel

    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack {
                Text("현재 환율")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(viewModel.lastUpdatedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // KRW to PHP
            RateRow(
                fromCurrency: .KRW,
                toCurrency: .PHP,
                rate: viewModel.krwToPhpRate,
                formattedRate: viewModel.formattedKrwToPhpRate
            )

            // PHP to KRW
            RateRow(
                fromCurrency: .PHP,
                toCurrency: .KRW,
                rate: viewModel.phpToKrwRate,
                formattedRate: viewModel.formattedPhpToKrwRate
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct RateRow: View {
    let fromCurrency: Currency
    let toCurrency: Currency
    let rate: ExchangeRate?
    let formattedRate: String

    var body: some View {
        HStack(spacing: 12) {
            // 통화 정보
            HStack(spacing: 8) {
                Text(fromCurrency.flag)
                    .font(.title2)
                Text("1 \(fromCurrency.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack(spacing: 8) {
                Text(toCurrency.flag)
                    .font(.title2)
                Text("\(formattedRate) \(toCurrency.rawValue)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()

            // 변동 표시
            if let rate = rate {
                TrendBadge(trend: rate.trend, changePercent: rate.changePercent)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TrendBadge: View {
    let trend: ExchangeRateTrend
    let changePercent: Double?

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.caption2)

            if let percent = changePercent {
                Text(String(format: "%.2f%%", abs(percent)))
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(hex: trend.color).opacity(0.15))
        .foregroundStyle(Color(hex: trend.color))
        .clipShape(Capsule())
    }
}

// MARK: - Calculator Section
struct CalculatorSection: View {
    @ObservedObject var viewModel: ExchangeRateViewModel
    var focusedField: FocusState<ExchangeRateView.Field?>.Binding

    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack {
                Text("환율 계산기")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    viewModel.clearInputs()
                } label: {
                    Text("초기화")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // KRW 입력
            CurrencyInputField(
                currency: .KRW,
                amount: Binding(
                    get: { viewModel.krwAmount },
                    set: { viewModel.updateKrwAmount($0) }
                ),
                isActive: viewModel.selectedDirection == .krwToPhp
            )
            .focused(focusedField, equals: .krw)
            .onTapGesture {
                viewModel.selectedDirection = .krwToPhp
            }

            // 스왑 버튼
            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.swapDirection()
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color(hex: "2563EB"))
                    .rotationEffect(.degrees(viewModel.selectedDirection == .krwToPhp ? 0 : 180))
            }

            // PHP 입력
            CurrencyInputField(
                currency: .PHP,
                amount: Binding(
                    get: { viewModel.phpAmount },
                    set: { viewModel.updatePhpAmount($0) }
                ),
                isActive: viewModel.selectedDirection == .phpToKrw
            )
            .focused(focusedField, equals: .php)
            .onTapGesture {
                viewModel.selectedDirection = .phpToKrw
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CurrencyInputField: View {
    let currency: Currency
    @Binding var amount: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 통화 플래그 및 심볼
            VStack(alignment: .leading, spacing: 2) {
                Text(currency.flag)
                    .font(.title2)
                Text(currency.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50)

            // 입력 필드
            TextField("0", text: $amount)
                .font(.title2)
                .fontWeight(.semibold)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)

            // 통화 심볼
            Text(currency.symbol)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(isActive ? Color(hex: "2563EB").opacity(0.05) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color(hex: "2563EB") : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Rate Info Section
struct RateInfoSection: View {
    @ObservedObject var viewModel: ExchangeRateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("환율 정보")
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                ExchangeInfoRow(icon: "info.circle.fill", text: "환율은 실시간으로 변동될 수 있습니다.")
                ExchangeInfoRow(icon: "clock.fill", text: "데이터는 30분마다 갱신됩니다.")
                ExchangeInfoRow(icon: "building.columns.fill", text: "실제 환전 시 수수료가 추가될 수 있습니다.")
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ExchangeInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color(hex: "2563EB"))
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

// MARK: - Compact Exchange Rate Card (for Home)
struct CompactExchangeRateCard: View {
    @ObservedObject var viewModel: ExchangeRateViewModel

    var body: some View {
        VStack(spacing: 12) {
            // 헤더
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "wonsign.circle.fill")
                        .foregroundStyle(Color(hex: "2563EB"))
                    Text("환율")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Text(viewModel.lastUpdatedText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // 환율 정보
            HStack(spacing: 16) {
                // KRW -> PHP
                VStack(alignment: .leading, spacing: 4) {
                    Text("🇰🇷 KRW → 🇵🇭 PHP")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Text(viewModel.formattedKrwToPhpRate)
                            .font(.headline)
                            .fontWeight(.bold)

                        if let rate = viewModel.krwToPhpRate {
                            Image(systemName: rate.trend.icon)
                                .font(.caption2)
                                .foregroundStyle(Color(hex: rate.trend.color))
                        }
                    }
                }

                Spacer()

                // PHP -> KRW
                VStack(alignment: .trailing, spacing: 4) {
                    Text("🇵🇭 PHP → 🇰🇷 KRW")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Text(viewModel.formattedPhpToKrwRate)
                            .font(.headline)
                            .fontWeight(.bold)

                        if let rate = viewModel.phpToKrwRate {
                            Image(systemName: rate.trend.icon)
                                .font(.caption2)
                                .foregroundStyle(Color(hex: rate.trend.color))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    NavigationStack {
        ExchangeRateView()
    }
}
