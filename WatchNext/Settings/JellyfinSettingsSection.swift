import SwiftUI

struct JellyfinSettingsSection: View {
    @ObservedObject var model: WatchNextAppModel

    var body: some View {
        Section("Jellyfin") {
            TextField("Base URL", text: $model.jellyfinURL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)

            TextField("Username", text: $model.jellyfinUsername)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            SecureField("Password (not stored)", text: $model.jellyfinPassword)
            Button("Sign In", systemImage: "person.badge.key", action: login)
                .disabled(model.jellyfinUsername.isEmpty || model.jellyfinPassword.isEmpty)

            SecureField(
                model.hasStoredJellyfinToken ? "API token (stored)" : "API token",
                text: $model.jellyfinToken
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            Button("Test Token", systemImage: "network", action: testToken)
                .disabled(model.jellyfinStatus == .testing)

            if model.jellyfinUsers.isEmpty == false {
                Picker("Watched-state user", selection: $model.selectedJellyfinUserID) {
                    Text("Select a user").tag("")
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
