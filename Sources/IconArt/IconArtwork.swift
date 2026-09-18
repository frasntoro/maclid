import CoreGraphics
import CoreImage
import Foundation

/// The MacLid icon, drawn in code so the generator and the app's About tab
/// always show exactly the same artwork.
///
/// The artwork is the effect itself: hard-edged diagonal bands that stay sharp
/// at the bottom and melt at the top. The crisp edges matter — blurring
/// something already soft reads as nothing at all.
public enum IconArtwork {

    /// Space gray body with Apple's system colours on the screen.
    private enum Palette {
        static let backgroundTop = CGColor(red: 0.255, green: 0.267, blue: 0.290, alpha: 1)
        static let backgroundBottom = CGColor(red: 0.129, green: 0.137, blue: 0.157, alpha: 1)
        static let screenBase = CGColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1)
        static let purple = CGColor(red: 0.686, green: 0.322, blue: 0.871, alpha: 1)
        static let blue = CGColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1)
        static let teal = CGColor(red: 0.188, green: 0.690, blue: 0.780, alpha: 1)
        static let pink = CGColor(red: 1.0, green: 0.176, blue: 0.333, alpha: 1)
        static let deck = CGColor(red: 0.722, green: 0.737, blue: 0.765, alpha: 1)
    }

    private static let canvas: CGFloat = 1024

    private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

    /// Cached because the About tab and the generator both ask for it, and the
    /// Gaussian blur is the expensive part.
    private static let master: CGImage = drawMaster()

    /// Artwork rendered at an arbitrary square size.
    public static func image(size: Int) -> CGImage {
        guard size != Int(canvas) else { return master }

        let context = makeContext(width: size, height: size)
        context.interpolationQuality = .high
        context.draw(master, in: CGRect(x: 0, y: 0, width: size, height: size))
        return context.makeImage()!
    }

    /// Menu bar glyph: a lid caught mid-close, seen from the side. Drawn as a
    /// black-on-transparent template, so macOS recolours it for light and dark
    /// menu bars by itself.
    public static func menuBarGlyph(size: CGFloat) -> CGImage {
        let side = Int(size)
        let context = makeContext(width: side, height: side)
        let unit = size / 18

        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(1.6 * unit)

        // The deck, and the lid leaning over it from the hinge on the left.
        context.move(to: CGPoint(x: 2.6 * unit, y: 4.4 * unit))
        context.addLine(to: CGPoint(x: 15.4 * unit, y: 4.4 * unit))
        context.strokePath()

        context.move(to: CGPoint(x: 4.0 * unit, y: 5.2 * unit))
        context.addLine(to: CGPoint(x: 12.6 * unit, y: 14.2 * unit))
        context.strokePath()

        // Two short strokes trailing the lid: the blur it leaves behind.
        context.setLineWidth(1.1 * unit)
        context.setAlpha(0.55)
        context.move(to: CGPoint(x: 6.6 * unit, y: 5.2 * unit))
        context.addLine(to: CGPoint(x: 14.2 * unit, y: 12.0 * unit))
        context.strokePath()

        context.setAlpha(0.28)
        context.move(to: CGPoint(x: 9.4 * unit, y: 5.2 * unit))
        context.addLine(to: CGPoint(x: 15.6 * unit, y: 9.6 * unit))
        context.strokePath()

        return context.makeImage()!
    }

    private static func makeContext(width: Int, height: Int) -> CGContext {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: sRGB,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            fatalError("Could not create the graphics context")
        }
        return context
    }

    private static func drawMaster() -> CGImage {
        let context = makeContext(width: Int(canvas), height: Int(canvas))

        // Rounded-square body, following Apple's proportions for macOS icons.
        let body = CGRect(x: 100, y: 100, width: 824, height: 824)

        context.saveGState()
        context.addPath(CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil))
        context.clip()

        if let background = CGGradient(
            colorsSpace: sRGB,
            colors: [Palette.backgroundTop, Palette.backgroundBottom] as CFArray,
            locations: [0, 1]
        ) {
            context.drawLinearGradient(
                background,
                start: CGPoint(x: body.midX, y: body.maxY),
                end: CGPoint(x: body.midX, y: body.minY),
                options: []
            )
        }

        let screenRect = CGRect(x: 252, y: 364, width: 520, height: 352)
        let artwork = makeBands(size: screenRect.size)
        let blurredArtwork = blurred(artwork, radius: 58)
        let mask = makeBlurMask(size: screenRect.size)
        let screenPath = CGPath(roundedRect: screenRect, cornerWidth: 44, cornerHeight: 44, transform: nil)

        context.saveGState()
        context.addPath(screenPath)
        context.clip()

        // Sharp underneath, blurred on top through the soft mask: the app's own trick.
        context.draw(artwork, in: screenRect)
        context.saveGState()
        context.clip(to: screenRect, mask: mask)
        context.draw(blurredArtwork, in: screenRect)
        context.restoreGState()
        context.restoreGState()

        // Hairline edge so the screen reads as a panel, not a hole.
        context.setStrokeColor(CGColor(gray: 1, alpha: 0.14))
        context.setLineWidth(3)
        context.addPath(screenPath)
        context.strokePath()

        // The deck the lid closes onto: dim, so it frames the screen instead of
        // competing with it.
        let deckRect = CGRect(x: 212, y: 308, width: 600, height: 26)
        context.setFillColor(Palette.deck)
        context.addPath(CGPath(roundedRect: deckRect, cornerWidth: 13, cornerHeight: 13, transform: nil))
        context.fillPath()

        context.restoreGState()

        return context.makeImage()!
    }

    private static func makeBands(size: CGSize) -> CGImage {
        let context = makeContext(width: Int(size.width), height: Int(size.height))

        context.setFillColor(Palette.screenBase)
        context.fill(CGRect(origin: .zero, size: size))

        let bands = [Palette.purple, Palette.blue, Palette.teal, Palette.pink]
        let diagonal = sqrt(size.width * size.width + size.height * size.height)
        let bandWidth = diagonal / CGFloat(bands.count)

        context.saveGState()
        context.translateBy(x: size.width / 2, y: size.height / 2)
        context.rotate(by: -.pi / 9)
        context.translateBy(x: -diagonal / 2, y: -diagonal / 2)

        for (index, color) in bands.enumerated() {
            context.setFillColor(color)
            context.fill(CGRect(x: CGFloat(index) * bandWidth, y: 0, width: bandWidth, height: diagonal))
        }
        context.restoreGState()

        return context.makeImage()!
    }

    private static func blurred(_ image: CGImage, radius: CGFloat) -> CGImage {
        let ciImage = CIImage(cgImage: image)
        let filter = CIFilter(name: "CIGaussianBlur")!
        // Clamping first keeps the blur from fading out at the edges.
        filter.setValue(ciImage.clampedToExtent(), forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)

        let output = filter.outputImage!.cropped(to: ciImage.extent)
        return CIContext().createCGImage(output, from: ciImage.extent)!
    }

    /// Grayscale mask: white where the blurred copy shows (top), black where the
    /// sharp one does (bottom), with a wide soft band between them.
    private static func makeBlurMask(size: CGSize) -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            fatalError("Could not create the mask context")
        }

        let gray = CGColorSpaceCreateDeviceGray()
        guard let gradient = CGGradient(
            colorsSpace: gray,
            colors: [
                CGColor(gray: 1, alpha: 1),
                CGColor(gray: 1, alpha: 1),
                CGColor(gray: 0, alpha: 1),
                CGColor(gray: 0, alpha: 1)
            ] as CFArray,
            locations: [0, 0.10, 0.74, 1]
        ) else {
            fatalError("Could not create the mask gradient")
        }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: size.width / 2, y: size.height),
            end: CGPoint(x: size.width / 2, y: 0),
            options: []
        )
        return context.makeImage()!
    }
}
