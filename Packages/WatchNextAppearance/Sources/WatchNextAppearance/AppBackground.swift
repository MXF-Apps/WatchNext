import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// A base color with an accent mesh gradient and film grain, so large empty
/// areas stop reading as flat while content keeps its contrast against `base`.
///
/// The grain is a tiled noise image rather than a Metal shader: shaders need
/// the Metal toolchain on every machine that builds the project, and widgets
/// cannot run them.
public struct AppBackground: View {
    private let settings: AppearanceSettings
    private let base: Color
    @Environment(\.colorScheme) private var colorScheme

    /// - Parameters:
    ///   - settings: texture strength and tint; `.off` draws the plain base.
    ///   - base: the surface color the content was designed against, for
    ///     example `systemGroupedBackground` in the app and the widget's
    ///     `secondarySystemGroupedBackground`.
    public init(settings: AppearanceSettings, base: Color) {
        self.settings = settings
        self.base = base
    }

    /// How far the warm and cool ends move away from the base (0 = none).
    private var tintAmount: Double {
        switch (settings.texture, colorScheme) {
        case (.off, _): 0
        case (.strong, .dark): 0.42
        case (.strong, _): 0.30
        case (.subtle, .dark): 0.26
        case (.subtle, _): 0.18
        }
    }

    /// Grain strength. Multiply darkens a light base and plus-lighter lifts a
    /// dark one; overlay would be invisible on pure black.
    private var grainOpacity: Double {
        switch (settings.texture, colorScheme) {
        case (.off, _): 0
        case (.strong, .dark): 0.20
        case (.strong, _): 0.18
        case (.subtle, .dark): 0.12
        case (.subtle, _): 0.11
        }
    }

    private var grainBlend: BlendMode { colorScheme == .dark ? .plusLighter : .multiply }

    public var body: some View {
        if settings.texture == .off {
            base.ignoresSafeArea()
        } else {
            gradient
                .overlay {
                    Image(decorative: GrainTexture.tile, scale: GrainTexture.scale)
                        .resizable(resizingMode: .tile)
                        .blendMode(grainBlend)
                        .opacity(grainOpacity)
                }
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
    }

    /// Diffuse wash over the whole surface: the primary hue leads at the
    /// top-left, the secondary at the bottom-right, and the middle carries a
    /// blend of both, so no area is left as plain base color.
    private var gradient: some View {
        let primary = settings.tint.primary
        let secondary = settings.tint.secondary
        let warm = base.mix(with: primary, by: tintAmount)
        let warmSide = base.mix(with: primary, by: tintAmount * 0.8).mix(with: secondary, by: tintAmount * 0.15)
        let middle = base.mix(with: primary, by: tintAmount * 0.45).mix(with: secondary, by: tintAmount * 0.4)
        let coolSide = base.mix(with: secondary, by: tintAmount * 0.7).mix(with: primary, by: tintAmount * 0.15)
        let cool = base.mix(with: secondary, by: tintAmount * 0.85)
        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                warm, warmSide, middle,
                warmSide, middle, coolSide,
                middle, coolSide, cool
            ]
        )
    }
}

/// One monochrome noise tile, generated once with Core Image.
enum GrainTexture {
    /// Drawn at 3x so the grain is pixel-sized on current devices.
    static let scale: CGFloat = 3

    /// 128 pt square.
    static let tile: CGImage = {
        let side = 128 * scale
        let noise = CIFilter.randomGenerator().outputImage ?? CIImage(color: .gray)
        let monochrome = CIFilter.colorControls()
        monochrome.inputImage = noise
        monochrome.saturation = 0
        // Averaging three random channels flattens the noise; stretch it back.
        monochrome.contrast = 2.5
        let output = monochrome.outputImage ?? noise
        let context = CIContext()
        if let image = context.createCGImage(output, from: CGRect(x: 0, y: 0, width: side, height: side)) {
            return image
        }
        // Unreachable in practice; a 1×1 transparent image keeps the view valid.
        let fallback = CGContext(data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return fallback.makeImage()!
    }()
}
