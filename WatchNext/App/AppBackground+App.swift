import SwiftUI
import WatchNextAppearance
import WatchNextCore

extension UserDefaults {
    /// Shared with the widget extension, so appearance choices apply to both.
    /// UserDefaults is thread-safe; the annotation only silences the Sendable check.
    nonisolated(unsafe) static let appGroup = UserDefaults(suiteName: WatchNextConstants.appGroupIdentifier) ?? .standard
}

private struct AppBackgroundModifier: ViewModifier {
    @AppStorage(AppearanceSettings.textureKey, store: .appGroup) private var texture = AppearanceSettings.default.texture.rawValue
    @AppStorage(AppearanceSettings.tintKey, store: .appGroup) private var tint = AppearanceSettings.default.tint.rawValue

    private var settings: AppearanceSettings {
        AppearanceSettings(
            texture: BackgroundTexture(rawValue: texture) ?? AppearanceSettings.default.texture,
            tint: BackgroundTint(rawValue: tint) ?? AppearanceSettings.default.tint
        )
    }

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(settings.texture == .off ? .automatic : .hidden)
            .background {
                if settings.texture != .off {
                    AppBackground(settings: settings)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: settings)
    }
}

extension View {
    /// Replaces a list's flat grouped background with `AppBackground`, unless
    /// the user turned the texture off in Settings › Appearance.
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}

extension BackgroundTexture {
    var localizedName: String {
        switch self {
        case .off: String(localized: .settingsAppearanceTextureOff)
        case .subtle: String(localized: .settingsAppearanceTextureSubtle)
        case .strong: String(localized: .settingsAppearanceTextureStrong)
        }
    }
}

extension BackgroundTint {
    var localizedName: String {
        switch self {
        case .indigo: String(localized: .settingsAppearanceTintIndigo)
        case .ocean: String(localized: .settingsAppearanceTintOcean)
        case .orchid: String(localized: .settingsAppearanceTintOrchid)
        case .sunset: String(localized: .settingsAppearanceTintSunset)
        case .forest: String(localized: .settingsAppearanceTintForest)
        case .ember: String(localized: .settingsAppearanceTintEmber)
        case .graphite: String(localized: .settingsAppearanceTintGraphite)
        case .white: String(localized: .settingsAppearanceTintWhite)
        case .black: String(localized: .settingsAppearanceTintBlack)
        }
    }
}
