import Foundation
import AppKit
import SwiftUI

struct AppResult: Identifiable, Equatable {
    let id: URL
    let name: String
    let lowercasedName: String
    let acronym: String
    let icon: NSImage
    let url: URL
    var score: Int = 0 // usage score + search match score
    let averageColor: Color
    
    // Equatable conformance
    static func == (lhs: AppResult, rhs: AppResult) -> Bool {
        return lhs.id == rhs.id
    }
}

extension NSImage {
    func getAverageColor() -> Color {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return Color.clear
        }

        let size = CGSize(width: 1, height: 1)
        let rect = CGRect(origin: .zero, size: size)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        
        var pixelData: [UInt8] = [0, 0, 0, 0]
        
        guard let context = CGContext(
            data: &pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return Color.clear
        }
        
        context.draw(cgImage, in: rect)
        
        let r = Double(pixelData[0]) / 255.0
        let g = Double(pixelData[1]) / 255.0
        let b = Double(pixelData[2]) / 255.0
        let a = Double(pixelData[3]) / 255.0
        
        // If the pixel is fully transparent, fallback to clear
        if a == 0 {
            return Color.clear
        }
        
        // Un-premultiply alpha
        return Color(red: r / a, green: g / a, blue: b / a, opacity: a)
    }
}
