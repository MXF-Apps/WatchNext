import Foundation

public enum ArtworkLocation {
    public static func fileURL(
        for cacheKey: String,
        appGroupIdentifier: String = WatchNextConstants.appGroupIdentifier
    ) -> URL? {
        guard let directory = directoryURL(appGroupIdentifier: appGroupIdentifier) else { return nil }
        let safeName = cacheKey.unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? String(scalar) : "-"
        }.joined()
        return directory.appending(path: "\(safeName).image")
    }

    /// The poster directory in the App Group container, or nil without one.
    public static func directoryURL(
        appGroupIdentifier: String = WatchNextConstants.appGroupIdentifier
    ) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appending(path: WatchNextConstants.artworkDirectoryName, directoryHint: .isDirectory)
    }

    /// Deletes every cached poster. A missing directory is not an error.
    public static func removeAll(
        appGroupIdentifier: String = WatchNextConstants.appGroupIdentifier
    ) throws {
        guard let directory = directoryURL(appGroupIdentifier: appGroupIdentifier) else { return }
        do {
            try FileManager.default.removeItem(at: directory)
        } catch CocoaError.fileNoSuchFile {
            return
        }
    }
}
