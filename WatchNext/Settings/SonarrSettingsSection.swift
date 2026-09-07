import SwiftUI

struct SonarrSettingsSection: View {
    @ObservedObject var model: WatchNextAppModel

    var body: some View {
        Section(String(localized: .settingsSonarrTitle)) {
            TextField(String(localized: .settingsServerUrlPlaceholder), text: $model.sonarrURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            SecureField(model.hasStoredSonarrKey ? String(localized: .settingsCredentialsStoredApiKeyPlaceholder) : String(localized: .settingsCredentialsApiKeyPlaceholder), text: $model.sonarrAPIKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button(String(localized: .settingsConnectionTestButton), systemImage: "network", action: test)
                .disabled(model.sonarrStatus == .testing)
            ConnectionStatusView(status: model.sonarrStatus)
        }
    }

    private func test() {
        Task { await model.testSonarr() }
    }
}
