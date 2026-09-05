import Foundation

enum DateCoding {
    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    static func queryString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
