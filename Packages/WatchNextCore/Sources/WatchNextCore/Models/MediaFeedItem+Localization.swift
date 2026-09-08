import Foundation

public extension MediaFeedItem {
    /// Subtitle for display. Episodes show their code and title; movies show
    /// nothing, because with only two kinds the missing episode line already
    /// says "movie". The cached `subtitle` keeps whatever the builder wrote.
    var localizedSubtitle: String? {
        kind == .movie ? nil : subtitle
    }
}
