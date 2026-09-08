import SwiftUI
import WatchNextAppearance

struct RootView: View {
    @State private var selection: AppTab = .feed
    @AppStorage(AppearanceSettings.textureKey, store: .appGroup) private var texture = AppearanceSettings.default.texture.rawValue
    @AppStorage(AppearanceSettings.tintKey, store: .appGroup) private var tint = AppearanceSettings.default.tint.rawValue

    var body: some View {
        TabView(selection: $selection) {
            Tab(String(localized: .appName), systemImage: "play.rectangle.on.rectangle", value: .feed) {
                FeedScreen()
            }
            Tab(String(localized: .settingsTitle), systemImage: "gearshape", value: .settings) {
                SettingsScreen()
            }
        }
        .environment(\.appearance, appearance)
    }

    private var appearance: AppearanceSettings {
        AppearanceSettings(
            texture: BackgroundTexture(rawValue: texture) ?? AppearanceSettings.default.texture,
            tint: BackgroundTint(rawValue: tint) ?? AppearanceSettings.default.tint
        )
    }
}
