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

    // Büyütülmüş 'a' harfi (size * 0.65)
    let font = NSFont(name: "Georgia-Bold", size: size * 0.65) ?? NSFont.boldSystemFont(ofSize: size * 0.65)
    let text = "a" as NSString
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.black
    ]
    let strSize = text.size(withAttributes: attrs)

    // Şapka ölçüleri: 'a' harfine çok daha yakın ve orantılı
    let xHeight = font.xHeight
    let cxHeight = xHeight * 0.36
    let cxWidth = strSize.width * 0.66
    let gap = xHeight * 0.10 // Şapka 'a' harfine yaklaştırıldı
    let cxThick = max(size * 0.065, 3.0)

    let totalVisualH = xHeight + gap + cxHeight
    let yBottom = (size - totalVisualH) / 2.0 - xHeight * 0.05
    let midX = size / 2.0
    let aX = (size - strSize.width) / 2.0

    // Harfi çiz
    text.draw(at: NSPoint(x: aX, y: yBottom), withAttributes: attrs)

    // Şapkayı çiz
    let apexY = yBottom + xHeight + gap + cxHeight - cxThick / 2.0
    let baseHatY = yBottom + xHeight + gap + cxThick / 2.0

    let path = NSBezierPath()
    path.lineWidth = cxThick
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.move(to: NSPoint(x: midX - cxWidth / 2.0, y: baseHatY))
    path.line(to: NSPoint(x: midX, y: apexY))
    path.line(to: NSPoint(x: midX + cxWidth / 2.0, y: baseHatY))
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
