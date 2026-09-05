import Foundation
import WatchNextLogging

public actor AppGroupConfigurationStore: ConfigurationStoring {
    private let defaults: UserDefaults
    private let key = "WatchNext.ServiceConfiguration"
    private let logger: WatchNextLogger

    public init(
        appGroupIdentifier: String = WatchNextConstants.appGroupIdentifier,
        logger: WatchNextLogger = .shared
    ) {
        self.logger = logger
        if let defaults = UserDefaults(suiteName: appGroupIdentifier) {
            self.defaults = defaults
        } else {
            self.defaults = .standard
            logger.warning(
                "App Group \(appGroupIdentifier) is unavailable; using standard defaults.",
                category: "Configuration"
            )
        }
    }

    public func load() -> ServiceConfiguration {
        guard let data = defaults.data(forKey: key) else {
            logger.debug("No saved service configuration was found.", category: "Configuration")
            return ServiceConfiguration()
        }
        do {
            let configuration = try JSONDecoder().decode(ServiceConfiguration.self, from: data)
            logger.debug("Loaded service configuration.", category: "Configuration")
            return configuration
        } catch {
            logger.error("Could not decode service configuration.", error: error, category: "Configuration")
            return ServiceConfiguration()
        }
    }

    public func save(_ configuration: ServiceConfiguration) throws {
        defaults.set(try JSONEncoder().encode(configuration), forKey: key)
        logger.debug("Saved service configuration.", category: "Configuration")
    }
}
