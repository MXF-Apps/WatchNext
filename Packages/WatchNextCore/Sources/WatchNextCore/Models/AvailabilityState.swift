public enum AvailabilityState: String, Codable, Sendable {
    case comingSoon
    /// Aired or released, still monitored, and not imported yet: Sonarr or
    /// Radarr is expected to be searching for it.
    case awaitingDownload
    case downloading
    case ready
}
