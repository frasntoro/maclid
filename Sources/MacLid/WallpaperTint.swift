import AppKit

/// Derives a tint colour from the desktop picture. `desktopImageURL` hands back
/// the wallpaper file path without any permission prompt, so this never asks the
/// user for screen access.
enum WallpaperTint {

    private static let thumbnailSize = 48

    static func dominantColor(for screen: NSScreen) -> NSColor? {
        guard let url = NSWorkspace.shared.desktopImageURL(for: screen),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: thumbnailSize
              ] as CFDictionary)
        else {
            return nil
        }
        return averageColor(of: thumbnail)
    }

    /// Hue is averaged as a vector (it wraps at 360°, so a plain mean is wrong)
    /// and weighted by saturation, so flat grey areas don't drag the result.
    private static func averageColor(of image: CGImage) -> NSColor? {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var hueX = 0.0
        var hueY = 0.0
        var saturationSum = 0.0
        var brightnessSum = 0.0
        var weight = 0.0

        for index in stride(from: 0, to: pixels.count, by: 4) {
            let color = NSColor(
                srgbRed: CGFloat(pixels[index]) / 255,
                green: CGFloat(pixels[index + 1]) / 255,
                blue: CGFloat(pixels[index + 2]) / 255,
                alpha: 1
            )

            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

            let pixelWeight = Double(saturation)
            let angle = Double(hue) * 2 * .pi
            hueX += cos(angle) * pixelWeight
            hueY += sin(angle) * pixelWeight
            saturationSum += Double(saturation)
            brightnessSum += Double(brightness)
            weight += pixelWeight
        }

        let pixelCount = Double(pixels.count / 4)
        guard pixelCount > 0 else { return nil }

        // An almost colourless wallpaper gives nothing worth tinting with.
        guard weight > pixelCount * 0.04 else { return nil }

        var meanHue = atan2(hueY, hueX) / (2 * .pi)
        if meanHue < 0 { meanHue += 1 }

        let meanSaturation = min(max(saturationSum / pixelCount, 0.3), 0.85)
        let meanBrightness = min(max(brightnessSum / pixelCount, 0.45), 0.95)

        return NSColor(
            hue: CGFloat(meanHue),
            saturation: CGFloat(meanSaturation),
            brightness: CGFloat(meanBrightness),
            alpha: 1
        )
    }
}
