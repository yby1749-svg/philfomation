//
//  LoginView.swift
//  Philfomation
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showResetPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    // Logo
                    LogoView()

                    Spacer(minLength: 20)

                    // Input Fields
                    VStack(spacing: 16) {
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "이메일",
                            text: $email,
                            keyboardType: .emailAddress
                        )

                        CustomSecureField(
                            icon: "lock.fill",
                            placeholder: "비밀번호",
                            text: $password
                        )
                    }

                    // Error Message
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    // Login Button
                    Button {
                        Task {
                            await authViewModel.signIn(email: email, password: password)
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("로그인")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "2563EB"))
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)

                    // Forgot Password
                    Button("비밀번호를 잊으셨나요?") {
                        showResetPassword = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Divider()

                    // Sign Up
                    HStack {
                        Text("계정이 없으신가요?")
                            .foregroundStyle(.secondary)
                        Button("회원가입") {
                            showSignUp = true
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "2563EB"))
                    }
                    .font(.subheadline)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showResetPassword) {
                ResetPasswordView()
            }
        }
    }
}

struct ResetPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("비밀번호 재설정 링크를 이메일로 보내드립니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                CustomTextField(
                    icon: "envelope.fill",
                    placeholder: "이메일",
                    text: $email,
                    keyboardType: .emailAddress
                )

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button {
                    Task {
                        await authViewModel.resetPassword(email: email)
                        if authViewModel.errorMessage == nil {
                            showSuccess = true
                        }
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("재설정 링크 보내기")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "2563EB"))
                .disabled(email.isEmpty || authViewModel.isLoading)

                Spacer()
            }
            .padding(24)
            .navigationTitle("비밀번호 재설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("이메일 전송 완료", isPresented: $showSuccess) {
                Button("확인") { dismiss() }
            } message: {
                Text("비밀번호 재설정 링크가 이메일로 전송되었습니다.")
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
