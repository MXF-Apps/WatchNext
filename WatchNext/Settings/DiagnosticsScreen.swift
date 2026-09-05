import SwiftUI
import WatchNextCore
import WatchNextLogging

struct DiagnosticsScreen: View {
    @EnvironmentObject private var model: WatchNextAppModel

    var body: some View {
        List {
            Section("Logging") {
                Picker("Minimum level", selection: $model.minimumLogLevel) {
                    ForEach(WatchNextLogLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .onChange(of: model.minimumLogLevel) { _, level in
                    Task { await model.setMinimumLogLevel(level) }
                }
            }

            Section("Credential Status") {
                CredentialStatusRow(name: "Sonarr API key", isStored: model.hasStoredSonarrKey)
                CredentialStatusRow(name: "Radarr API key", isStored: model.hasStoredRadarrKey)
                CredentialStatusRow(name: "Jellyfin token", isStored: model.hasStoredJellyfinToken)
            }

            Section("Refresh") {
                if let error = model.refreshError ?? model.feed.lastRefreshError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else {
                    Label("No refresh error recorded", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
                if let attempt = model.feed.lastRefreshAttempt {
                    LabeledContent("Last attempt") {
                        Text(attempt, format: .relative(presentation: .named))
                    }
                }
                if let success = model.feed.lastSuccessfulRefresh {
                    LabeledContent("Last success") {
                        Text(success, format: .relative(presentation: .named))
                    }
                }
            }

            Section("App Logs") {
                if model.logEntries.isEmpty {
                    ContentUnavailableView(
                        "No Logs Yet",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Run a connection test or refresh the feed.")
                    )
                } else {
                    ForEach(model.logEntries.reversed()) { entry in
                        LogEntryRow(entry: entry)
                    }
                }
            }
        }
        .navigationTitle("Diagnostics")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear", systemImage: "trash", action: clear)
                    .disabled(model.logEntries.isEmpty)
            }
        }
        .task { await model.reloadLogs() }
        .refreshable { await model.reloadLogs() }
    }

    private func clear() {
        Task { await model.clearLogs() }
    }
}
