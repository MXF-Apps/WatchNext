import SwiftUI

struct JellyfinSettingsSection: View {
    @ObservedObject var model: WatchNextAppModel

    var body: some View {
        Section(String(localized: .settingsJellyfinTitle)) {
            TextField(String(localized: .settingsServerUrlPlaceholder), text: $model.jellyfinURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)

            TextField(String(localized: .settingsJellyfinUsernamePlaceholder), text: $model.jellyfinUsername)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            SecureField(String(localized: .settingsJellyfinPasswordPlaceholder), text: $model.jellyfinPassword)
            Button(String(localized: .settingsJellyfinSignInButton), systemImage: "person.badge.key", action: login)
                .disabled(model.jellyfinUsername.isEmpty || model.jellyfinPassword.isEmpty)

            SecureField(
                model.hasStoredJellyfinToken ? String(localized: .settingsJellyfinStoredTokenPlaceholder) : String(localized: .settingsJellyfinTokenPlaceholder),
                text: $model.jellyfinToken
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            Button(String(localized: .settingsJellyfinTestTokenButton), systemImage: "network", action: testToken)
                .disabled(model.jellyfinStatus == .testing)

            if model.jellyfinUsers.isEmpty == false {
                Picker(String(localized: .settingsJellyfinUserLabel), selection: $model.selectedJellyfinUserID) {
                    Text(String(localized: .settingsJellyfinUserPlaceholder)).tag("")
                    ForEach(model.jellyfinUsers) { user in
                        Text(user.name).tag(user.id)
                    }
                }
            }
            ConnectionStatusView(status: model.jellyfinStatus)
        }
    }

    private func login() {
        Task { await model.loginToJellyfin() }
    }

    private func testToken() {
        Task { await model.testJellyfinToken() }
    }
}
