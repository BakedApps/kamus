import AppKit
import Foundation

func makeBrandIcon(size: CGFloat, filename: String) {
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

    let font = NSFont(name: "Georgia-Bold", size: size * 0.52) ?? NSFont.boldSystemFont(ofSize: size * 0.52)
    let text = "a" as NSString
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.black
    ]
    let strSize = text.size(withAttributes: attrs)

    // Circumflex dimensions
    let cxWidth = strSize.width * 0.62
    let cxHeight = strSize.width * 0.24
    let cxThick = max(size * 0.05, 2.5)
    let gap = strSize.width * 0.10

    let totalH = cxHeight + gap + strSize.height
    let topY = (size + totalH) / 2.0

    let aX = (size - strSize.width) / 2.0
    let aY = topY - cxHeight - gap - strSize.height

    text.draw(at: NSPoint(x: aX, y: aY), withAttributes: attrs)

    // Draw circumflex in bottom-left origin
    let apexY = topY - cxThick / 2.0
    let midX = size / 2.0
    let path = NSBezierPath()
    path.lineWidth = cxThick
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.move(to: NSPoint(x: midX - cxWidth / 2.0, y: apexY - cxHeight))
    path.line(to: NSPoint(x: midX, y: apexY))
    path.line(to: NSPoint(x: midX + cxWidth / 2.0, y: apexY - cxHeight))
    NSColor.black.setStroke()
    path.stroke()

    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: filename))
    print("✅ Generated: \(filename)")
}

let actionDir = "iOS/KamusActionExtension"
let assetDir = "\(actionDir)/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: assetDir, withIntermediateDirectories: true, attributes: nil)

makeBrandIcon(size: 60, filename: "\(actionDir)/ActionIcon.png")
makeBrandIcon(size: 120, filename: "\(actionDir)/ActionIcon@2x.png")
makeBrandIcon(size: 180, filename: "\(actionDir)/ActionIcon@3x.png")

makeBrandIcon(size: 120, filename: "\(assetDir)/icon-60@2x.png")
makeBrandIcon(size: 180, filename: "\(assetDir)/icon-60@3x.png")
