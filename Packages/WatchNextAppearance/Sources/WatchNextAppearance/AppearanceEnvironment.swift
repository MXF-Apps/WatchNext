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
