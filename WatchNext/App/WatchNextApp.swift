import SwiftUI

@main
struct WatchNextApp: App {
    @StateObject private var model = WatchNextAppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .task { await model.load() }
        }
    }
}
