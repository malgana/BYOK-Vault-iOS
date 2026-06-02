//
//  PlatformIconView.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 13.01.26.
//

import SwiftUI

struct PlatformIconView: View {
    let platform: Platform
    let size: CGFloat
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(platform: Platform, size: CGFloat = 40) {
        self.platform = platform
        self.size = size
    }
    
    var body: some View {
        Group {
            if let assetName = platform.assetIconName {
                // Иконка из Assets для предустановленных платформ
                Image(assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let iconData = platform.customIconData,
                      let uiImage = ImageHelper.imageFromData(iconData) {
                // Кастомная иконка пользователя
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Fallback - первая буква в цветном круге
                fallbackIcon
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
    
    private var fallbackIcon: some View {
        Group {
            if let fallbackImage = ImageHelper.generateFallbackIcon(for: platform.name) {
                Image(uiImage: fallbackImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // Крайний fallback
                ZStack {
                    Circle()
                        .fill(Color.gray)
                    Text(platform.name.prefix(1).uppercased())
                        .font(.system(size: size * 0.5, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

#Preview("С иконкой из Assets") {
    let platform = Platform(name: "Claude")
    return PlatformIconView(platform: platform, size: 60)
        .padding()
}

#Preview("Без иконки - fallback") {
    let platform = Platform(name: "Custom Platform")
    return PlatformIconView(platform: platform, size: 60)
        .padding()
}

#Preview("С кастомной иконкой") {
    let platform = Platform(name: "Test")
    // Генерируем тестовую иконку
    if let testImage = ImageHelper.generateFallbackIcon(for: "Test"),
       let testData = ImageHelper.convertToPNGData(testImage) {
        platform.customIconData = testData
    }
    return PlatformIconView(platform: platform, size: 60)
        .padding()
}
