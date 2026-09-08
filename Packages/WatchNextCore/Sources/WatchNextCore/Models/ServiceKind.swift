/// The three servers WatchNext talks to. Used to attribute failures and to
/// point the user at the matching settings section.
public enum ServiceKind: String, CaseIterable, Codable, Hashable, Sendable {
    case sonarr
    case radarr
    case jellyfin

    /// Product name; not translated.
    public var name: String {
        switch self {
        case .sonarr: "Sonarr"
        case .radarr: "Radarr"
        case .jellyfin: "Jellyfin"
        }
    }
}
