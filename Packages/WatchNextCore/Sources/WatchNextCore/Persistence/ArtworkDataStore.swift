import Foundation

public actor ArtworkDataStore {
    public static let shared = ArtworkDataStore()

    public init() {}

    public func data(for cacheKey: String) -> Data? {
        guard let url = ArtworkLocation.fileURL(for: cacheKey) else { return nil }
        return try? Data(contentsOf: url)
    }
}
