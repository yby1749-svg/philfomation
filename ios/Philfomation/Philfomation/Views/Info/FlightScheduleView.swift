//
//  FlightScheduleView.swift
//  Philfomation
//

import SwiftUI

struct FlightScheduleView: View {
    @State private var selectedRoute: FlightRoute = .koreaToPhilippines

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Route Selector
                Picker("", selection: $selectedRoute) {
                    ForEach(FlightRoute.allCases, id: \.self) { route in
                        Text(route.title).tag(route)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Flight List
                if selectedRoute == .koreaToPhilippines {
                    KoreaToPhilippinesFlights()
                } else {
                    PhilippinesToKoreaFlights()
                }

                // Info Section
                FlightInfoSection()
            }
            .padding(.vertical)
        }
        .navigationTitle("항공 스케줄")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Flight Route
enum FlightRoute: CaseIterable {
    case koreaToPhilippines
    case philippinesToKorea

    var title: String {
        switch self {
        case .koreaToPhilippines: return "한국 → 필리핀"
        case .philippinesToKorea: return "필리핀 → 한국"
        }
    }
}

// MARK: - Korea to Philippines Flights
struct KoreaToPhilippinesFlights: View {
    var body: some View {
        VStack(spacing: 16) {
            // Manila (MNL)
            FlightDestinationSection(
                destination: "마닐라 (MNL)",
                flag: "🇵🇭",
                flights: [
                    FlightInfo(airline: "대한항공", flightNo: "KE621", departure: "08:30", arrival: "12:00", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "대한항공", flightNo: "KE623", departure: "19:00", arrival: "22:30", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "아시아나", flightNo: "OZ701", departure: "09:00", arrival: "12:30", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "필리핀항공", flightNo: "PR469", departure: "10:00", arrival: "13:30", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "세부퍼시픽", flightNo: "5J189", departure: "01:30", arrival: "05:00", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "진에어", flightNo: "LJ201", departure: "07:00", arrival: "10:30", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "제주항공", flightNo: "7C2601", departure: "08:00", arrival: "11:30", duration: "4시간 30분", frequency: "매일")
                ]
            )

            // Cebu (CEB)
            FlightDestinationSection(
                destination: "세부 (CEB)",
                flag: "🇵🇭",
                flights: [
                    FlightInfo(airline: "대한항공", flightNo: "KE631", departure: "08:00", arrival: "11:50", duration: "4시간 50분", frequency: "매일"),
                    FlightInfo(airline: "필리핀항공", flightNo: "PR479", departure: "09:30", arrival: "13:20", duration: "4시간 50분", frequency: "매일"),
                    FlightInfo(airline: "세부퍼시픽", flightNo: "5J191", departure: "02:00", arrival: "05:50", duration: "4시간 50분", frequency: "매일"),
                    FlightInfo(airline: "진에어", flightNo: "LJ211", departure: "07:30", arrival: "11:20", duration: "4시간 50분", frequency: "매일")
                ]
            )

            // Clark (CRK)
            FlightDestinationSection(
                destination: "클락 (CRK)",
                flag: "🇵🇭",
                flights: [
                    FlightInfo(airline: "세부퍼시픽", flightNo: "5J195", departure: "03:00", arrival: "06:20", duration: "4시간 20분", frequency: "주 4회"),
                    FlightInfo(airline: "진에어", flightNo: "LJ215", departure: "08:00", arrival: "11:20", duration: "4시간 20분", frequency: "주 3회")
                ]
            )

            // Boracay/Kalibo (KLO)
            FlightDestinationSection(
                destination: "보라카이/칼리보 (KLO)",
                flag: "🇵🇭",
                flights: [
                    FlightInfo(airline: "필리핀항공", flightNo: "PR485", departure: "08:30", arrival: "12:30", duration: "5시간", frequency: "주 5회"),
                    FlightInfo(airline: "진에어", flightNo: "LJ221", departure: "09:00", arrival: "13:00", duration: "5시간", frequency: "주 4회")
                ]
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Philippines to Korea Flights
struct PhilippinesToKoreaFlights: View {
    var body: some View {
        VStack(spacing: 16) {
            // Manila (MNL)
            FlightDestinationSection(
                destination: "마닐라 (MNL) → 인천",
                flag: "🇰🇷",
                flights: [
                    FlightInfo(airline: "대한항공", flightNo: "KE622", departure: "13:30", arrival: "19:00", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "대한항공", flightNo: "KE624", departure: "23:55", arrival: "05:25+1", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "아시아나", flightNo: "OZ702", departure: "14:00", arrival: "19:30", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "필리핀항공", flightNo: "PR468", departure: "15:00", arrival: "20:30", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "세부퍼시픽", flightNo: "5J188", departure: "19:30", arrival: "01:00+1", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "진에어", flightNo: "LJ202", departure: "12:00", arrival: "17:30", duration: "4시간 30분", frequency: "매일"),
                    FlightInfo(airline: "제주항공", flightNo: "7C2602", departure: "13:00", arrival: "18:30", duration: "4시간 30분", frequency: "매일")
                ]
            )

            // Cebu (CEB)
            FlightDestinationSection(
                destination: "세부 (CEB) → 인천",
                flag: "🇰🇷",
                flights: [
                    FlightInfo(airline: "대한항공", flightNo: "KE632", departure: "13:20", arrival: "19:10", duration: "4시간 50분", frequency: "매일"),
                    FlightInfo(airline: "필리핀항공", flightNo: "PR478", departure: "14:50", arrival: "20:40", duration: "4시간 50분", frequency: "매일"),
                    FlightInfo(airline: "세부퍼시픽", flightNo: "5J190", departure: "20:00", arrival: "01:50+1", duration: "4시간 50분", frequency: "매일"),
                    FlightInfo(airline: "진에어", flightNo: "LJ212", departure: "12:50", arrival: "18:40", duration: "4시간 50분", frequency: "매일")
                ]
            )

            // Clark (CRK)
            FlightDestinationSection(
                destination: "클락 (CRK) → 인천",
                flag: "🇰🇷",
                flights: [
                    FlightInfo(airline: "세부퍼시픽", flightNo: "5J194", departure: "21:00", arrival: "02:20+1", duration: "4시간 20분", frequency: "주 4회"),
                    FlightInfo(airline: "진에어", flightNo: "LJ216", departure: "12:50", arrival: "18:10", duration: "4시간 20분", frequency: "주 3회")
                ]
            )

            // Boracay/Kalibo (KLO)
            FlightDestinationSection(
                destination: "보라카이/칼리보 (KLO) → 인천",
                flag: "🇰🇷",
                flights: [
                    FlightInfo(airline: "필리핀항공", flightNo: "PR484", departure: "14:00", arrival: "19:00", duration: "5시간", frequency: "주 5회"),
                    FlightInfo(airline: "진에어", flightNo: "LJ222", departure: "14:30", arrival: "19:30", duration: "5시간", frequency: "주 4회")
                ]
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Flight Destination Section
struct FlightDestinationSection: View {
    let destination: String
    let flag: String
    let flights: [FlightInfo]
    @State private var isExpanded = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(flag)
                        .font(.title2)
                    Text(destination)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(flights.count)편")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                VStack(spacing: 0) {
                    ForEach(flights.indices, id: \.self) { index in
                        FlightRow(flight: flights[index])

                        if index < flights.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Flight Info
struct FlightInfo {
    let airline: String
    let flightNo: String
    let departure: String
    let arrival: String
    let duration: String
    let frequency: String

    var airlineColor: Color {
        switch airline {
        case "대한항공": return Color(hex: "0064D2")
        case "아시아나": return Color(hex: "C4161C")
        case "필리핀항공": return Color(hex: "0033A0")
        case "세부퍼시픽": return Color(hex: "FFD700")
        case "진에어": return Color(hex: "FF6600")
        case "제주항공": return Color(hex: "FF5722")
        default: return .gray
        }
    }

    var airlineShort: String {
        switch airline {
        case "대한항공": return "KE"
        case "아시아나": return "OZ"
        case "필리핀항공": return "PR"
        case "세부퍼시픽": return "5J"
        case "진에어": return "LJ"
        case "제주항공": return "7C"
        default: return "--"
        }
    }
}

struct FlightRow: View {
    let flight: FlightInfo

    var body: some View {
        HStack(spacing: 12) {
            // Airline Logo
            Text(flight.airlineShort)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(flight.airlineColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Flight Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(flight.airline)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(flight.flightNo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Text(flight.departure)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(flight.arrival)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("(\(flight.duration))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Frequency
            Text(flight.frequency)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
        }
        .padding()
    }
}

// MARK: - Flight Info Section
struct FlightInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text("안내 사항")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                FlightInfoRow(icon: "clock.fill", text: "스케줄은 항공사 사정에 따라 변경될 수 있습니다.")
                FlightInfoRow(icon: "calendar", text: "정확한 스케줄은 각 항공사 웹사이트에서 확인하세요.")
                FlightInfoRow(icon: "airplane.departure", text: "출발 시간은 현지 시간 기준입니다.")
                FlightInfoRow(icon: "plus.circle.fill", text: "+1은 다음 날 도착을 의미합니다.")
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
}

struct FlightInfoRow: View {
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

#Preview {
    NavigationStack {
        FlightScheduleView()
    }
}
