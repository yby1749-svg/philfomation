//
//  ThemeManager.swift
//  Philfomation
//

import SwiftUI
import Combine

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

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.system.rawValue

    @Published var currentTheme: AppTheme = .system

    var colorScheme: ColorScheme? {
        currentTheme.colorScheme
    }

    private init() {
        currentTheme = AppTheme(rawValue: selectedThemeRaw) ?? .system
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        selectedThemeRaw = theme.rawValue
    }
}
