//
//  MaterialTheme.swift
//  KeyVault
//

import SwiftUI

// MARK: - Background

struct KeyVaultBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.1, green: 0.08, blue: 0.2),
                Color.black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Glass Surface

struct GlassBackground: View {
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
                                .white.opacity(0.3),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: .black.opacity(0.4),
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }
}

// MARK: - Toolbar Button

struct GlassCircleButton: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
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
