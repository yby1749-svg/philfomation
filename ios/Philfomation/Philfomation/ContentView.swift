//
//  ContentView.swift
//  Philfomation
//
//  Created by robin on 1/2/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if authViewModel.isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isLoggedIn)
        .animation(.easeInOut, value: hasCompletedOnboarding)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
