//
//  LoginView.swift
//  Philfomation
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("Philfomation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Spacer()

                // Input Fields
                VStack(spacing: 16) {
                    TextField("이메일", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("비밀번호", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)
                }
                .padding(.horizontal)

                // Error Message
                if let error = authManager.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Login/SignUp Button
                Button {
                    Task {
                        if isSignUp {
                            await authManager.signUp(email: email, password: password)
                        } else {
                            await authManager.signIn(email: email, password: password)
                        }
                    }
                } label: {
                    if authManager.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    } else {
                        Text(isSignUp ? "회원가입" : "로그인")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)

                // Toggle SignUp/Login
                Button {
                    isSignUp.toggle()
                    authManager.errorMessage = nil
                } label: {
                    Text(isSignUp ? "이미 계정이 있으신가요? 로그인" : "계정이 없으신가요? 회원가입")
                        .font(.subheadline)
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
