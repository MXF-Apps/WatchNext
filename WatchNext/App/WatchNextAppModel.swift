import Foundation
import Combine
import SwiftUI
import WatchNextCore
import WidgetKit
import WatchNextLogging

@MainActor
final class WatchNextAppModel: ObservableObject {
    @Published var feed: WatchNextFeed = .empty
    /// False until the cached feed and hidden set have been published once.
    @Published private(set) var hasLoadedFeed = false
    @Published var isRefreshing = false
    @Published var refreshError: String?
    /// The last refresh failure with advice and a fix-it action; nil after success.
    @Published var refreshIssue: ActionableIssue?
    /// Selected tab and Settings navigation, published so other screens can deep-link.
    @Published var selectedTab: AppTab = .feed
    @Published var settingsPath: [SettingsRoute] = []
    @Published var hiddenItems: Set<HiddenItem> = []
    @Published var showsHiddenItems = false
    /// Multi-select mode in the feed: rows show selection circles and the
    /// hide/unhide actions apply to every selected row at once.
    @Published var isSelectingItems = false
    @Published var kindFilter: FeedKindFilter = WatchNextAppModel.storedKindFilter() {
        didSet { UserDefaults.standard.set(kindFilter.rawValue, forKey: Self.kindFilterKey) }
    }
    @Published var logEntries: [WatchNextLogEntry] = []
    @Published var minimumLogLevel = WatchNextLogger.minimumLevel

    @Published var sonarrURL = ""
    @Published var sonarrAPIKey = ""
    @Published var hasStoredSonarrKey = false
    @Published var sonarrStatus: ConnectionStatus = .idle

    @Published var radarrURL = ""
    @Published var radarrAPIKey = ""
    @Published var hasStoredRadarrKey = false
    @Published var radarrStatus: ConnectionStatus = .idle

    @Published var jellyfinURL = ""
    @Published var jellyfinToken = ""
    @Published var hasStoredJellyfinToken = false
    @Published var jellyfinUsername = ""
    @Published var jellyfinPassword = ""
    @Published var jellyfinUsers: [JellyfinUser] = []
    @Published var selectedJellyfinUserID = ""
    @Published var jellyfinStatus: ConnectionStatus = .idle

    @Published var recentLookbackDays = 14
    @Published var futureWindowDays = 14
    /// Mirrors `ServiceConfiguration.demoMode`; change it through `setDemoMode`.
    @Published private(set) var demoMode = false
    @Published var settingsMessage: String?
    @Published var settingsMessageIsError = false
    @Published var isSavingSettings = false
    /// Local network permission as last observed. Starts from the persisted
    /// outcome so Settings does not flash the permission gate on every launch.
    @Published private(set) var localNetworkAccess: LocalNetworkAccess = WatchNextAppModel.storedLocalNetworkAccess()
    /// Why the last explicit Local Network check could not decide, with guidance.
    @Published private(set) var localNetworkIssue: ActionableIssue?

    /// Pending auto-dismissal of a success confirmation.
    private var settingsMessageDismissal: Task<Void, Never>?
    /// Success confirmations disappear on their own; errors stay until the
    /// user dismisses them or the next save replaces them.
    private static let settingsConfirmationDuration: Duration = .seconds(4)

    private let dependencies: WatchNextDependencies
    private static let kindFilterKey = "WatchNext.FeedKindFilter"
    private static let localNetworkAccessKey = "WatchNext.LocalNetwork.access"

    init(dependencies: WatchNextDependencies = .live) {
        self.dependencies = dependencies
    }

    /// The cached feed with hidden entries removed and the kind filter applied.
    var visibleFeed: WatchNextFeed {
        feed.hiding(hiddenItems).filtering(kindFilter).collapsingSeasons()
    }

    /// Items currently hidden from the feed, respecting the kind filter.
    var hiddenFeedItems: [MediaFeedItem] {
        feed.filtering(kindFilter).hiddenItems(matching: hiddenItems)
    }

    func load() async {
        logger.info("Application state loading started.", category: "App")
        let configuration = await dependencies.configurationStore.load()
        sonarrURL = configuration.sonarrBaseURL?.absoluteString ?? ""
        radarrURL = configuration.radarrBaseURL?.absoluteString ?? ""
        jellyfinURL = configuration.jellyfinBaseURL?.absoluteString ?? ""
        selectedJellyfinUserID = configuration.jellyfinUserID ?? ""
        recentLookbackDays = configuration.recentLookbackDays
        futureWindowDays = configuration.futureWindowDays
        demoMode = configuration.demoMode
        // Publish the hidden set and the feed together, without animation: the
        // first render must already exclude hidden items and fold seasons, or
        // rows appear and then animate away.
        let cachedFeed = await dependencies.feedService.cachedFeed()
        let hidden = await dependencies.hiddenItemStore.hidden()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            hiddenItems = hidden
            feed = cachedFeed
            hasLoadedFeed = true
        }
        hasStoredSonarrKey = await storedCredential(.sonarrAPIKey) != nil
        hasStoredRadarrKey = await storedCredential(.radarrAPIKey) != nil
        hasStoredJellyfinToken = await storedCredential(.jellyfinAccessToken) != nil
        jellyfinUsername = await storedCredential(.jellyfinUsername) ?? ""
        if hasStoredJellyfinToken, let url = try? validatedURL(jellyfinURL, service: "Jellyfin") {
            do {
                jellyfinUsers = try await dependencies.connectionService.fetchJellyfinUsers(baseURL: url)
            } catch {
                logger.error("Could not restore Jellyfin users.", error: error, category: "App")
                showSettingsMessage(String(localized: .settingsJellyfinRestoreError(error: error.localizedDescription)), isError: true)
            }
        }
        logger.info(
            "Application state loaded; Sonarr key: \(hasStoredSonarrKey), Radarr key: \(hasStoredRadarrKey), Jellyfin token: \(hasStoredJellyfinToken).",
            category: "App"
        )
        await reloadLogs()
        Task { await refreshLocalNetworkAccess() }
    }

    /// True once the user has been through the Local Network prompt, whatever
    /// the answer; later launches re-check silently instead of showing the gate.
    var hasRequestedLocalNetworkAccess: Bool {
        UserDefaults.standard.string(forKey: Self.localNetworkAccessKey) != nil
    }

    /// Shows the iOS Local Network prompt (the first time) and records the outcome.
    func requestLocalNetworkAccess() async {
        guard localNetworkAccess != .checking else { return }
        localNetworkAccess = .checking
        localNetworkIssue = nil
        let result = await LocalNetworkAuthorization.check()
        localNetworkAccess = result.access
        localNetworkIssue = result.failure.map(ActionableIssue.init(localNetworkFailure:))
        UserDefaults.standard.set(result.access.rawValue, forKey: Self.localNetworkAccessKey)
    }

    /// Re-checks a permission the user already answered. iOS shows no prompt
    /// then, and the published state only changes once the result is in, so a
    /// granted permission never hides the server fields while checking.
    func refreshLocalNetworkAccess() async {
        guard hasRequestedLocalNetworkAccess, localNetworkAccess != .checking else { return }
        let result = await LocalNetworkAuthorization.check(timeout: 10)
        guard result.access != .unknown else { return }
        localNetworkAccess = result.access
        UserDefaults.standard.set(result.access.rawValue, forKey: Self.localNetworkAccessKey)
    }

    func refresh() async {
        guard isRefreshing == false else { return }
        logger.info("Manual app refresh requested.", category: "App")
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            try await saveSettings(showConfirmation: false)
            let refreshed = try await dependencies.feedService.refresh()
            hiddenItems = await dependencies.hiddenItemStore.hidden()
            feed = refreshed
            refreshError = nil
            refreshIssue = nil
            WidgetCenter.shared.reloadTimelines(ofKind: WatchNextConstants.widgetKind)
        } catch {
            refreshError = error.localizedDescription
            refreshIssue = ActionableIssue(refreshError: error)
            feed = await dependencies.feedService.cachedFeed()
            logger.error("Manual app refresh failed.", error: error, category: "App")
        }
        await reloadLogs()
    }

    /// Switches to Settings › Servers, scrolled to `service` when given.
    func openServers(focusing service: ServiceKind?) {
        selectedTab = .settings
        settingsPath = [.servers(service)]
    }

    /// True once any server address has been entered.
    var hasServerConfiguration: Bool {
        [sonarrURL, radarrURL, jellyfinURL].contains { $0.isEmpty == false }
    }

    /// Switches between the fictional demo library and the configured servers,
    /// saves the choice, and refreshes the feed and widgets right away.
    func setDemoMode(_ enabled: Bool) async {
        guard demoMode != enabled else { return }
        demoMode = enabled
        logger.info("Demo mode \(enabled ? "enabled" : "disabled").", category: "Demo")
        await refresh()
    }

    /// Hides the Settings banner right away, for a tap on it.
    func dismissSettingsMessage() {
        settingsMessageDismissal?.cancel()
        settingsMessageDismissal = nil
        settingsMessage = nil
    }

    private func showSettingsMessage(_ message: String, isError: Bool) {
        settingsMessageDismissal?.cancel()
        settingsMessageDismissal = nil
        settingsMessage = message
        settingsMessageIsError = isError
        guard isError == false else { return }
        settingsMessageDismissal = Task { [weak self] in
            try? await Task.sleep(for: Self.settingsConfirmationDuration)
            guard Task.isCancelled == false else { return }
            self?.settingsMessage = nil
        }
    }

    func saveSettingsFromUI() async {
        guard isSavingSettings == false else { return }
        isSavingSettings = true
        defer { isSavingSettings = false }
        do {
            try await saveSettings()
        } catch {
            showSettingsMessage(error.localizedDescription, isError: true)
            logger.error("Settings save failed.", error: error, category: "Settings")
        }
        await reloadLogs()
    }

    func saveSettings(showConfirmation: Bool = true) async throws {
        let configuration = try currentConfiguration()
        try await dependencies.configurationStore.save(configuration)
        if sonarrAPIKey.isEmpty == false {
            try await dependencies.connectionService.saveCredential(sonarrAPIKey, for: .sonarrAPIKey)
            sonarrAPIKey = ""
            hasStoredSonarrKey = true
        }
        if radarrAPIKey.isEmpty == false {
            try await dependencies.connectionService.saveCredential(radarrAPIKey, for: .radarrAPIKey)
            radarrAPIKey = ""
            hasStoredRadarrKey = true
        }
        if jellyfinToken.isEmpty == false {
            try await dependencies.connectionService.saveCredential(jellyfinToken, for: .jellyfinAccessToken)
            jellyfinToken = ""
            hasStoredJellyfinToken = true
        }
        logger.info("Non-sensitive settings and supplied credentials were saved.", category: "Settings")
        if showConfirmation {
            showSettingsMessage(String(localized: .settingsSaveSuccessMessage), isError: false)
        }
    }

    func testSonarr() async {
        sonarrStatus = .testing
        do {
            let url = try validatedURL(sonarrURL, service: "Sonarr")
            let health = try await dependencies.connectionService.testSonarr(
                baseURL: url,
                apiKey: sonarrAPIKey.isEmpty ? nil : sonarrAPIKey
            )
            if sonarrAPIKey.isEmpty == false {
                try await dependencies.connectionService.saveCredential(sonarrAPIKey, for: .sonarrAPIKey)
                sonarrAPIKey = ""
                hasStoredSonarrKey = true
            }
            sonarrStatus = .connected(health.version.map { String(localized: .settingsConnectionVersionLabel(version: $0)) } ?? String(localized: .settingsConnectionSuccessLabel))
        } catch {
            sonarrStatus = .failed(error.localizedDescription)
            logger.error("Sonarr connection test failed.", error: error, category: "Sonarr")
        }
        await reloadLogs()
    }

    func testRadarr() async {
        radarrStatus = .testing
        do {
            let url = try validatedURL(radarrURL, service: "Radarr")
            let health = try await dependencies.connectionService.testRadarr(
                baseURL: url,
                apiKey: radarrAPIKey.isEmpty ? nil : radarrAPIKey
            )
            if radarrAPIKey.isEmpty == false {
                try await dependencies.connectionService.saveCredential(radarrAPIKey, for: .radarrAPIKey)
                radarrAPIKey = ""
                hasStoredRadarrKey = true
            }
            radarrStatus = .connected(health.version.map { String(localized: .settingsConnectionVersionLabel(version: $0)) } ?? String(localized: .settingsConnectionSuccessLabel))
        } catch {
            radarrStatus = .failed(error.localizedDescription)
            logger.error("Radarr connection test failed.", error: error, category: "Radarr")
        }
        await reloadLogs()
    }

    func loginToJellyfin() async {
        jellyfinStatus = .testing
        do {
            let url = try validatedURL(jellyfinURL, service: "Jellyfin")
            let authentication = try await dependencies.connectionService.authenticateJellyfin(
                baseURL: url,
                username: jellyfinUsername,
                password: jellyfinPassword
            )
            jellyfinPassword = ""
            hasStoredJellyfinToken = true
            selectedJellyfinUserID = authentication.user.id
            jellyfinUsers = try await dependencies.connectionService.fetchJellyfinUsers(baseURL: url)
            try await saveSettings(showConfirmation: false)
            jellyfinStatus = .connected(String(localized: .settingsJellyfinSignedInMessage(username: authentication.user.name)))
        } catch {
            jellyfinStatus = .failed(error.localizedDescription)
            logger.error("Jellyfin sign-in failed.", error: error, category: "Jellyfin")
        }
        await reloadLogs()
    }

    func testJellyfinToken() async {
        jellyfinStatus = .testing
        do {
            let url = try validatedURL(jellyfinURL, service: "Jellyfin")
            let health = try await dependencies.connectionService.saveAndTestJellyfinToken(
                baseURL: url,
                token: jellyfinToken.isEmpty ? nil : jellyfinToken
            )
            hasStoredJellyfinToken = true
            jellyfinToken = ""
            jellyfinUsers = try await dependencies.connectionService.fetchJellyfinUsers(baseURL: url)
            jellyfinStatus = .connected(health.version.map { String(localized: .settingsConnectionVersionLabel(version: $0)) } ?? String(localized: .settingsConnectionSuccessLabel))
        } catch {
            jellyfinStatus = .failed(error.localizedDescription)
            logger.error("Jellyfin token test failed.", error: error, category: "Jellyfin")
        }
        await reloadLogs()
    }

    func hide(_ item: MediaFeedItem, scope: HideScope) async {
        await hide([item], scope: scope)
    }

    /// Hides every item (or, for `.series`, every item's series) in one write.
    func hide(_ items: [MediaFeedItem], scope: HideScope) async {
        let entries: [HiddenItem] = items.compactMap { item in
            switch scope {
            case .item: item.itemHideKey
            case .series: item.seriesHideKey
            }
        }
        guard entries.isEmpty == false else { return }
        do {
            try await dependencies.hiddenItemStore.hide(contentsOf: entries)
            hiddenItems = await dependencies.hiddenItemStore.hidden()
            WidgetCenter.shared.reloadTimelines(ofKind: WatchNextConstants.widgetKind)
        } catch {
            logger.error("Could not hide \(items.count) item(s).", error: error, category: "HiddenItems")
        }
    }

    func unhide(_ item: MediaFeedItem) async {
        await unhide([item])
    }

    /// Removes every hidden entry that matches any of the items, in one write.
    func unhide(_ items: [MediaFeedItem]) async {
        let entries = hiddenItems.filter { entry in items.contains { entry.matches($0) } }
        guard entries.isEmpty == false else { return }
        do {
            try await dependencies.hiddenItemStore.unhide(entries)
            hiddenItems = await dependencies.hiddenItemStore.hidden()
            WidgetCenter.shared.reloadTimelines(ofKind: WatchNextConstants.widgetKind)
        } catch {
            logger.error("Could not unhide \(items.count) item(s).", error: error, category: "HiddenItems")
        }
    }

    func reloadLogs() async {
        logEntries = await logger.entries()
    }

    func clearLogs() async {
        await logger.clear()
        await reloadLogs()
    }

    func setMinimumLogLevel(_ level: WatchNextLogLevel) async {
        WatchNextLogger.setMinimumLevel(level)
        minimumLogLevel = level
        logger.notice("Log level changed to \(level.displayName).", category: "Logging")
        await reloadLogs()
    }

    private func currentConfiguration() throws -> ServiceConfiguration {
        ServiceConfiguration(
            sonarrBaseURL: try optionalValidatedURL(sonarrURL, service: "Sonarr"),
            radarrBaseURL: try optionalValidatedURL(radarrURL, service: "Radarr"),
            jellyfinBaseURL: try optionalValidatedURL(jellyfinURL, service: "Jellyfin"),
            jellyfinUserID: selectedJellyfinUserID.isEmpty ? nil : selectedJellyfinUserID,
            recentLookbackDays: recentLookbackDays,
            futureWindowDays: futureWindowDays,
            demoMode: demoMode
        )
    }

    /// Empty fields stay unset (a fresh install, or demo mode without servers);
    /// anything typed must be a valid HTTP or HTTPS URL.
    private func optionalValidatedURL(_ value: String, service: String) throws -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : try validatedURL(trimmed, service: service)
    }

    private func validatedURL(_ value: String, service: String) throws -> URL {
        guard
            let url = URL(string: value),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host() != nil
        else { throw AppConfigurationError.invalidURL(service) }
        return url
    }

    private static func storedLocalNetworkAccess() -> LocalNetworkAccess {
        let stored = UserDefaults.standard.string(forKey: localNetworkAccessKey).flatMap(LocalNetworkAccess.init(rawValue:))
        return stored == .checking ? .unknown : (stored ?? .unknown)
    }

    private static func storedKindFilter() -> FeedKindFilter {
        UserDefaults.standard.string(forKey: kindFilterKey).flatMap(FeedKindFilter.init(rawValue:)) ?? .all
    }

    private func storedCredential(_ key: CredentialKey) async -> String? {
        do {
            return try await dependencies.connectionService.credential(key)
        } catch {
            logger.error("Could not restore credential \(key.rawValue).", error: error, category: "Keychain")
            if settingsMessage == nil {
                showSettingsMessage(String(localized: .settingsCredentialsReadError(error: error.localizedDescription)), isError: true)
            }
            return nil
        }
    }
}
