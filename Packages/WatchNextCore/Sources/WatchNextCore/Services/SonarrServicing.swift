import Foundation

public protocol SonarrServicing: Sendable {
    func testConnection() async throws -> ServiceHealth
    func fetchEpisodes(recentSince: Date, futureThrough: Date) async throws -> [SonarrEpisode]
}
