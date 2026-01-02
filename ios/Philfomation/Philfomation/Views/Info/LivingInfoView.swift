//
//  LivingInfoView.swift
//  Philfomation
//

import SwiftUI

struct LivingInfoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Banking & ATM Section
                BankingSection()

                // Money Transfer Section
                MoneyTransferSection()

                // SIM & Internet Section
                SimInternetSection()

                // Transportation Section
                TransportationSection()

                // Useful Tips Section
                LivingTipsSection()
            }
            .padding()
        }
        .navigationTitle("생활 정보")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Banking Section
struct BankingSection: View {
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderWithToggle(
                icon: "creditcard.fill",
                title: "은행 & ATM 정보",
                color: .green,
                isExpanded: $isExpanded
            )

            if isExpanded {
                VStack(spacing: 12) {
                    BankInfoCard(
                        bankName: "우리은행 (Woori Bank)",
                        location: "마카티, BGC, 세부 등",
                        services: "현금 인출, 송금, 환전",
                        tips: "한국 우리은행 카드로 필리핀 ATM 출금 가능\n수수료: 약 250페소 + 한국측 수수료",
                        color: Color(hex: "0066B3")
                    )

                    BankInfoCard(
                        bankName: "BDO (Banco de Oro)",
                        location: "전국 지점",
                        services: "ATM 출금, 계좌 개설",
                        tips: "가장 많은 ATM 보유\n1회 출금 한도: 10,000~20,000페소",
                        color: Color(hex: "003DA5")
                    )

                    BankInfoCard(
                        bankName: "BPI (Bank of Philippine Islands)",
                        location: "전국 지점",
                        services: "ATM 출금, 온라인 뱅킹",
                        tips: "외국 카드 호환성 좋음\n24시간 ATM 이용 가능",
                        color: Color(hex: "C8102E")
                    )

                    // ATM Tips
                    InfoCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "ATM 이용 팁",
                        content: """
                        • 쇼핑몰 내부 ATM 이용 권장 (안전)
                        • 야간 노상 ATM 이용 자제
                        • 카드 복제 주의 (스키밍)
                        • 인출 전 주변 확인
                        • 1회 한도 확인 후 여러번 출금
                        """,
                        color: .orange
                    )
                }
            }
        }
    }
}

// MARK: - Money Transfer Section
struct MoneyTransferSection: View {
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderWithToggle(
                icon: "arrow.left.arrow.right.circle.fill",
                title: "송금 & 환전",
                color: .blue,
                isExpanded: $isExpanded
            )

            if isExpanded {
                VStack(spacing: 12) {
                    TransferMethodCard(
                        name: "한패스 (Hanpass)",
                        description: "한국→필리핀 송금 서비스",
                        pros: "빠른 송금, 경쟁력 있는 환율",
                        cons: "앱 설치 필요",
                        fee: "송금액에 따라 다름"
                    )

                    TransferMethodCard(
                        name: "웨스턴유니온 (Western Union)",
                        description: "전 세계 송금 네트워크",
                        pros: "현금 수령 가능, 전국 지점",
                        cons: "수수료 높음",
                        fee: "약 1,000~3,000원"
                    )

                    TransferMethodCard(
                        name: "와이즈 (Wise)",
                        description: "온라인 해외 송금",
                        pros: "저렴한 수수료, 실시간 환율",
                        cons: "계좌 이체만 가능",
                        fee: "약 0.5~1%"
                    )

                    TransferMethodCard(
                        name: "현지 환전소",
                        description: "마닐라, 세부 등 주요 도시",
                        pros: "즉시 환전, 협상 가능",
                        cons: "위치에 따라 환율 차이",
                        fee: "환율에 포함"
                    )

                    InfoCard(
                        icon: "lightbulb.fill",
                        title: "환전 팁",
                        content: """
                        • 공항 환전소는 환율 불리함
                        • 말라테, 에르미타 환전소 환율 좋음
                        • 대량 환전 시 협상 가능
                        • 달러→페소가 원화→페소보다 유리할 수 있음
                        • 환전 후 금액 반드시 확인
                        """,
                        color: .yellow
                    )
                }
            }
        }
    }
}

// MARK: - SIM & Internet Section
struct SimInternetSection: View {
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderWithToggle(
                icon: "wifi",
                title: "통신 & 인터넷",
                color: .purple,
                isExpanded: $isExpanded
            )

            if isExpanded {
                VStack(spacing: 12) {
                    SimCard(
                        provider: "Globe",
                        color: Color(hex: "00A0E4"),
                        coverage: "★★★★☆",
                        speed: "★★★★☆",
                        price: "프리페이드: 40페소~",
                        dataPlans: ["GoSURF50: 1GB/3일 - 50페소", "GoSURF299: 8GB/30일 - 299페소", "Go90: 2GB/7일 - 90페소"]
                    )

                    SimCard(
                        provider: "Smart",
                        color: Color(hex: "00913A"),
                        coverage: "★★★★★",
                        speed: "★★★★☆",
                        price: "프리페이드: 40페소~",
                        dataPlans: ["Giga99: 2GB/7일 - 99페소", "Giga299: 8GB/30일 - 299페소", "All Data 149: 3GB/7일 - 149페소"]
                    )

                    SimCard(
                        provider: "DITO",
                        color: Color(hex: "F15A24"),
                        coverage: "★★★☆☆",
                        speed: "★★★★★",
                        price: "프리페이드: 99페소~",
                        dataPlans: ["DITO 199: 25GB/30일 - 199페소", "DITO 299: 35GB/30일 - 299페소"]
                    )

                    // Home Internet
                    InfoCard(
                        icon: "house.fill",
                        title: "가정용 인터넷",
                        content: """
                        • PLDT Fibr: 가장 안정적, 1699페소~/월
                        • Globe At Home: 경쟁력 있는 가격, 1499페소~/월
                        • Converge: 빠른 속도, 1500페소~/월
                        • Sky Fiber: 저렴한 옵션, 1299페소~/월
                        """,
                        color: .cyan
                    )
                }
            }
        }
    }
}

// MARK: - Transportation Section
struct TransportationSection: View {
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderWithToggle(
                icon: "car.fill",
                title: "교통수단",
                color: .orange,
                isExpanded: $isExpanded
            )

            if isExpanded {
                VStack(spacing: 12) {
                    TransportCard(
                        name: "Grab",
                        icon: "car.fill",
                        description: "가장 안전하고 편리한 이동수단",
                        price: "거리/시간에 따라 책정",
                        tips: "현금/카드 결제 가능, 영수증 발급"
                    )

                    TransportCard(
                        name: "택시",
                        icon: "car.side.fill",
                        description: "미터기 택시, 흰색/노란색",
                        price: "기본요금 40페소~",
                        tips: "미터기 작동 확인 필수, 잔돈 준비"
                    )

                    TransportCard(
                        name: "지프니 (Jeepney)",
                        icon: "bus.fill",
                        description: "현지 대중교통, 정해진 노선 운행",
                        price: "기본요금 13페소~",
                        tips: "현지 경험용, 소매치기 주의"
                    )

                    TransportCard(
                        name: "트라이시클 (Tricycle)",
                        icon: "bicycle",
                        description: "오토바이 + 사이드카",
                        price: "협상제 (단거리 20~50페소)",
                        tips: "짧은 거리 이동에 적합"
                    )

                    TransportCard(
                        name: "렌트카",
                        icon: "key.fill",
                        description: "장기 체류 시 편리",
                        price: "1,500~3,000페소/일",
                        tips: "국제운전면허증 필요, 보험 확인"
                    )
                }
            }
        }
    }
}

// MARK: - Living Tips Section
struct LivingTipsSection: View {
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderWithToggle(
                icon: "lightbulb.fill",
                title: "생활 꿀팁",
                color: .yellow,
                isExpanded: $isExpanded
            )

            if isExpanded {
                VStack(spacing: 12) {
                    TipCard(
                        category: "쇼핑",
                        tips: [
                            "SM, Robinsons, Ayala 몰에서 대부분 구매 가능",
                            "한국 식품: 한인마트 (마카티, BGC)",
                            "약국: Mercury Drug, Watsons 전국 체인",
                            "온라인: Lazada, Shopee 배송 서비스"
                        ]
                    )

                    TipCard(
                        category: "음식",
                        tips: [
                            "한식당: 마카티, BGC, 말라테 지역 다수",
                            "배달앱: GrabFood, Foodpanda",
                            "로컬음식: Jollibee, Chowking, Mang Inasal",
                            "물: 반드시 생수 구매 (수돗물 음용 금지)"
                        ]
                    )

                    TipCard(
                        category: "의료",
                        tips: [
                            "대형병원: St. Luke's, Makati Medical Center",
                            "한국어 가능 병원: 일부 병원 한국인 코디네이터",
                            "약국: 처방전 없이 구매 가능한 약 많음",
                            "여행자보험 가입 필수 권장"
                        ]
                    )

                    TipCard(
                        category: "안전",
                        tips: [
                            "귀중품은 호텔 금고에 보관",
                            "야간 외출 시 Grab 이용",
                            "과시적인 복장/액세서리 자제",
                            "여권 사본 항상 소지",
                            "긴급 시 대사관 연락: +63-2-8856-9210"
                        ]
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct SectionHeaderWithToggle: View {
    let icon: String
    let title: String
    let color: Color
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
        }
        .buttonStyle(.plain)
    }
}

struct BankInfoCard: View {
    let bankName: String
    let location: String
    let services: String
    let tips: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(bankName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Label(location, systemImage: "mappin.circle")
                Label(services, systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(tips)
                .font(.caption)
                .foregroundStyle(.primary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TransferMethodCard: View {
    let name: String
    let description: String
    let pros: String
    let cons: String
    let fee: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("장점", systemImage: "plus.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text(pros)
                        .font(.caption)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Label("단점", systemImage: "minus.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text(cons)
                        .font(.caption)
                }
            }

            HStack {
                Text("수수료:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(fee)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(content)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SimCard: View {
    let provider: String
    let color: Color
    let coverage: String
    let speed: String
    let price: String
    let dataPlans: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(provider)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(color)
                    .clipShape(Capsule())

                Spacer()

                Text(price)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("커버리지")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(coverage)
                        .font(.caption)
                }

                VStack(alignment: .leading) {
                    Text("속도")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(speed)
                        .font(.caption)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("데이터 플랜")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach(dataPlans, id: \.self) { plan in
                    Text("• \(plan)")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TransportCard: View {
    let name: String
    let icon: String
    let description: String
    let price: String
    let tips: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color(hex: "2563EB"))
                .frame(width: 44, height: 44)
                .background(Color(hex: "2563EB").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(price)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(hex: "2563EB"))
                }

                Text(tips)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TipCard: View {
    let category: String
    let tips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(hex: "2563EB"))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(Color(hex: "2563EB"))
                        Text(tip)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        LivingInfoView()
    }
}
