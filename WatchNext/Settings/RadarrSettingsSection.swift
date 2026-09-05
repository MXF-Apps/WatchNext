import SwiftUI

struct RadarrSettingsSection: View {
    @ObservedObject var model: WatchNextAppModel

    var body: some View {
        Section("Radarr") {
            TextField("Base URL", text: $model.radarrURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            SecureField(model.hasStoredRadarrKey ? "API key (stored)" : "API key", text: $model.radarrAPIKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Test Connection", systemImage: "network", action: test)
                .disabled(model.radarrStatus == .testing)
            ConnectionStatusView(status: model.radarrStatus)
        }
    }

    private func test() {
        Task { await model.testRadarr() }
    }
}
