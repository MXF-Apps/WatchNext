import Foundation

public protocol HTTPTransport: Sendable {
    func data(for request: HTTPRequest) async throws -> Data
}
