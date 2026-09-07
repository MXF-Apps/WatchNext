import SwiftUI

struct RadarrSettingsSection: View {
    @ObservedObject var model: WatchNextAppModel

    var body: some View {
        Section(String(localized: .settingsRadarrTitle)) {
            TextField(String(localized: .settingsServerUrlPlaceholder), text: $model.radarrURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            SecureField(model.hasStoredRadarrKey ? String(localized: .settingsCredentialsStoredApiKeyPlaceholder) : String(localized: .settingsCredentialsApiKeyPlaceholder), text: $model.radarrAPIKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button(String(localized: .settingsConnectionTestButton), systemImage: "network", action: test)
                .disabled(model.radarrStatus == .testing)
            ConnectionStatusView(status: model.radarrStatus)
        }
    }

    private func test() {
        Task { await model.testRadarr() }
    }
}
