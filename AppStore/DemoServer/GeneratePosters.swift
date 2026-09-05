// Generates fictional poster art for the demo server: a gradient, a shape, and
// the title's initials. Usage: swiftc -O -o /tmp/genposters GeneratePosters.swift && /tmp/genposters <out dir>
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let titles: [(slug: String, title: String, hue: CGFloat)] = [
    ("harbor-lights", "Harbor Lights", 0.58),
    ("the-cartographers", "The Cartographers", 0.08),
    ("ninefold-station", "Ninefold Station", 0.72),
    ("saltmarsh", "Saltmarsh", 0.36),
    ("paper-meridian", "Paper Meridian", 0.95),
    ("the-long-static", "The Long Static", 0.62),
    ("glasshouse-summer", "Glasshouse Summer", 0.15),
    ("vantablack-sonata", "Vantablack Sonata", 0.78),
    ("orbital-kitchen", "Orbital Kitchen", 0.48),
    ("copper-and-tide", "Copper and Tide", 0.04)
]

func hsl(_ h: CGFloat, _ s: CGFloat, _ l: CGFloat) -> CGColor {
    let c = (1 - abs(2 * l - 1)) * s
    let hp = h * 6
    let x = c * (1 - abs(hp.truncatingRemainder(dividingBy: 2) - 1))
    let (r1, g1, b1): (CGFloat, CGFloat, CGFloat)
    switch Int(hp) % 6 {
    case 0: (r1, g1, b1) = (c, x, 0)
    case 1: (r1, g1, b1) = (x, c, 0)
    case 2: (r1, g1, b1) = (0, c, x)
    case 3: (r1, g1, b1) = (0, x, c)
    case 4: (r1, g1, b1) = (x, 0, c)
    default: (r1, g1, b1) = (c, 0, x)
    }
    let m = l - c / 2
    return CGColor(srgbRed: r1 + m, green: g1 + m, blue: b1 + m, alpha: 1)
}

func initials(_ title: String) -> String {
    let words = title.split(separator: " ").filter { $0.lowercased() != "the" && $0.lowercased() != "and" }
    return words.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
}

func render(_ entry: (slug: String, title: String, hue: CGFloat)) -> CGImage {
    let w = 600, h = 900
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let g = CGGradient(colorsSpace: space, colors: [hsl(entry.hue, 0.55, 0.22), hsl(entry.hue + 0.08, 0.6, 0.45)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: CGFloat(h)), end: CGPoint(x: CGFloat(w), y: 0), options: [])
    // Decorative circle.
    ctx.setFillColor(hsl(entry.hue + 0.5, 0.5, 0.6).copy(alpha: 0.25)!)
    ctx.fillEllipse(in: CGRect(x: CGFloat(w) * 0.55, y: CGFloat(h) * 0.6, width: CGFloat(w) * 0.7, height: CGFloat(w) * 0.7))
    // Initials.
    let text = initials(entry.title)
    let font = CTFontCreateWithName("HelveticaNeue-Bold" as CFString, 260, nil)
    let attrs: [CFString: Any] = [kCTFontAttributeName: font, kCTForegroundColorAttributeName: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.95)]
    let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!)
    let bounds = CTLineGetBoundsWithOptions(line, [])
    ctx.textPosition = CGPoint(x: (CGFloat(w) - bounds.width) / 2, y: CGFloat(h) * 0.42)
    CTLineDraw(line, ctx)
    // Title strip.
    let small = CTFontCreateWithName("HelveticaNeue-Medium" as CFString, 40, nil)
    let sattrs: [CFString: Any] = [kCTFontAttributeName: small, kCTForegroundColorAttributeName: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.85)]
    let sline = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, entry.title.uppercased() as CFString, sattrs as CFDictionary)!)
    let sb = CTLineGetBoundsWithOptions(sline, [])
    ctx.textPosition = CGPoint(x: (CGFloat(w) - sb.width) / 2, y: CGFloat(h) * 0.12)
    CTLineDraw(sline, ctx)
    return ctx.makeImage()!
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
for entry in titles {
    let url = out.appendingPathComponent("\(entry.slug).png")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, render(entry), nil)
    CGImageDestinationFinalize(dest)
}
print("wrote \(titles.count) posters")
