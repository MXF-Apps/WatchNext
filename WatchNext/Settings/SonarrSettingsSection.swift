import SwiftUI

struct SonarrSettingsSection: View {
    @ObservedObject var model: WatchNextAppModel

    var body: some View {
        Section("Sonarr") {
            TextField("Base URL", text: $model.sonarrURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            SecureField(model.hasStoredSonarrKey ? "API key (stored)" : "API key", text: $model.sonarrAPIKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Test Connection", systemImage: "network", action: test)
                .disabled(model.sonarrStatus == .testing)
            ConnectionStatusView(status: model.sonarrStatus)
        }
    }

    private func test() {
        Task { await model.testSonarr() }
    }
}
