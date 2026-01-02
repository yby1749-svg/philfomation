//
//  TravelInfoView.swift
//  Philfomation
//

import SwiftUI

struct TravelInfoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Travel Guidelines Section
                TravelGuidelinesSection()

                // Emergency Contacts Section
                EmergencyContactsSection()

                // Useful Tips Section
                UsefulTipsSection()
            }
            .padding()
        }
        .navigationTitle("여행 정보")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Travel Guidelines Section
struct TravelGuidelinesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "book.fill", title: "여행 지침서", color: .blue)

            VStack(spacing: 8) {
                GuidelineItem(
                    icon: "doc.text.fill",
                    title: "비자 정보",
                    description: "한국 여권 소지자는 30일 무비자 체류 가능. 연장 시 이민국 방문 필요."
                )

                GuidelineItem(
                    icon: "wonsign.circle.fill",
                    title: "환전",
                    description: "공항, 쇼핑몰, 환전소에서 환전 가능. 달러 또는 원화를 페소로 환전."
                )

                GuidelineItem(
                    icon: "wifi",
                    title: "통신",
                    description: "공항에서 SIM 카드 구매 권장 (Globe, Smart). 포켓 와이파이도 대여 가능."
                )

                GuidelineItem(
                    icon: "car.fill",
                    title: "교통",
                    description: "Grab 앱 사용 권장. 택시 이용 시 미터기 사용 확인. 지프니는 현지 경험용."
                )

                GuidelineItem(
                    icon: "cross.case.fill",
                    title: "건강",
                    description: "수돗물 음용 금지. 생수 구매 필수. 모기 기피제 준비 권장."
                )

                GuidelineItem(
                    icon: "shield.checkered",
                    title: "안전",
                    description: "귀중품 관리 주의. 야간 외출 시 주의. 밀집 지역에서 소매치기 주의."
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Emergency Contacts Section
struct EmergencyContactsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "phone.fill", title: "비상 연락처", color: .red)

            VStack(spacing: 0) {
                EmergencyContactItem(
                    icon: "building.columns.fill",
                    title: "주필리핀 대한민국 대사관",
                    phone: "+63-2-8856-9210",
                    subInfo: "긴급: +63-917-817-5703",
                    color: .blue
                )

                Divider().padding(.leading, 50)

                EmergencyContactItem(
                    icon: "staroflife.fill",
                    title: "응급 서비스",
                    phone: "911",
                    subInfo: "경찰, 소방, 응급의료",
                    color: .red
                )

                Divider().padding(.leading, 50)

                EmergencyContactItem(
                    icon: "shield.fill",
                    title: "필리핀 국가경찰 (PNP)",
                    phone: "117",
                    subInfo: "범죄 신고",
                    color: .blue
                )

                Divider().padding(.leading, 50)

                EmergencyContactItem(
                    icon: "flame.fill",
                    title: "소방서",
                    phone: "160",
                    subInfo: "화재 신고",
                    color: .orange
                )

                Divider().padding(.leading, 50)

                EmergencyContactItem(
                    icon: "cross.fill",
                    title: "적십자",
                    phone: "143",
                    subInfo: "의료 지원",
                    color: .red
                )

                Divider().padding(.leading, 50)

                EmergencyContactItem(
                    icon: "airplane",
                    title: "관광부 핫라인",
                    phone: "1-800-8-888-DOT",
                    subInfo: "관광객 지원",
                    color: .green
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Useful Tips Section
struct UsefulTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(icon: "lightbulb.fill", title: "유용한 팁", color: .yellow)

            VStack(spacing: 8) {
                TipItem(
                    number: "1",
                    text: "항상 여권 사본을 별도로 보관하세요."
                )

                TipItem(
                    number: "2",
                    text: "소액 현금을 여러 곳에 분산 보관하세요."
                )

                TipItem(
                    number: "3",
                    text: "중요 연락처는 오프라인에서도 확인 가능하게 저장하세요."
                )

                TipItem(
                    number: "4",
                    text: "여행자 보험 가입을 권장합니다."
                )

                TipItem(
                    number: "5",
                    text: "현지 법률과 문화를 존중하세요."
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Supporting Views
struct SectionHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
        }
    }
}

struct GuidelineItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color(hex: "2563EB"))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EmergencyContactItem: View {
    let icon: String
    let title: String
    let phone: String
    var subInfo: String? = nil
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let subInfo = subInfo {
                    Text(subInfo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                callPhone(phone)
            } label: {
                Text(phone)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(hex: "2563EB"))
            }
        }
        .padding(.vertical, 8)
    }

    private func callPhone(_ number: String) {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
}

struct TipItem: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Color(hex: "2563EB"))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        TravelInfoView()
    }
}
