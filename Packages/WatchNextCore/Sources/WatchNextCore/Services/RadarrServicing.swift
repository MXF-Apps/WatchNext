import Foundation

public protocol RadarrServicing: Sendable {
    func testConnection() async throws -> ServiceHealth
    func fetchMovies(recentSince: Date, futureThrough: Date) async throws -> [RadarrMovie]
}
