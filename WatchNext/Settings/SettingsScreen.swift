import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var model: WatchNextAppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Form {
                // The server fields need the Local Network permission for LAN
                // hosts, so they stay hidden until the user has answered the
                // prompt. After a refusal they come back, with the warning on
                // top, because servers reachable over the internet still work.
                if model.localNetworkAccess != .granted {
                    LocalNetworkAccessSection(access: model.localNetworkAccess) {
                        Task { await model.requestLocalNetworkAccess() }
                    }
                }
                if model.localNetworkAccess == .granted || model.localNetworkAccess == .denied {
                    SonarrSettingsSection(model: model)
                    RadarrSettingsSection(model: model)
                    JellyfinSettingsSection(model: model)
                }
                Section {
                    Stepper(value: $model.recentLookbackDays, in: 0...60) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.recentLookbackDays == 0 ? "Recent imports: no limit" : "Recent imports: \(model.recentLookbackDays) days")
                            Text(recentImportsDescription)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Stepper(value: $model.futureWindowDays, in: 0...90) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.futureWindowDays == 0 ? "Coming soon: no limit" : "Coming soon: \(model.futureWindowDays) days")
                            Text(comingSoonDescription)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Feed Windows")
                } footer: {
                    Text("Step a window down to 0 to remove its limit.")
                }
                Section {
                    Toggle("Demo mode", systemImage: "sparkles", isOn: Binding(
                        get: { model.demoMode },
                        set: { enabled in Task { await model.setDemoMode(enabled) } }
                    ))
                } header: {
                    Text("Demo")
                } footer: {
                    Text("Shows a fictional library in the app and the widgets so you can try WatchNext without servers. Your server settings are kept and used again when this is off.")
                }
                Section("Diagnostics") {
                    NavigationLink {
                        DiagnosticsScreen()
                    } label: {
                        LabeledContent("Logs") {
                            Text(model.logEntries.count, format: .number)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .overlay(alignment: .top) {
                if let message = model.settingsMessage {
                    SettingsStatusBanner(message: message, isError: model.settingsMessageIsError)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.default, value: model.settingsMessage)
            .animation(.default, value: model.localNetworkAccess)
            .onChange(of: scenePhase) { _, phase in
                // Coming back from the iOS Settings app after flipping the switch.
                if phase == .active { Task { await model.refreshLocalNetworkAccess() } }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if model.isSavingSettings {
                        ProgressView()
                            .accessibilityLabel("Saving settings")
                    } else {
                        Button("Save", action: save)
                    }
                }
            }
        }
    }

    private var recentImportsDescription: String {
        if model.recentLookbackDays == 0 {
            return "Ready to Watch lists everything Sonarr and Radarr imported that you have not watched in Jellyfin, up to the newest 250 imports per service."
        }
        return "Ready to Watch lists what Sonarr and Radarr imported in the last \(model.recentLookbackDays) days and you have not watched in Jellyfin. Older imports drop off even if unwatched."
    }

    private var comingSoonDescription: String {
        if model.futureWindowDays == 0 {
            return "Coming Soon lists every monitored episode and movie with a release date in the next year."
        }
        return "Coming Soon lists monitored episodes and movies that release within the next \(model.futureWindowDays) days."
    }

    private func save() {
        Task { await model.saveSettingsFromUI() }
    }
}
