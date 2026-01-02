//
//  ContentView.swift
//  Philfomation
//
//  Created by robin on 1/2/26.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)

                Text("로그인 성공!")
                    .font(.title)
                    .fontWeight(.bold)

                if let email = authManager.user?.email {
                    Text(email)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("홈")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("로그아웃") {
                        authManager.signOut()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
