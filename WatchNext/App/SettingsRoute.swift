import WatchNextCore

/// Pushed destinations inside the Settings tab, so other screens can deep-link.
enum SettingsRoute: Hashable {
    /// The Servers page, scrolled to one server's section when given.
    case servers(ServiceKind?)

    var service: ServiceKind? {
        switch self {
        case .servers(let service): service
        }
    }
}
