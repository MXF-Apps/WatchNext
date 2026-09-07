import SwiftUI
import WatchNextCore
import WatchNextLogging

struct DiagnosticsScreen: View {
    @EnvironmentObject private var model: WatchNextAppModel

    var body: some View {
        List {
            Section(String(localized: .diagnosticsLoggingTitle)) {
                Picker(String(localized: .diagnosticsLoggingLevelLabel), selection: $model.minimumLogLevel) {
                    ForEach(WatchNextLogLevel.allCases, id: \.self) { level in
                        Text(level.localizedDisplayName).tag(level)
                    }
                }
                .onChange(of: model.minimumLogLevel) { _, level in
                    Task { await model.setMinimumLogLevel(level) }
                }
            }

            Section(String(localized: .diagnosticsCredentialsTitle)) {
                CredentialStatusRow(name: String(localized: .diagnosticsCredentialsSonarrLabel), isStored: model.hasStoredSonarrKey)
                CredentialStatusRow(name: String(localized: .diagnosticsCredentialsRadarrLabel), isStored: model.hasStoredRadarrKey)
                CredentialStatusRow(name: String(localized: .diagnosticsCredentialsJellyfinLabel), isStored: model.hasStoredJellyfinToken)
            }

            Section(String(localized: .diagnosticsRefreshTitle)) {
                if let error = model.refreshError ?? model.feed.lastRefreshError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                } else {
                    Label(String(localized: .diagnosticsRefreshSuccessMessage), systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
                if let attempt = model.feed.lastRefreshAttempt {
                    LabeledContent(String(localized: .diagnosticsRefreshAttemptLabel)) {
                        Text(attempt, format: .relative(presentation: .named))
                    }
                }
                if let success = model.feed.lastSuccessfulRefresh {
                    LabeledContent(String(localized: .diagnosticsRefreshSuccessLabel)) {
                        Text(success, format: .relative(presentation: .named))
                    }
                }
            }

            Section(String(localized: .diagnosticsLogsTitle)) {
                if model.logEntries.isEmpty {
                    ContentUnavailableView(
                        String(localized: .diagnosticsLogsEmptyTitle),
                        systemImage: "doc.text.magnifyingglass",
                        description: Text(String(localized: .diagnosticsLogsEmptyMessage))
                    )
                } else {
                    ForEach(model.logEntries.reversed()) { entry in
                        LogEntryRow(entry: entry)
                    }
                }
            }
        }
        .navigationTitle(String(localized: .settingsDiagnosticsTitle))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: .diagnosticsLogsClearButton), systemImage: "trash", action: clear)
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
