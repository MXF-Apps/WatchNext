import Foundation

public protocol FeedBuilding: Sendable {
    func build(snapshot: SourceSnapshot, configuration: ServiceConfiguration, now: Date) -> WatchNextFeed
}
