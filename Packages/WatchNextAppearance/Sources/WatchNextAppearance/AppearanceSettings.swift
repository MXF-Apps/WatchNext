import Foundation

/// The user's background choices. Stored in the App Group defaults so the
/// widget extension renders the same background as the app.
public struct AppearanceSettings: Equatable, Sendable {
    public var texture: BackgroundTexture
    public var tint: BackgroundTint

    public init(texture: BackgroundTexture, tint: BackgroundTint) {
        self.texture = texture
        self.tint = tint
    }

    public static let `default` = AppearanceSettings(texture: .subtle, tint: .indigo)

    public static let textureKey = "WatchNext.Appearance.backgroundTexture"
    public static let tintKey = "WatchNext.Appearance.backgroundTint"

    /// Reads the stored choices; missing or unknown values fall back to the defaults.
    public static func load(from defaults: UserDefaults) -> AppearanceSettings {
        AppearanceSettings(
            texture: defaults.string(forKey: textureKey).flatMap(BackgroundTexture.init(rawValue:)) ?? Self.default.texture,
            tint: defaults.string(forKey: tintKey).flatMap(BackgroundTint.init(rawValue:)) ?? Self.default.tint
        )
    }
}
