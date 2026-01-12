//
//  ImageHelper.swift
//  KeyVault
//
//  Created by Aleksandr Prostetsov on 13.01.26.
//

import UIKit
import SwiftUI

enum ImageHelper {
    /// Сжимает изображение до 250x250px с сохранением пропорций
    static func resizeImage(_ image: UIImage, to size: CGSize = CGSize(width: 250, height: 250)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Конвертирует UIImage в PNG Data
    static func convertToPNGData(_ image: UIImage) -> Data? {
        return image.pngData()
    }
    
    /// Обрабатывает загруженное изображение: сжимает и конвертирует в Data
    static func processImage(_ image: UIImage) -> Data? {
        guard let resized = resizeImage(image) else { return nil }
        return convertToPNGData(resized)
    }
    
    /// Создает UIImage из Data
    static func imageFromData(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    /// Генерирует fallback изображение с первой буквой названия
    static func generateFallbackIcon(for text: String, size: CGSize = CGSize(width: 250, height: 250)) -> UIImage? {
        let firstLetter = text.prefix(1).uppercased()
        let color = colorForString(text)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Фон круга
            color.setFill()
            let rect = CGRect(origin: .zero, size: size)
            context.cgContext.fillEllipse(in: rect)
            
            // Текст
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.5, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = firstLetter.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            firstLetter.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    /// Генерирует цвет на основе строки (детерминированно)
    private static func colorForString(_ string: String) -> UIColor {
        let colors: [UIColor] = [
            .systemBlue, .systemGreen, .systemIndigo, .systemOrange,
            .systemPink, .systemPurple, .systemRed, .systemTeal,
            .systemYellow, .systemCyan, .systemMint, .systemBrown
        ]
        
        let hash = abs(string.hashValue)
        let index = hash % colors.count
        return colors[index]
    }
}
