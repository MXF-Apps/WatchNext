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
    @Environment(\.colorScheme) private var colorScheme

    /// - Parameter settings: texture strength and tint; `.off` draws the plain base.
    public init(settings: AppearanceSettings) {
        self.settings = settings
    }

    private var base: Color { AppearanceSettings.base(for: colorScheme) }

    private var grainOpacity: Double { settings.grainOpacity(for: colorScheme) }

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
    /// blend of both, so no area is left as plain base color. The colors come
    /// from `AppearanceSettings.washColors`, which the palette also checks
    /// contrast against.
    private var gradient: some View {
        let wash = settings.washColors(for: colorScheme)
        let (warm, warmSide, middle, coolSide, cool) = (wash[0], wash[1], wash[2], wash[3], wash[4])
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
