import SwiftUI
import WatchNextAppearance
import WatchNextCore
import WidgetKit

struct SettingsScreen: View {
    @Environment(\.palette) private var palette
    @EnvironmentObject private var model: WatchNextAppModel
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppearanceSettings.textureKey, store: .appGroup) private var backgroundTexture = AppearanceSettings.default.texture.rawValue
    @AppStorage(AppearanceSettings.tintKey, store: .appGroup) private var backgroundTint = AppearanceSettings.default.tint.rawValue

    var body: some View {
        NavigationStack(path: $model.settingsPath) {
            Form {
                Section {
                    NavigationLink(value: SettingsRoute.servers(nil)) {
                        HStack(spacing: 8) {
                            Label(String(localized: .settingsServersTitle), systemImage: "server.rack")
                            Spacer()
                            if model.localNetworkAccess == .denied {
                                Image(systemName: "wifi.exclamationmark")
                                    .foregroundStyle(palette.caution)
                                    .accessibilityLabel(String(localized: .settingsNetworkDeniedMessage))
                            }
                            Text(String(localized: .settingsServersConfiguredCount(count: configuredServerCount)))
                                .foregroundStyle(.secondary)
                        }
                    }
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
            .appBackground()
            .navigationTitle(String(localized: .settingsTitle))
            .navigationDestination(for: SettingsRoute.self) { route in
                ServersScreen(focus: route.service)
            }
            .onChange(of: backgroundTexture) { reloadWidgets() }
            .onChange(of: backgroundTint) { reloadWidgets() }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    SettingsSaveButton()
                }
            }
        }
        // On the stack, so the banner also covers the Servers page.
        .overlay(alignment: .top) {
            if let message = model.settingsMessage {
                SettingsStatusBanner(message: message, isError: model.settingsMessageIsError, onDismiss: model.dismissSettingsMessage)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.default, value: model.settingsMessage)
        .onChange(of: scenePhase) { _, phase in
            // Coming back from the iOS Settings app after flipping the switch.
            if phase == .active { Task { await model.refreshLocalNetworkAccess() } }
        }
    }

    private var configuredServerCount: Int {
        [model.sonarrURL, model.radarrURL, model.jellyfinURL].filter { $0.isEmpty == false }.count
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

    /// Widgets read the appearance from the App Group only when they re-render.
    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: WatchNextConstants.widgetKind)
    }
}

/// One tappable gradient disc per tint palette; the selected one wears a ring
/// and a checkmark. Buttons are plain so each disc is its own tap target
/// inside the Form row, and the grid wraps when a row cannot hold them all.
private struct TintSwatchRow: View {
    @Binding var selection: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44, maximum: 56), spacing: 0)], spacing: 4) {
            ForEach(BackgroundTint.allCases) { tint in
                let isSelected = tint.rawValue == selection
                Button {
                    withAnimation(.snappy) { selection = tint.rawValue }
                } label: {
                    Circle()
                        .fill(LinearGradient(colors: [tint.primary, tint.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay {
                            // Keeps the white and black discs visible on any card.
                            Circle().strokeBorder(.primary.opacity(0.18), lineWidth: 1)
                        }
                        .frame(width: 32, height: 32)
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(checkColor(for: tint))
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
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: .settingsAppearanceTintLabel))
    }

    /// White on every hue, except on the white disc where black is needed.
    private func checkColor(for tint: BackgroundTint) -> Color {
        tint == .white ? .black : .white
    }
}
