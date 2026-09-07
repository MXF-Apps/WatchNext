import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

/// User-selectable strength of the textured list background (Settings › Appearance).
enum BackgroundTexture: String, CaseIterable, Identifiable {
    case off
    case subtle
    case strong

    var id: Self { self }
    static let storageKey = "WatchNext.Appearance.backgroundTexture"

    var localizedName: String {
        switch self {
        case .off: String(localized: .settingsAppearanceTextureOff)
        case .subtle: String(localized: .settingsAppearanceTextureSubtle)
        case .strong: String(localized: .settingsAppearanceTextureStrong)
        }
    }
}

/// Grouped background with an accent mesh gradient and film grain, so large
/// empty areas stop reading as flat gray while list rows keep their contrast
/// against `systemGroupedBackground`.
///
/// The grain is a tiled noise image rather than a Metal shader: shaders need
/// the Metal toolchain on every machine that builds the project, and widgets
/// cannot run them anyway.
struct AppBackground: View {
    let texture: BackgroundTexture
    @Environment(\.colorScheme) private var colorScheme

    /// How far the warm and cool ends move away from the base gray (0 = none).
    private var tintAmount: Double {
        switch (texture, colorScheme) {
        case (.strong, .dark): 0.42
        case (.strong, _): 0.30
        case (_, .dark): 0.26
        default: 0.18
        }
    }

    /// Grain strength. Multiply darkens a light base and plus-lighter lifts a
    /// black one; overlay would be invisible on pure black.
    private var grainOpacity: Double {
        switch (texture, colorScheme) {
        case (.strong, .dark): 0.20
        case (.strong, _): 0.18
        case (_, .dark): 0.12
        default: 0.11
        }
    }

    private var grainBlend: BlendMode { colorScheme == .dark ? .plusLighter : .multiply }

    var body: some View {
        let base = Color(.systemGroupedBackground)
        let warm = base.mix(with: .indigo, by: tintAmount)
        let warmHalf = base.mix(with: .indigo, by: tintAmount * 0.5)
        let cool = base.mix(with: .teal, by: tintAmount * 0.8)
        let coolHalf = base.mix(with: .teal, by: tintAmount * 0.4)
        // Diagonal wash: indigo from the top-left corner to teal at the bottom-right.
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.45, 0.55], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                warm, warmHalf, base,
                warmHalf, base, coolHalf,
                base, coolHalf, cool
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

private struct AppBackgroundModifier: ViewModifier {
    @AppStorage(BackgroundTexture.storageKey) private var stored = BackgroundTexture.subtle.rawValue

    private var texture: BackgroundTexture { BackgroundTexture(rawValue: stored) ?? .subtle }

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(texture == .off ? .automatic : .hidden)
            .background {
                if texture != .off {
                    AppBackground(texture: texture)
                }
            }
    }
}

extension View {
    /// Replaces a list's flat grouped background with `AppBackground`, unless
    /// the user turned the texture off in Settings › Appearance.
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}
