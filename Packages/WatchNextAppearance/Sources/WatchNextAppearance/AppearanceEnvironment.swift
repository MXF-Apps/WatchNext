import SwiftUI

private struct AppearanceSettingsKey: EnvironmentKey {
    static let defaultValue = AppearanceSettings.default
}

public extension EnvironmentValues {
    /// The current background choices, set once at each root (app and widget)
    /// so rows can pick colors that match the selected palette.
    var appearance: AppearanceSettings {
        get { self[AppearanceSettingsKey.self] }
        set { self[AppearanceSettingsKey.self] = newValue }
    }
}

public extension AppearanceSettings {
    /// Color for emphasized counts such as the folded-season badge. It follows
    /// the palette's leading hue instead of the system accent, so it never
    /// clashes with the tinted background.
    var emphasis: Color { tint.primary }
}
