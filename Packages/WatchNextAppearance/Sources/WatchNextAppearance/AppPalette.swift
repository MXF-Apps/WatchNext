import SwiftUI

/// Semantic colors for status and actions. Derived from the selected tint and
/// color scheme so every role stays legible over the textured background, in
/// the app and in the widgets alike. Views name the role, never the hue.
public struct AppPalette: Equatable, Sendable {
    /// Available to watch: checkmarks, "Ready", restore actions.
    public var ready: Color
    /// Release and air times, clock glyphs, awaiting-download hints.
    public var upcoming: Color
    /// Folded-season counts and other emphasized numbers; the palette's leading hue.
    public var emphasis: Color
    /// Errors, failed refreshes, destructive actions.
    public var alert: Color
    /// Warnings that are not errors: a refused permission, the hide action.
    public var caution: Color

    /// Fill behind a selected row.
    public var selectionFill: Color { emphasis.opacity(0.14) }

    /// Minimum WCAG contrast ratio kept between a role color and the background.
    /// 3:1 is the large-text threshold; 3.5 leaves a margin for the grain.
    public static let minimumContrast = 3.5

    /// Darkens (light scheme) or lightens (dark scheme) `color` in 5 % steps
    /// until it reaches `minimum` contrast over every background sample.
    static func ensuringContrast(_ color: Color, over backgrounds: [Color], minimum: Double, scheme: ColorScheme) -> Color {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        let targets = backgrounds.map { $0.resolve(in: environment) }
        let adjuster: Color = scheme == .dark ? .white : .black
        var amount = 0.0
        while amount <= 0.7 {
            let candidate = amount == 0 ? color : color.mix(with: adjuster, by: amount)
            let resolved = candidate.resolve(in: environment)
            if targets.allSatisfy({ contrast(resolved, $0) >= minimum }) {
                return candidate
            }
            amount += 0.05
        }
        return color.mix(with: adjuster, by: 0.7)
    }

    /// WCAG 2 contrast ratio between two resolved colors.
    static func contrast(_ a: Color.Resolved, _ b: Color.Resolved) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private static func luminance(_ c: Color.Resolved) -> Double {
        0.2126 * Double(c.linearRed) + 0.7152 * Double(c.linearGreen) + 0.0722 * Double(c.linearBlue)
    }
}

public extension AppearanceSettings {
    /// Base surface the tints are mixed into: the grouped background values at
    /// the base level, fixed rather than read from the system so widgets, which
    /// render at the elevated level, match the app exactly.
    static func base(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0, green: 0, blue: 0) : Color(red: 242 / 255, green: 242 / 255, blue: 247 / 255)
    }

    /// How far the warm and cool ends move away from the base (0 = none).
    func tintAmount(for scheme: ColorScheme) -> Double {
        switch (texture, scheme) {
        case (.off, _): 0
        case (.strong, .dark): 0.42
        case (.strong, _): 0.30
        case (.subtle, .dark): 0.26
        case (.subtle, _): 0.18
        }
    }

    /// The mesh colors, top-left to bottom-right: warm corner, warm side,
    /// middle, cool side, cool corner.
    func washColors(for scheme: ColorScheme) -> [Color] {
        let base = Self.base(for: scheme)
        let amount = tintAmount(for: scheme)
        let primary = tint.primary
        let secondary = tint.secondary
        return [
            base.mix(with: primary, by: amount),
            base.mix(with: primary, by: amount * 0.8).mix(with: secondary, by: amount * 0.15),
            base.mix(with: primary, by: amount * 0.45).mix(with: secondary, by: amount * 0.4),
            base.mix(with: secondary, by: amount * 0.7).mix(with: primary, by: amount * 0.15),
            base.mix(with: secondary, by: amount * 0.85)
        ]
    }

    /// The surfaces text can sit on: the mesh samples plus the base and the
    /// row cards (white in light, elevated gray in dark). In dark mode the grain
    /// lifts the wash a little, so the wash samples are brightened by the same
    /// amount before checking.
    func contrastSamples(for scheme: ColorScheme) -> [Color] {
        var wash = washColors(for: scheme) + [Self.base(for: scheme)]
        if scheme == .dark, texture != .off {
            wash = wash.map { $0.mix(with: .white, by: 0.1) }
        }
        let card: Color = scheme == .dark ? Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255) : .white
        return wash + [card]
    }

    /// Role colors that keep `AppPalette.minimumContrast` over every sample.
    /// Emphasis follows the tint's leading hue, except for neutral tints where
    /// the app's indigo stands in, since white or gray emphasis says nothing.
    func palette(for scheme: ColorScheme) -> AppPalette {
        let samples = contrastSamples(for: scheme)
        func fit(_ color: Color) -> Color {
            AppPalette.ensuringContrast(color, over: samples, minimum: AppPalette.minimumContrast, scheme: scheme)
        }
        return AppPalette(
            ready: fit(.green),
            upcoming: fit(.orange),
            emphasis: fit(tint.isNeutral ? .indigo : tint.primary),
            alert: fit(.red),
            caution: fit(.orange)
        )
    }
}

public extension EnvironmentValues {
    /// Semantic colors for the current appearance and color scheme.
    var palette: AppPalette {
        appearance.palette(for: colorScheme)
    }
}
