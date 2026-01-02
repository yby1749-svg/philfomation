//
//  HapticManager.swift
//  Philfomation
//

import UIKit
import SwiftUI

final class HapticManager {
    static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private init() {
        // Prepare generators for faster response
        prepareAll()
    }

    func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }

    // MARK: - Impact Feedback

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            lightImpact.impactOccurred()
        case .medium:
            mediumImpact.impactOccurred()
        case .heavy:
            heavyImpact.impactOccurred()
        case .soft:
            softImpact.impactOccurred()
        case .rigid:
            rigidImpact.impactOccurred()
        @unknown default:
            mediumImpact.impactOccurred()
        }
    }

    func lightImpactOccurred() {
        lightImpact.impactOccurred()
    }

    func mediumImpactOccurred() {
        mediumImpact.impactOccurred()
    }

    func heavyImpactOccurred() {
        heavyImpact.impactOccurred()
    }

    // MARK: - Selection Feedback

    func selectionChanged() {
        selectionFeedback.selectionChanged()
    }

    // MARK: - Notification Feedback

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationFeedback.notificationOccurred(type)
    }

    func success() {
        notificationFeedback.notificationOccurred(.success)
    }

    func warning() {
        notificationFeedback.notificationOccurred(.warning)
    }

    func error() {
        notificationFeedback.notificationOccurred(.error)
    }
}

// MARK: - SwiftUI View Modifiers

struct HapticOnTap: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        HapticManager.shared.impact(style)
                    }
            )
    }
}

struct HapticOnChange<Value: Equatable>: ViewModifier {
    let value: Value
    let style: UIImpactFeedbackGenerator.FeedbackStyle

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _ in
                HapticManager.shared.impact(style)
            }
    }
}

extension View {
    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        modifier(HapticOnTap(style: style))
    }

    func hapticOnChange<Value: Equatable>(of value: Value, style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        modifier(HapticOnChange(value: value, style: style))
    }

    func hapticSelection() -> some View {
        simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticManager.shared.selectionChanged()
                }
        )
    }
}
