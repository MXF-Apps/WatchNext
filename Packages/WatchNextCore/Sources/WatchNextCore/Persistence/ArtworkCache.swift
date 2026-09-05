import Foundation

public actor ArtworkCache: ArtworkCaching {
    private let transport: any HTTPTransport

    public init(transport: any HTTPTransport = URLSessionTransport()) {
        self.transport = transport
    }

    public func cacheArtwork(
        for feed: WatchNextFeed,
        configuration: ServiceConfiguration,
        credentials: [CredentialKey: String]
    ) async {
        let candidates = Array((feed.ready + feed.comingSoon).prefix(16))
        for item in candidates {
            guard
                let remoteURL = item.artworkURL,
                let cacheKey = item.artworkCacheKey,
                let fileURL = ArtworkLocation.fileURL(for: cacheKey),
                FileManager.default.fileExists(atPath: fileURL.path()) == false
            else { continue }

            do {
                let data = try await transport.data(
                    for: HTTPRequest(url: remoteURL, headers: headers(
                        for: remoteURL,
                        configuration: configuration,
                        credentials: credentials
                    ))
                )
                try FileManager.default.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try data.write(to: fileURL, options: .atomic)
            } catch {
                logger.warning(
                    "Could not cache artwork for item \(item.id).",
                    error: error,
                    category: "Artwork"
                )
                continue
            }
        }
    }

    private func headers(
        for url: URL,
        configuration: ServiceConfiguration,
        credentials: [CredentialKey: String]
    ) -> [String: String] {
        if sameService(url, configuration.jellyfinBaseURL),
           let token = credentials[.jellyfinAccessToken] {
            return ["X-Emby-Token": token]
        }
        if sameService(url, configuration.sonarrBaseURL),
           let key = credentials[.sonarrAPIKey] {
            return ["X-Api-Key": key]
        }
        if sameService(url, configuration.radarrBaseURL),
           let key = credentials[.radarrAPIKey] {
            return ["X-Api-Key": key]
        }
        return [:]
    }

    private func sameService(_ first: URL, _ second: URL?) -> Bool {
        guard let second else { return false }
        return first.host() == second.host() && first.port == second.port
    }
}
