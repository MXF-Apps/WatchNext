import SwiftUI
import WatchNextAppearance
import WatchNextCore
import WidgetKit

struct SettingsScreen: View {
    @EnvironmentObject private var model: WatchNextAppModel
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppearanceSettings.textureKey, store: .appGroup) private var backgroundTexture = AppearanceSettings.default.texture.rawValue
    @AppStorage(AppearanceSettings.tintKey, store: .appGroup) private var backgroundTint = AppearanceSettings.default.tint.rawValue

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
                    // Inline swatches: the Form's own background previews the
                    // choice live, so no detail screen is needed.
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(String(localized: .settingsAppearanceTintLabel))
                            Spacer()
                            Text(selectedTint.localizedName)
                                .foregroundStyle(.secondary)
                        }
                        TintSwatchRow(selection: $backgroundTint)
                    }
                    .disabled(backgroundTexture == BackgroundTexture.off.rawValue)
                    .opacity(backgroundTexture == BackgroundTexture.off.rawValue ? 0.4 : 1)
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
            .onChange(of: backgroundTint) { reloadWidgets() }
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

    private var selectedTint: BackgroundTint {
        BackgroundTint(rawValue: backgroundTint) ?? AppearanceSettings.default.tint
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

/// One tappable gradient disc per tint palette; the selected one wears a ring
/// and a checkmark. Buttons are plain so each disc is its own tap target
/// inside the Form row.
private struct TintSwatchRow: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BackgroundTint.allCases) { tint in
                let isSelected = tint.rawValue == selection
                Button {
                    withAnimation(.snappy) { selection = tint.rawValue }
                } label: {
                    Circle()
                        .fill(LinearGradient(colors: [tint.primary, tint.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 1)
                            }
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(.primary.opacity(isSelected ? 0.55 : 0), lineWidth: 2)
                                .frame(width: 40, height: 40)
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tint.localizedName)
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                if tint != BackgroundTint.allCases.last {
                    Spacer(minLength: 0)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: .settingsAppearanceTintLabel))
    }
}
