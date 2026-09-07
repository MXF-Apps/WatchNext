import SwiftUI

struct RootView: View {
    @State private var selection: AppTab = .feed

    var body: some View {
        TabView(selection: $selection) {
            Tab(String(localized: .appName), systemImage: "play.rectangle.on.rectangle", value: .feed) {
                FeedScreen()
            }
            Tab(String(localized: .settingsTitle), systemImage: "gearshape", value: .settings) {
                SettingsScreen()
            }
        }
    }
}
