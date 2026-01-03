//
//  ThemeManager.swift
//  Philfomation
//

import SwiftUI
import Combine

// MARK: - App Theme
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "시스템 설정"
        case .light: return "라이트 모드"
        case .dark: return "다크 모드"
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Accent Color Options
enum AccentColorOption: String, CaseIterable, Identifiable {
    case blue = "블루"
    case purple = "퍼플"
    case green = "그린"
    case orange = "오렌지"
    case pink = "핑크"
    case red = "레드"
    case teal = "틸"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return Color(hex: "2563EB")
        case .purple: return Color(hex: "7C3AED")
        case .green: return Color(hex: "059669")
        case .orange: return Color(hex: "F97316")
        case .pink: return Color(hex: "EC4899")
        case .red: return Color(hex: "EF4444")
        case .teal: return Color(hex: "14B8A6")
        }
    }

    var hexValue: String {
        switch self {
        case .blue: return "2563EB"
        case .purple: return "7C3AED"
        case .green: return "059669"
        case .orange: return "F97316"
        case .pink: return "EC4899"
        case .red: return "EF4444"
        case .teal: return "14B8A6"
        }
    }
}

// MARK: - Font Size Options
enum FontSizeOption: String, CaseIterable, Identifiable {
    case small = "작게"
    case medium = "보통"
    case large = "크게"
    case extraLarge = "아주 크게"

    var id: String { rawValue }

    var scale: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        }
    }

    var bodySize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 17
        case .large: return 20
        case .extraLarge: return 24
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("accentColor") private var accentColorRaw: String = AccentColorOption.blue.rawValue
    @AppStorage("fontSize") private var fontSizeRaw: String = FontSizeOption.medium.rawValue

    @Published var currentTheme: AppTheme = .system
    @Published var accentColor: AccentColorOption = .blue
    @Published var fontSize: FontSizeOption = .medium

    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }

    var currentAccentColor: Color {
        accentColor.color
    }

    private init() {
        currentTheme = AppTheme(rawValue: selectedThemeRaw) ?? .system
        accentColor = AccentColorOption(rawValue: accentColorRaw) ?? .blue
        fontSize = FontSizeOption(rawValue: fontSizeRaw) ?? .medium
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        selectedThemeRaw = theme.rawValue
    }

    func setAccentColor(_ color: AccentColorOption) {
        accentColor = color
        accentColorRaw = color.rawValue
    }

    func setFontSize(_ size: FontSizeOption) {
        fontSize = size
        fontSizeRaw = size.rawValue
    }
}

// MARK: - View Extension for Theme
extension View {
    func applyTheme(_ themeManager: ThemeManager) -> some View {
        self
            .tint(themeManager.currentAccentColor)
            .preferredColorScheme(themeManager.colorScheme)
    }
}
