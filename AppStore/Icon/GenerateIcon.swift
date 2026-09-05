// Renders the WatchNext app icon with CoreGraphics so it can be regenerated
// deterministically. Usage:
//   swiftc -O -o /tmp/genicon GenerateIcon.swift && /tmp/genicon <output dir>
// Produces icon-1024.png (variant A) plus variants/ and a contact sheet.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Palette {
    let top: CGColor
    let bottom: CGColor
    let glyph: CGColor
    let accent: CGColor
}

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let palettes: [(name: String, palette: Palette)] = [
    // A: midnight indigo → electric blue, white glyph, orange "next" bar (the widget's upcoming tint).
    ("A-indigo", Palette(top: color(0x1B1F4B), bottom: color(0x3559E0), glyph: color(0xFFFFFF), accent: color(0xFF9F0A))),
    // B: deep teal → green, white glyph, warm accent. Echoes the "Ready" green.
    ("B-teal", Palette(top: color(0x0B3C49), bottom: color(0x1FA37A), glyph: color(0xFFFFFF), accent: color(0xFFD60A))),
    // C: near-black charcoal → graphite, white glyph, orange accent. Cinema-dark.
    ("C-charcoal", Palette(top: color(0x141416), bottom: color(0x3A3A42), glyph: color(0xFFFFFF), accent: color(0xFF9F0A)))
]

/// Draws the icon into a square context of the given side.
func draw(_ palette: Palette, side: CGFloat, in ctx: CGContext, rounded: Bool) {
    let rect = CGRect(x: 0, y: 0, width: side, height: side)
    if rounded {
        let path = CGPath(roundedRect: rect, cornerWidth: side * 0.2237, cornerHeight: side * 0.2237, transform: nil)
        ctx.addPath(path)
        ctx.clip()
    }

    // Background: diagonal gradient.
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let gradient = CGGradient(colorsSpace: space, colors: [palette.top, palette.bottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: side), end: CGPoint(x: side, y: 0), options: [])

    // Soft highlight in the upper left so the surface reads as glass.
    let highlight = CGGradient(
        colorsSpace: space,
        colors: [color(0xFFFFFF, alpha: 0.18), color(0xFFFFFF, alpha: 0)] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        highlight,
        startCenter: CGPoint(x: side * 0.25, y: side * 0.8), startRadius: 0,
        endCenter: CGPoint(x: side * 0.25, y: side * 0.8), endRadius: side * 0.75,
        options: []
    )

    // Glyph: "skip to next" — a play triangle with a rounded bar. Centered as a
    // group; the triangle's visual weight sits left, the bar closes it on the right.
    let s = side
    let glyphWidth = s * 0.52
    let originX = (s - glyphWidth) / 2 + s * 0.015
    let triangleWidth = s * 0.36
    let triangleHeight = s * 0.40
    let centerY = s * 0.5
    let radius = s * 0.045

    // Triangle with rounded corners: build from three points via a stroked+filled path.
    let p1 = CGPoint(x: originX, y: centerY + triangleHeight / 2)
    let p2 = CGPoint(x: originX, y: centerY - triangleHeight / 2)
    let p3 = CGPoint(x: originX + triangleWidth, y: centerY)
    let triangle = CGMutablePath()
    triangle.move(to: p1)
    triangle.addLine(to: p2)
    triangle.addLine(to: p3)
    triangle.closeSubpath()
    ctx.setFillColor(palette.glyph)
    ctx.setStrokeColor(palette.glyph)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(radius * 2)
    ctx.addPath(triangle)
    ctx.drawPath(using: .fillStroke)

    // Shadow under glyph for depth.
    // Bar: rounded capsule.
    let barWidth = s * 0.075
    let barHeight = triangleHeight + radius * 2
    let barX = originX + glyphWidth - barWidth
    let bar = CGPath(
        roundedRect: CGRect(x: barX, y: centerY - barHeight / 2, width: barWidth, height: barHeight),
        cornerWidth: barWidth / 2, cornerHeight: barWidth / 2, transform: nil
    )
    ctx.setFillColor(palette.accent)
    ctx.addPath(bar)
    ctx.fillPath()
}

func render(_ palette: Palette, side: Int, rounded: Bool) -> CGImage {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(
        data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    draw(palette, side: CGFloat(side), in: ctx, rounded: rounded)
    return ctx.makeImage()!
}

func write(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

/// Contact sheet: each variant at 1024-equivalent 180, 120, 60 px with rounded corners on a light and a dark ground.
func contactSheet() -> CGImage {
    let width = 3 * 420, height = 2 * 260
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    for (row, ground) in [color(0xF2F2F7), color(0x1C1C1E)].enumerated() {
        ctx.setFillColor(ground)
        ctx.fill(CGRect(x: 0, y: row == 0 ? height / 2 : 0, width: width, height: height / 2))
    }
    for (column, entry) in palettes.enumerated() {
        for (row, _) in [0, 1].enumerated() {
            var x = CGFloat(column * 420 + 20)
            let baseY = CGFloat(row == 0 ? height / 2 : 0) + 40
            for size in [180, 120, 60] {
                let img = render(entry.palette, side: size, rounded: true)
                ctx.draw(img, in: CGRect(x: x, y: baseY, width: CGFloat(size), height: CGFloat(size)))
                x += CGFloat(size) + 20
            }
        }
    }
    return ctx.makeImage()!
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
try? FileManager.default.createDirectory(at: out.appendingPathComponent("variants"), withIntermediateDirectories: true)
for entry in palettes {
    write(render(entry.palette, side: 1024, rounded: false), to: out.appendingPathComponent("variants/icon-1024-\(entry.name).png"))
    write(render(entry.palette, side: 512, rounded: true), to: out.appendingPathComponent("variants/preview-rounded-\(entry.name).png"))
}
write(render(palettes[0].palette, side: 1024, rounded: false), to: out.appendingPathComponent("icon-1024.png"))
write(contactSheet(), to: out.appendingPathComponent("contact-sheet.png"))
print("wrote icons to \(out.path)")
