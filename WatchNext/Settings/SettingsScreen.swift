import SwiftUI
import WatchNextAppearance
import WatchNextCore
import WidgetKit

struct SettingsScreen: View {
    @EnvironmentObject private var model: WatchNextAppModel
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppearanceSettings.textureKey, store: .appGroup) private var backgroundTexture = AppearanceSettings.default.texture.rawValue

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
                            Text(model.recentLookbackDays == 0 ? String(localized: .settingsWindowsRecentUnlimitedLabel) : String(localized: .settingsWindowsRecentLabel(days: model.recentLookbackDays)))
                            Text(recentImportsDescription)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Stepper(value: $model.futureWindowDays, in: 0...90) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.futureWindowDays == 0 ? String(localized: .settingsWindowsUpcomingUnlimitedLabel) : String(localized: .settingsWindowsUpcomingLabel(days: model.futureWindowDays)))
                            Text(comingSoonDescription)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(String(localized: .settingsWindowsTitle))
                } footer: {
                    Text(String(localized: .settingsWindowsFooter))
                }
                Section {
                    Picker(String(localized: .settingsAppearanceTextureLabel), selection: $backgroundTexture) {
                        ForEach(BackgroundTexture.allCases) { texture in
                            Text(texture.localizedName).tag(texture.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(String(localized: .settingsAppearanceTitle))
                } footer: {
                    Text(String(localized: .settingsAppearanceFooter))
                }
                Section {
                    Toggle(String(localized: .settingsDemoToggle), systemImage: "sparkles", isOn: Binding(
                        get: { model.demoMode },
                        set: { enabled in Task { await model.setDemoMode(enabled) } }
                    ))
                } header: {
                    Text(String(localized: .settingsDemoTitle))
                } footer: {
                    Text(String(localized: .settingsDemoFooter))
                }
                Section(String(localized: .settingsDiagnosticsTitle)) {
                    NavigationLink {
                        DiagnosticsScreen()
                    } label: {
                        LabeledContent(String(localized: .settingsDiagnosticsLogsLabel)) {
                            Text(model.logEntries.count, format: .number)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .appBackground()
            .navigationTitle(String(localized: .settingsTitle))
            .overlay(alignment: .top) {
                if let message = model.settingsMessage {
                    SettingsStatusBanner(message: message, isError: model.settingsMessageIsError, onDismiss: model.dismissSettingsMessage)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.default, value: model.settingsMessage)
            .animation(.default, value: model.localNetworkAccess)
            .onChange(of: backgroundTexture) { reloadWidgets() }
            .onChange(of: scenePhase) { _, phase in
                // Coming back from the iOS Settings app after flipping the switch.
                if phase == .active { Task { await model.refreshLocalNetworkAccess() } }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: .settingsKeyboardDoneButton), action: hideKeyboard)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if model.isSavingSettings {
                        ProgressView()
                            .accessibilityLabel(String(localized: .settingsSaveAccessibilityLabel))
                    } else {
                        Button(String(localized: .settingsSaveButton), action: save)
                    }
                }
            }
        }
    }

    private var recentImportsDescription: String {
        if model.recentLookbackDays == 0 {
            return String(localized: .settingsWindowsRecentUnlimitedMessage)
        }
        return String(localized: .settingsWindowsRecentMessage(days: model.recentLookbackDays))
    }

    private var comingSoonDescription: String {
        if model.futureWindowDays == 0 {
            return String(localized: .settingsWindowsUpcomingUnlimitedMessage)
        }
        return String(localized: .settingsWindowsUpcomingMessage(days: model.futureWindowDays))
    }

    private func save() {
        Task { await model.saveSettingsFromUI() }
    }

    /// Widgets read the appearance from the App Group only when they re-render.
    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: WatchNextConstants.widgetKind)
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

