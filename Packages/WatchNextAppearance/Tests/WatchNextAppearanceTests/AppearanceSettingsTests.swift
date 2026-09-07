import Foundation
import Testing
@testable import WatchNextAppearance

struct AppearanceSettingsTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "WatchNextAppearanceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test
    func missingValuesFallBackToDefaults() {
        #expect(AppearanceSettings.load(from: makeDefaults()) == .default)
    }

    @Test
    func storedRawValuesAreRead() {
        let defaults = makeDefaults()
        defaults.set(BackgroundTexture.strong.rawValue, forKey: AppearanceSettings.textureKey)
        defaults.set(BackgroundTint.forest.rawValue, forKey: AppearanceSettings.tintKey)
        #expect(AppearanceSettings.load(from: defaults) == AppearanceSettings(texture: .strong, tint: .forest))
    }

    @Test(arguments: ["Strong", "vivid", ""])
    func unknownTextureFallsBack(_ stored: String) {
        let defaults = makeDefaults()
        defaults.set(stored, forKey: AppearanceSettings.textureKey)
        #expect(AppearanceSettings.load(from: defaults).texture == AppearanceSettings.default.texture)
    }
}
