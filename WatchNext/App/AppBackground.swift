import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// Grouped background with a faint accent mesh gradient and film grain, so
/// large empty areas stop reading as flat gray while list rows keep their
/// contrast against `systemGroupedBackground`.
///
/// The grain is a tiled noise image rather than a Metal shader: shaders need
/// the Metal toolchain on every machine that builds the project, and widgets
/// cannot run them anyway.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    /// How far the corner tints move away from the base gray (0 = none).
    private var tintAmount: Double { colorScheme == .dark ? 0.16 : 0.10 }
    /// Grain strength. Multiply darkens a light base and plus-lighter lifts a
    /// black one; overlay would be invisible on pure black.
    private var grainOpacity: Double { colorScheme == .dark ? 0.08 : 0.07 }
    private var grainBlend: BlendMode { colorScheme == .dark ? .plusLighter : .multiply }

    var body: some View {
        let base = Color(.systemGroupedBackground)
        let warm = base.mix(with: .indigo, by: tintAmount)
        let cool = base.mix(with: .teal, by: tintAmount * 0.7)
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.45, 0.55], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                warm, base, base,
                base, base, base,
                base, cool, cool
            ]
        )
        .overlay {
            Image(uiImage: GrainTexture.tile)
                .resizable(resizingMode: .tile)
                .blendMode(grainBlend)
                .opacity(grainOpacity)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// One monochrome noise tile, generated once with Core Image.
enum GrainTexture {
    /// 128 pt square at 3x, so the grain is pixel-sized on current devices.
    static let tile: UIImage = {
        let scale: CGFloat = 3
        let side: CGFloat = 128 * scale
        let noise = CIFilter.randomGenerator().outputImage ?? CIImage(color: .gray)
        let monochrome = CIFilter.colorControls()
        monochrome.inputImage = noise
        monochrome.saturation = 0
        // Averaging three random channels flattens the noise; stretch it back.
        monochrome.contrast = 2.5
        let output = monochrome.outputImage ?? noise
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: CGRect(x: 0, y: 0, width: side, height: side)) else {
            return UIImage()
        }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }()
}

extension View {
    /// Replaces a list's flat grouped background with `AppBackground`.
    func appBackground() -> some View {
        scrollContentBackground(.hidden)
            .background { AppBackground() }
    }
}
