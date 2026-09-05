public enum ConnectionStatus: Equatable, Sendable {
    case idle
    case testing
    case connected(String)
    case failed(String)
}
