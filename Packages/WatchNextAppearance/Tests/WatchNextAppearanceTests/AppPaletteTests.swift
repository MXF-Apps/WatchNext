import SwiftUI
import Testing
@testable import WatchNextAppearance

struct AppPaletteTests {
    static let cases: [(BackgroundTexture, BackgroundTint, ColorScheme)] = {
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

    @Test(arguments: cases)
    func everyRoleKeepsMinimumContrastOverTheWash(_ texture: BackgroundTexture, _ tint: BackgroundTint, _ scheme: ColorScheme) {
        let settings = AppearanceSettings(texture: texture, tint: tint)
        let palette = settings.palette(for: scheme)
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        let samples = settings.contrastSamples(for: scheme)
        for role in [palette.ready, palette.upcoming, palette.emphasis, palette.alert, palette.caution] {
            let resolved = role.resolve(in: environment)
            for sample in samples {
                #expect(AppPalette.contrast(resolved, sample.resolve(in: environment)) >= AppPalette.minimumContrast - 0.01)
            }
        }
    }

    @Test
    func unchangedWhenAlreadyLegible() {
        let white = Color.white.resolve(in: EnvironmentValues())
        let black = Color.black.resolve(in: EnvironmentValues())
        #expect(AppPalette.contrast(white, black) > 20)
        let kept = AppPalette.ensuringContrast(.black, over: [.white], minimum: 3.5, scheme: .light)
        #expect(kept == .black)
    }
}

extension AppPaletteTests {
    @Test(arguments: [BackgroundTint.white, .black, .graphite])
    func neutralTintsUseIndigoForEmphasis(_ tint: BackgroundTint) {
        let settings = AppearanceSettings(texture: .strong, tint: tint)
        for scheme in [ColorScheme.light, .dark] {
            let emphasis = settings.palette(for: scheme).emphasis.resolve(in: EnvironmentValues())
            // Indigo keeps blue as its strongest channel whatever the adjustment.
            #expect(emphasis.blue > emphasis.red && emphasis.blue > emphasis.green)
        }
    }
}
