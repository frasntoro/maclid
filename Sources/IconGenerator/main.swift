import AppKit
import IconArt

// Writes the full .iconset for MacLid. The artwork itself lives in IconArt, so
// the app's About tab draws exactly the same image.

func write(size: Int, to url: URL) {
    let rep = NSBitmapImageRep(cgImage: IconArtwork.image(size: size))
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode the PNG")
    }
    try! data.write(to: url)
}

let outputRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Resources")
let iconset = outputRoot.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(name: String, size: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for variant in variants {
    write(size: variant.size, to: iconset.appendingPathComponent("\(variant.name).png"))
}

// Full-size preview, handy for reviewing the artwork and for the README.
write(size: 1024, to: outputRoot.appendingPathComponent("AppIcon-preview.png"))

print("Iconset written to \(iconset.path)")

// Oversized menu bar glyph, for eyeballing the shape.
let glyphRep = NSBitmapImageRep(cgImage: IconArtwork.menuBarGlyph(size: 288))
if let glyphData = glyphRep.representation(using: .png, properties: [:]) {
    try! glyphData.write(to: outputRoot.appendingPathComponent("MenuBarGlyph-preview.png"))
}
