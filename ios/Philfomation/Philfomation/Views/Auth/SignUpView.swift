//
//  SignUpView.swift
//  Philfomation
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }

    private var passwordError: String? {
        if password.isEmpty { return nil }
        if password.count < 6 { return "비밀번호는 6자리 이상이어야 합니다" }
        if !confirmPassword.isEmpty && password != confirmPassword {
            return "비밀번호가 일치하지 않습니다"
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color(hex: "2563EB"))

                    Text("회원가입")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Philfomation에 오신 것을 환영합니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Input Fields
                VStack(spacing: 16) {
                    CustomTextField(
                        icon: "person.fill",
                        placeholder: "이름",
                        text: $name
                    )

                    CustomTextField(
                        icon: "envelope.fill",
                        placeholder: "이메일",
                        text: $email,
                        keyboardType: .emailAddress
                    )

                    CustomSecureField(
                        icon: "lock.fill",
                        placeholder: "비밀번호 (6자리 이상)",
                        text: $password
                    )

                    CustomSecureField(
                        icon: "lock.fill",
                        placeholder: "비밀번호 확인",
                        text: $confirmPassword
                    )

                    if let error = passwordError {
                        Text(error)
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }

                // Error Message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }

                // Sign Up Button
                Button {
                    Task {
                        await authViewModel.signUp(email: email, password: password, name: name)
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("가입하기")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "2563EB"))
                .disabled(!isFormValid || authViewModel.isLoading)

                // Terms
                Text("가입하시면 서비스 이용약관 및 개인정보처리방침에 동의하게 됩니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(false)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
