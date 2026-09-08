import SwiftUI

/// Semantic colors for status and actions. Derived from the selected tint and
/// color scheme so every role stays legible over the textured background, in
/// the app and in the widgets alike. Views name the role, never the hue.
public struct AppPalette: Equatable, Sendable {
    /// Available to watch: checkmarks, "Ready", restore actions.
    public var ready: Color
    /// Release and air times still in the future, clock glyphs.
    public var upcoming: Color
    /// Already aired or released but not downloaded yet (the magnifier rows):
    /// teal, so "out now, in flight" reads apart from both the orange of
    /// "still waiting" and the green of "ready".
    public var released: Color
    /// Folded-season counts and other emphasized numbers; the palette's leading hue.
    public var emphasis: Color
    /// Errors, failed refreshes, destructive actions.
    public var alert: Color
    /// Warnings that are not errors: a refused permission, the hide action.
    public var caution: Color
    /// Inactive or disabled controls and text that must stay readable without
    /// drawing attention; replaces the system's disabled dimming, which is
    /// not contrast-checked.
    public var muted: Color
    /// Small-caps section headers: a mid gray held at `headingMinimumContrast`,
    /// so it never washes out yet stays quieter than primary titles.
    public var heading: Color

    /// Fill behind a selected row.
    public var selectionFill: Color { emphasis.opacity(0.14) }

    /// Minimum WCAG contrast ratio kept between a role color and the background.
    /// 3:1 is the large-text threshold; 3.5 leaves a margin for the grain.
    public static let minimumContrast = 3.5
    /// Headers are small text, so they get the body-text threshold.
    public static let headingMinimumContrast = 4.5

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
        ratio(luminance(a), luminance(b))
    }

    /// Contrast of a translucent label (`alpha` over `background`) against that
    /// background, as the eye sees it after compositing.
    static func contrast(label: Color.Resolved, alpha: Double, over background: Color.Resolved) -> Double {
        func mix(_ l: Float, _ b: Float) -> Double { Double(l) * alpha + Double(b) * (1 - alpha) }
        let composite = (
            linearize(mix(label.red, background.red)),
            linearize(mix(label.green, background.green)),
            linearize(mix(label.blue, background.blue))
        )
        let lc = 0.2126 * composite.0 + 0.7152 * composite.1 + 0.0722 * composite.2
        return ratio(lc, luminance(background))
    }

    /// Mixes `surface` toward `base` in 5 % steps until the system primary and
    /// secondary labels are legible on it. `seen` maps a candidate to how it
    /// looks under the grain, which darkens light washes and lifts dark ones.
    static func ensuringLegibleSurface(_ surface: Color, base: Color, scheme: ColorScheme, seen: (Color) -> Color) -> Color {
        var amount = 0.0
        while amount <= 1.0 {
            let candidate = amount == 0 ? surface : surface.mix(with: base, by: amount)
            if SystemLabel.isLegible(on: seen(candidate), scheme: scheme) {
                return candidate
            }
            amount += 0.05
        }
        return base
    }

    private static func ratio(_ a: Double, _ b: Double) -> Double {
        (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    private static func luminance(_ c: Color.Resolved) -> Double {
        0.2126 * Double(c.linearRed) + 0.7152 * Double(c.linearGreen) + 0.0722 * Double(c.linearBlue)
    }

    /// sRGB gamma component to linear light.
    private static func linearize(_ c: Double) -> Double {
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
}

/// The system label colors views use without going through the palette
/// (`.primary`, `.secondary`), so the wash can be kept legible for them.
public enum SystemLabel {
    /// Body text, WCAG AA.
    public static let primaryMinimumContrast = 4.5
    /// Secondary labels are supplementary text. Their stock contrast on the
    /// plain grouped background is about 3.3; asking for 3.0 left no room for
    /// any wash in light mode, so the promise is 80 % of stock. Primary text
    /// keeps the WCAG AA 4.5 and palette roles 3.5.
    public static let secondaryMinimumContrast = 2.7
    /// How much of the grain's effect is assumed when checking a surface.
    static let grainShiftAmount = 0.5

    static func primary(_ scheme: ColorScheme) -> Color { scheme == .dark ? .white : .black }
    /// UIKit's `secondaryLabel`: 60/60/67 at 60 % in light, 235/235/245 at 60 % in dark.
    static func secondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255) : Color(red: 60 / 255, green: 60 / 255, blue: 67 / 255)
    }
    static let secondaryAlpha = 0.6

    /// True when both system labels meet their minimum contrast on `surface`.
    public static func isLegible(on surface: Color, scheme: ColorScheme) -> Bool {
        primaryContrast(on: surface, scheme: scheme) >= primaryMinimumContrast
            && secondaryContrast(on: surface, scheme: scheme) >= secondaryMinimumContrast
    }

    public static func primaryContrast(on surface: Color, scheme: ColorScheme) -> Double {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        return AppPalette.contrast(primary(scheme).resolve(in: environment), surface.resolve(in: environment))
    }

    public static func secondaryContrast(on surface: Color, scheme: ColorScheme) -> Double {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        return AppPalette.contrast(label: secondary(scheme).resolve(in: environment), alpha: secondaryAlpha, over: surface.resolve(in: environment))
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

    /// Grain strength. Multiply darkens a light base and plus-lighter lifts a
    /// dark one; overlay would be invisible on pure black. Light values stay
    /// low enough that the plain base under grain still passes
    /// `SystemLabel.secondaryMinimumContrast` (0.18 did not).
    func grainOpacity(for scheme: ColorScheme) -> Double {
        switch (texture, scheme) {
        case (.off, _): 0
        case (.strong, .dark): 0.20
        case (.strong, _): 0.15
        case (.subtle, .dark): 0.12
        case (.subtle, _): 0.11
        }
    }

    /// The color the grain pulls the wash toward (white in dark, black in light).
    func grainShift(for scheme: ColorScheme) -> Color? {
        texture == .off ? nil : (scheme == .dark ? .white : .black)
    }

    /// A wash sample as the eye sees it once the grain is drawn over it.
    func grained(_ color: Color, for scheme: ColorScheme) -> Color {
        guard let shift = grainShift(for: scheme) else { return color }
        return color.mix(with: shift, by: grainOpacity(for: scheme) * SystemLabel.grainShiftAmount)
    }

    /// The mesh colors, top-left to bottom-right: warm corner, warm side,
    /// middle, cool side, cool corner. Each is pulled back toward the base as
    /// far as needed for the system labels to stay legible on it, so a dark
    /// tint in light mode (or a bright one in dark mode) cannot swallow
    /// secondary text.
    func washColors(for scheme: ColorScheme) -> [Color] {
        let base = Self.base(for: scheme)
        let amount = tintAmount(for: scheme)
        let primary = tint.primary
        let secondary = tint.secondary
        let raw = [
            base.mix(with: primary, by: amount),
            base.mix(with: primary, by: amount * 0.8).mix(with: secondary, by: amount * 0.15),
            base.mix(with: primary, by: amount * 0.45).mix(with: secondary, by: amount * 0.4),
            base.mix(with: secondary, by: amount * 0.7).mix(with: primary, by: amount * 0.15),
            base.mix(with: secondary, by: amount * 0.85)
        ]
        return raw.map { sample in
            AppPalette.ensuringLegibleSurface(sample, base: base, scheme: scheme) { self.grained($0, for: scheme) }
        }
    }

    /// The surfaces text can sit on: the mesh samples and the base as they look
    /// under the grain, plus the row cards (white in light, elevated gray in dark).
    func contrastSamples(for scheme: ColorScheme) -> [Color] {
        let wash = (washColors(for: scheme) + [Self.base(for: scheme)]).map { grained($0, for: scheme) }
        return wash + [Self.card(for: scheme)]
    }

    /// The row and bar surface: white in light, the elevated gray in dark.
    static func card(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255) : .white
    }

    /// Role colors that keep `AppPalette.minimumContrast` over every sample.
    /// Emphasis follows the tint's leading hue, except for neutral tints where
    /// the app's indigo stands in, since white or gray emphasis says nothing.
    func palette(for scheme: ColorScheme) -> AppPalette {
        let samples = contrastSamples(for: scheme)
        func fit(_ color: Color) -> Color {
            AppPalette.ensuringContrast(color, over: samples, minimum: AppPalette.minimumContrast, scheme: scheme)
        }
        // Start from the system secondary label as it looks composited on the
        // base, then push it only as far as the header threshold needs.
        let secondaryOnBase: Color = scheme == .dark
            ? Color(red: 141 / 255, green: 141 / 255, blue: 147 / 255)
            : Color(red: 133 / 255, green: 133 / 255, blue: 139 / 255)
        return AppPalette(
            ready: fit(.green),
            upcoming: fit(.orange),
            released: fit(.teal),
            emphasis: fit(tint.isNeutral ? .indigo : tint.primary),
            alert: fit(.red),
            caution: fit(.orange),
            muted: fit(.gray),
            heading: AppPalette.ensuringContrast(secondaryOnBase, over: samples, minimum: AppPalette.headingMinimumContrast, scheme: scheme)
        )
    }
}

public extension EnvironmentValues {
    /// Semantic colors for the current appearance and color scheme.
    var palette: AppPalette {
        appearance.palette(for: colorScheme)
    }
}
