import SwiftUI

struct RootView: View {
    @State private var selection: AppTab = .feed

    var body: some View {
        TabView(selection: $selection) {
            Tab("WatchNext", systemImage: "play.rectangle.on.rectangle", value: .feed) {
                FeedScreen()
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsScreen()
            }
        }
    }
}
