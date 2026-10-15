import AppKit
import Foundation

func renderSymbolIcon(name: String, size: CGFloat, pointSize: CGFloat, filename: String) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    // Transparent background
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
    if let sym = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let symSize = sym.size
        let rect = NSRect(x: (size - symSize.width) / 2.0, y: (size - symSize.height) / 2.0, width: symSize.width, height: symSize.height)
        sym.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: filename))
    print("✅ Generated: \(filename)")
}

let actionDir = "iOS/KamusActionExtension"
let assetDir = "\(actionDir)/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: assetDir, withIntermediateDirectories: true, attributes: nil)

// character.book.closed: Apple'ın yerel Sözlük (Dictionary) SF Symbol ikonu
let symbolName = "character.book.closed"

renderSymbolIcon(name: symbolName, size: 60, pointSize: 28, filename: "\(actionDir)/ActionIcon.png")
renderSymbolIcon(name: symbolName, size: 120, pointSize: 56, filename: "\(actionDir)/ActionIcon@2x.png")
renderSymbolIcon(name: symbolName, size: 180, pointSize: 84, filename: "\(actionDir)/ActionIcon@3x.png")

renderSymbolIcon(name: symbolName, size: 120, pointSize: 56, filename: "\(assetDir)/icon-60@2x.png")
renderSymbolIcon(name: symbolName, size: 180, pointSize: 84, filename: "\(assetDir)/icon-60@3x.png")
