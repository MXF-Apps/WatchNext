import SwiftUI
import Testing
@testable import WatchNextAppearance

/// Every texture × tint × scheme combination is checked here, so a new tint or
/// a tuned mesh cannot ship a surface that hides text. Thresholds live next to
/// the values they guard: `AppPalette.minimumContrast` and `SystemLabel`.
struct AppPaletteTests {
    static let combinations: [(BackgroundTexture, BackgroundTint, ColorScheme)] = {
        var result: [(BackgroundTexture, BackgroundTint, ColorScheme)] = []
        for texture in BackgroundTexture.allCases {
            for tint in BackgroundTint.allCases {
                for scheme in [ColorScheme.light, .dark] {
                    result.append((texture, tint, scheme))
                }
            }
        }
        return result
    }()

    private static func environment(_ scheme: ColorScheme) -> EnvironmentValues {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        return environment
    }

    @Test("Palette roles keep 3.5:1 over the wash, the base, and the cards", arguments: combinations)
    func rolesKeepMinimumContrast(_ texture: BackgroundTexture, _ tint: BackgroundTint, _ scheme: ColorScheme) {
        let settings = AppearanceSettings(texture: texture, tint: tint)
        let palette = settings.palette(for: scheme)
        let environment = Self.environment(scheme)
        let roles: [(String, Color)] = [
            ("ready", palette.ready), ("upcoming", palette.upcoming), ("released", palette.released),
            ("emphasis", palette.emphasis), ("alert", palette.alert), ("caution", palette.caution),
            ("muted", palette.muted), ("heading", palette.heading)
        ]
        for (name, role) in roles {
            let resolved = role.resolve(in: environment)
            for (index, sample) in settings.contrastSamples(for: scheme).enumerated() {
                let contrast = AppPalette.contrast(resolved, sample.resolve(in: environment))
                #expect(contrast >= AppPalette.minimumContrast - 0.01, "\(name) over sample \(index): \(contrast)")
            }
        }
    }

    @Test("Heading role keeps 4.5:1 and stays below the primary label", arguments: combinations)
    func headingIsFirmButQuiet(_ texture: BackgroundTexture, _ tint: BackgroundTint, _ scheme: ColorScheme) {
        let settings = AppearanceSettings(texture: texture, tint: tint)
        let environment = Self.environment(scheme)
        let heading = settings.palette(for: scheme).heading.resolve(in: environment)
        for sample in settings.contrastSamples(for: scheme) {
            let resolved = sample.resolve(in: environment)
            let headingContrast = AppPalette.contrast(heading, resolved)
            let primaryContrast = AppPalette.contrast(SystemLabel.primary(scheme).resolve(in: environment), resolved)
            #expect(headingContrast >= AppPalette.headingMinimumContrast - 0.01)
            #expect(headingContrast <= primaryContrast)
        }
    }

    @Test("System primary label keeps 4.5:1 on every grained wash sample", arguments: combinations)
    func primaryLabelStaysLegible(_ texture: BackgroundTexture, _ tint: BackgroundTint, _ scheme: ColorScheme) {
        let settings = AppearanceSettings(texture: texture, tint: tint)
        for (index, sample) in settings.washColors(for: scheme).enumerated() {
            let contrast = SystemLabel.primaryContrast(on: settings.grained(sample, for: scheme), scheme: scheme)
            #expect(contrast >= SystemLabel.primaryMinimumContrast, "sample \(index): \(contrast)")
        }
    }

    @Test("System secondary label keeps 3:1 on every grained wash sample", arguments: combinations)
    func secondaryLabelStaysLegible(_ texture: BackgroundTexture, _ tint: BackgroundTint, _ scheme: ColorScheme) {
        let settings = AppearanceSettings(texture: texture, tint: tint)
        for (index, sample) in settings.washColors(for: scheme).enumerated() {
            let contrast = SystemLabel.secondaryContrast(on: settings.grained(sample, for: scheme), scheme: scheme)
            #expect(contrast >= SystemLabel.secondaryMinimumContrast - 0.01, "sample \(index): \(contrast)")
        }
    }

    @Test("Released is lighter than upcoming: the closer, the lighter", arguments: combinations)
    func releasedIsLighterThanUpcoming(_ texture: BackgroundTexture, _ tint: BackgroundTint, _ scheme: ColorScheme) {
        let palette = AppearanceSettings(texture: texture, tint: tint).palette(for: scheme)
        let environment = Self.environment(scheme)
        let released = AppPalette.luminance(palette.released.resolve(in: environment))
        let upcoming = AppPalette.luminance(palette.upcoming.resolve(in: environment))
        #expect(released > upcoming)
    }

    @Test("The plain base already satisfies the label thresholds")
    func baseIsLegible() {
        for scheme in [ColorScheme.light, .dark] {
            #expect(SystemLabel.isLegible(on: AppearanceSettings.base(for: scheme), scheme: scheme))
        }
    }

    @Test("A wash that is already legible is left untouched")
    func legibleSurfaceIsKept() {
        let kept = AppPalette.ensuringLegibleSurface(.white, base: .white, scheme: .light) { $0 }
        #expect(kept == .white)
    }

    @Test("Legible colors are not adjusted")
    func unchangedWhenAlreadyLegible() {
        let kept = AppPalette.ensuringContrast(.black, over: [.white], minimum: 3.5, scheme: .light)
        #expect(kept == .black)
    }

    @Test(arguments: [BackgroundTint.white, .black, .graphite])
    func neutralTintsUseIndigoForEmphasis(_ tint: BackgroundTint) {
        let settings = AppearanceSettings(texture: .strong, tint: tint)
        for scheme in [ColorScheme.light, .dark] {
            let emphasis = settings.palette(for: scheme).emphasis.resolve(in: EnvironmentValues())
            #expect(emphasis.blue > emphasis.red && emphasis.blue > emphasis.green)
        }
    }

    @Test("Translucent label contrast composites the alpha first")
    func translucentContrastComposites() {
        let environment = Self.environment(.light)
        let black = Color.black.resolve(in: environment)
        let white = Color.white.resolve(in: environment)
        let opaque = AppPalette.contrast(label: black, alpha: 1, over: white)
        let faint = AppPalette.contrast(label: black, alpha: 0.1, over: white)
        #expect(opaque > 20)
        #expect(faint < 1.5)
    }
}

extension AppPaletteTests {
    static let tints: [BackgroundTint] = BackgroundTint.allCases

    @Test("In dark mode Strong is the darker wash, Subtle the lighter", arguments: tints)
    func darkModeStrongIsDarker(_ tint: BackgroundTint) {
        var environment = EnvironmentValues()
        environment.colorScheme = .dark
        let subtle = AppearanceSettings(texture: .subtle, tint: tint)
        let strong = AppearanceSettings(texture: .strong, tint: tint)
        for (s, g) in zip(subtle.washColors(for: .dark), strong.washColors(for: .dark)) {
            let ls = AppPalette.luminance(subtle.grained(s, for: .dark).resolve(in: environment))
            let lg = AppPalette.luminance(strong.grained(g, for: .dark).resolve(in: environment))
            #expect(lg <= ls + 0.001)
        }
    }

    @Test("Light mode keeps its original values: Strong tints more than Subtle")
    func lightModeUnchanged() {
        let subtle = AppearanceSettings(texture: .subtle, tint: .indigo)
        let strong = AppearanceSettings(texture: .strong, tint: .indigo)
        #expect(strong.tintAmount(for: .light) > subtle.tintAmount(for: .light))
        #expect(strong.grainOpacity(for: .light) > subtle.grainOpacity(for: .light))
    }
}
