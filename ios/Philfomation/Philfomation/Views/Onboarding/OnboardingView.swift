//
//  OnboardingView.swift
//  Philfomation
//

import SwiftUI

// MARK: - Onboarding Page Model
struct OnboardingPage: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let subtitle: String
    let description: String
    let accentColor: Color
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "globe.asia.australia.fill",
            title: "Philfomation에\n오신 것을 환영합니다",
            subtitle: "Philippine Community Hub",
            description: "필리핀에 거주하거나 여행하는 한국인을 위한\n종합 커뮤니티 앱입니다",
            accentColor: Color(hex: "2563EB")
        ),
        OnboardingPage(
            imageName: "building.2.fill",
            title: "한인 업소 정보",
            subtitle: "주변 업소 찾기",
            description: "음식점, 마사지, 미용실 등\n한국인이 운영하는 업소를 쉽게 찾아보세요",
            accentColor: Color(hex: "7C3AED")
        ),
        OnboardingPage(
            imageName: "bubble.left.and.bubble.right.fill",
            title: "커뮤니티",
            subtitle: "정보 공유 & 소통",
            description: "맛집, 여행, 생활 정보를 공유하고\n다른 교민들과 소통하세요",
            accentColor: Color(hex: "059669")
        ),
        OnboardingPage(
            imageName: "wonsign.circle.fill",
            title: "환율 계산기",
            subtitle: "실시간 환율 정보",
            description: "KRW-PHP 실시간 환율을 확인하고\n간편하게 계산하세요",
            accentColor: Color(hex: "F59E0B")
        ),
        OnboardingPage(
            imageName: "checkmark.circle.fill",
            title: "시작할 준비가\n되셨나요?",
            subtitle: "Let's Get Started",
            description: "지금 바로 Philfomation을\n시작해보세요!",
            accentColor: Color(hex: "2563EB")
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    pages[currentPage].accentColor.opacity(0.1),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("건너뛰기") {
                            completeOnboarding()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].accentColor : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 30)

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("이전")
                            }
                            .font(.headline)
                            .foregroundStyle(pages[currentPage].accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(pages[currentPage].accentColor, lineWidth: 2)
                            )
                        }
                    }

                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "다음" : "시작하기")
                            if currentPage < pages.count - 1 {
                                Image(systemName: "chevron.right")
                            } else {
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(pages[currentPage].accentColor)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with animated background
            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.15))
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(page.accentColor.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: page.imageName)
                    .font(.system(size: 70))
                    .foregroundStyle(page.accentColor)
            }
            .padding(.bottom, 20)

            // Subtitle
            Text(page.subtitle)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(page.accentColor)
                .textCase(.uppercase)
                .tracking(1.5)

            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
}
