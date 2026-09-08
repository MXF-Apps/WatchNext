import SwiftUI
import WatchNextCore

/// Sonarr, Radarr, and Jellyfin connection details, one level below Settings
/// so the root stays short. The Local Network gate lives here too, because
/// only these fields need the permission.
struct ServersScreen: View {
    /// Section to scroll to on appear, for deep links from an error.
    var focus: ServiceKind? = nil
    @EnvironmentObject private var model: WatchNextAppModel

    var body: some View {
        ScrollViewReader { proxy in
            Form {
                // The server fields need the Local Network permission for LAN
                // hosts, so they stay hidden until the user has answered the
                // prompt. After a refusal they come back, with the warning on
                // top, because servers reachable over the internet still work.
                if model.localNetworkAccess != .granted {
                    LocalNetworkAccessSection(access: model.localNetworkAccess, issue: model.localNetworkIssue) {
                        Task { await model.requestLocalNetworkAccess() }
                    }
                }
                if model.localNetworkAccess == .granted || model.localNetworkAccess == .denied {
                    SonarrSettingsSection(model: model)
                        .id(ServiceKind.sonarr)
                    RadarrSettingsSection(model: model)
                        .id(ServiceKind.radarr)
                    JellyfinSettingsSection(model: model)
                        .id(ServiceKind.jellyfin)
                }
            }
            .task(id: focus) {
                guard let focus else { return }
                // Let the push animation land before scrolling.
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation { proxy.scrollTo(focus, anchor: .top) }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .appBackground()
        .navigationTitle(String(localized: .settingsServersTitle))
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: model.localNetworkAccess)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: .settingsKeyboardDoneButton), action: hideKeyboard)
                    .fontWeight(.semibold)
            }
            ToolbarItem(placement: .confirmationAction) {
                SettingsSaveButton()
            }
        }
    }

    /// The fields live in separate sections with their own bindings, so the
    /// keyboard is dismissed through the window instead of a focus state.
    private func hideKeyboard() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { $0.endEditing(true) }
    }
}

/// Save control shared by the Settings root and the Servers page.
struct SettingsSaveButton: View {
    @EnvironmentObject private var model: WatchNextAppModel

    var body: some View {
        if model.isSavingSettings {
            ProgressView()
                .accessibilityLabel(String(localized: .settingsSaveAccessibilityLabel))
        } else {
            Button(String(localized: .settingsSaveButton)) {
                Task { await model.saveSettingsFromUI() }
            }
        }
    }
}
