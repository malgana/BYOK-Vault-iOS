//
//  MaterialTheme.swift
//  KeyVault
//

import SwiftUI

// MARK: - Background

struct KeyVaultBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.08, blue: 0.2),
                    Color.black
                ]
                : [
                    Color(red: 0.95, green: 0.95, blue: 1.0),
                    Color(red: 0.9, green: 0.92, blue: 1.0),
                    Color(red: 0.85, green: 0.88, blue: 0.95)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass Surface

struct GlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var cornerRadius: CGFloat = 20
    var shadowRadius: CGFloat = 16
    var shadowY: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(colorScheme == .dark ? 0.3 : 0.6),
                                .white.opacity(colorScheme == .dark ? 0.1 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.4)
                    : .black.opacity(0.1),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }
}

// MARK: - Toolbar Button

struct GlassCircleButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.title3.weight(.semibold))
            .foregroundStyle(colorScheme == .dark ? .white : .black)
            .frame(width: 36, height: 36)
            .contentShape(Circle())
    }
}

// MARK: - View Modifiers

extension View {
    func keyVaultScreenBackground() -> some View {
        background {
            KeyVaultBackground()
                .ignoresSafeArea()
        }
    }

    func keyVaultNavigationStyle() -> some View {
        toolbarBackground(.hidden, for: .navigationBar)
    }

    func glassListRowBackground(cornerRadius: CGFloat = 12) -> some View {
        listRowBackground(
            Color.clear.background {
                GlassBackground(cornerRadius: cornerRadius, shadowRadius: 8, shadowY: 4)
            }
        )
    }

    func glassFormStyle() -> some View {
        scrollContentBackground(.hidden)
            .keyVaultScreenBackground()
    }
}

// MARK: - Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
