public struct JellyfinAuthentication: Sendable {
    public let accessToken: String
    public let user: JellyfinUser

    public init(accessToken: String, user: JellyfinUser) {
        self.accessToken = accessToken
        self.user = user
    }
}
