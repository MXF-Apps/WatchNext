import Foundation

public enum ArtworkLocation {
    public static func fileURL(
        for cacheKey: String,
        appGroupIdentifier: String = WatchNextConstants.appGroupIdentifier
    ) -> URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else { return nil }
        let safeName = cacheKey.unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? String(scalar) : "-"
        }.joined()
        return container
            .appending(path: WatchNextConstants.artworkDirectoryName, directoryHint: .isDirectory)
            .appending(path: "\(safeName).image")
    }
}
