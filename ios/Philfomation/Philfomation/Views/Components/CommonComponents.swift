//
//  CommonComponents.swift
//  Philfomation
//

import SwiftUI

// MARK: - Logo View

struct LogoView: View {
    var body: some View {
        VStack(spacing: 8) {
            // Logo Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "2563EB"))
                    .frame(width: 80, height: 80)

                // Network nodes representation
                Image(systemName: "network")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            Text("Philfomation")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text("Philippine Community Hub")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "2563EB"))
        }
    }
}

// MARK: - Custom Text Fields

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .keyboardType(keyboardType)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .autocapitalization(.none)
            .autocorrectionDisabled()

            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Async Profile Image

struct AsyncProfileImage: View {
    let url: String?
    let size: CGFloat

    var body: some View {
        if let url = url {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                placeholderView
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews

#Preview("Logo") {
    LogoView()
}

#Preview("Text Fields") {
    VStack(spacing: 16) {
        CustomTextField(icon: "envelope", placeholder: "이메일", text: .constant(""))
        CustomSecureField(icon: "lock", placeholder: "비밀번호", text: .constant(""))
    }
    .padding()
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "tray",
        title: "데이터가 없습니다",
        message: "아직 표시할 내용이 없습니다"
    )
}
