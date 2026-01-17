//
//  MainView.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 12.01.26.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Platform.name) private var platforms: [Platform]
    @Query private var allKeys: [APIKey]
    @State private var showingAddKey = false
    @State private var appearAnimation = false
    
    private var platformsWithKeys: [Platform] {
        platforms.filter { !$0.apiKeys.isEmpty }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Градиентный фон
                backgroundGradient
                    .ignoresSafeArea()
                
                if platformsWithKeys.isEmpty {
                    emptyStateView
                } else {
                    platformsGrid
                }
            }
            .navigationTitle("API Keys")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddKey = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            }
            .sheet(isPresented: $showingAddKey) {
                AddKeyView()
            }
            .onAppear {
                cleanupEmptyPlatforms()
                withAnimation(.easeOut(duration: 0.5)) {
                    appearAnimation = true
                }
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.05, green: 0.05, blue: 0.15),
                   Color(red: 0.1, green: 0.08, blue: 0.2),
                   Color.black]
                : [Color(red: 0.95, green: 0.95, blue: 1.0),
                   Color(red: 0.9, green: 0.92, blue: 1.0),
                   Color(red: 0.85, green: 0.88, blue: 0.95)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Platforms Grid
    private var platformsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(platformsWithKeys.enumerated()), id: \.element.id) { index, platform in
                    NavigationLink {
                        destinationView(for: platform)
                    } label: {
                        GlassCard(platform: platform)
                    }
                    .buttonStyle(CardButtonStyle())
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(index) * 0.08),
                        value: appearAnimation
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "key.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            VStack(spacing: 8) {
                Text("Нет API ключей")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text("Добавьте первый ключ")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                showingAddKey = true
            } label: {
                Label("Добавить ключ", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
            }
        }
        .padding()
    }
    
    // MARK: - Cleanup
    private func cleanupEmptyPlatforms() {
        let emptyPlatforms = platforms.filter { platform in
            !platform.isDefault && platform.apiKeys.isEmpty
        }
        
        for platform in emptyPlatforms {
            modelContext.delete(platform)
        }
        
        if !emptyPlatforms.isEmpty {
            try? modelContext.save()
        }
    }
    
    @ViewBuilder
    private func destinationView(for platform: Platform) -> some View {
        if platform.apiKeys.count == 1, let key = platform.apiKeys.first {
            KeyDetailView(apiKey: key)
        } else {
            PlatformKeysListView(platform: platform)
        }
    }
}

// MARK: - Glass Card
struct GlassCard: View {
    let platform: Platform
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Иконка платформы
            PlatformIconView(platform: platform, size: 56)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 4) {
                Text(platform.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("\(platform.apiKeys.count) \(keysText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background {
            glassBackground
        }
    }
    
    private var glassBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
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
                radius: 16,
                x: 0,
                y: 8
            )
    }
    
    private var keysText: String {
        let count = platform.apiKeys.count
        if count == 1 {
            return "ключ"
        } else if count >= 2 && count <= 4 {
            return "ключа"
        } else {
            return "ключей"
        }
    }
}

// MARK: - Card Button Style
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Platform.self, APIKey.self], inMemory: true)
}
