import Foundation

public struct ServiceConfiguration: Codable, Hashable, Sendable {
    public var sonarrBaseURL: URL?
    public var radarrBaseURL: URL?
    public var jellyfinBaseURL: URL?
    public var jellyfinUserID: String?
    /// Days of import history shown in Ready to Watch; 0 means no limit.
    public var recentLookbackDays: Int
    /// Days ahead shown in Coming Soon; 0 means no limit, capped at a year
    /// because the calendar endpoints need an end date.
    public var futureWindowDays: Int

    /// Feed the app and widgets a fictional library instead of the servers, so
    /// WatchNext can be tried, demonstrated, and reviewed without any setup.
    /// Server settings are kept and used again when this is turned off.
    public var demoMode: Bool

    /// The horizon used for Coming Soon when `futureWindowDays` is 0.
    public static let unlimitedFutureDays = 365

    public var hasRecentLimit: Bool { recentLookbackDays > 0 }
    public var hasFutureLimit: Bool { futureWindowDays > 0 }

    /// Earliest import date that still counts as recent.
    public func recentStart(now: Date, calendar: Calendar = .current) -> Date {
        guard hasRecentLimit else { return .distantPast }
        return calendar.date(byAdding: .day, value: -recentLookbackDays, to: now) ?? now
    }

    /// Latest release date that still counts as coming soon.
    public func futureEnd(now: Date, calendar: Calendar = .current) -> Date {
        let days = hasFutureLimit ? futureWindowDays : Self.unlimitedFutureDays
        return calendar.date(byAdding: .day, value: days, to: now) ?? now
    }

    public init(
        sonarrBaseURL: URL? = nil,
        radarrBaseURL: URL? = nil,
        jellyfinBaseURL: URL? = nil,
        jellyfinUserID: String? = nil,
        recentLookbackDays: Int = 14,
        futureWindowDays: Int = 14,
        demoMode: Bool = false
    ) {
        self.sonarrBaseURL = sonarrBaseURL
        self.radarrBaseURL = radarrBaseURL
        self.jellyfinBaseURL = jellyfinBaseURL
        self.jellyfinUserID = jellyfinUserID
        self.recentLookbackDays = recentLookbackDays
        self.futureWindowDays = futureWindowDays
        self.demoMode = demoMode
    }

    private enum CodingKeys: String, CodingKey {
        case sonarrBaseURL, radarrBaseURL, jellyfinBaseURL, jellyfinUserID
        case recentLookbackDays, futureWindowDays, demoMode
    }

    /// Settings saved before `demoMode` existed decode with it off.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sonarrBaseURL = try container.decodeIfPresent(URL.self, forKey: .sonarrBaseURL)
        radarrBaseURL = try container.decodeIfPresent(URL.self, forKey: .radarrBaseURL)
        jellyfinBaseURL = try container.decodeIfPresent(URL.self, forKey: .jellyfinBaseURL)
        jellyfinUserID = try container.decodeIfPresent(String.self, forKey: .jellyfinUserID)
        recentLookbackDays = try container.decode(Int.self, forKey: .recentLookbackDays)
        futureWindowDays = try container.decode(Int.self, forKey: .futureWindowDays)
        demoMode = try container.decodeIfPresent(Bool.self, forKey: .demoMode) ?? false
    }
}
