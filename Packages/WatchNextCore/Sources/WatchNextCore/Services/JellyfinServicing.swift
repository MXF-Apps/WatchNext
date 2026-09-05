public protocol JellyfinServicing: Sendable {
    func testConnection() async throws -> ServiceHealth
    func authenticate(username: String, password: String) async throws -> JellyfinAuthentication
    func fetchUsers() async throws -> [JellyfinUser]
    func fetchLibrary(userID: String) async throws -> [JellyfinMediaItem]
}
