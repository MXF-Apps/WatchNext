import Foundation

/// How tightly a widget packs its rows. Configured per widget via Edit Widget.
enum RowDensity: String, CaseIterable {
    // Raw values double as the text the Edit Widget sheet shows for the
    // current choice, so they are display titles rather than identifiers.
    case comfortable = "Comfortable"
    case compact = "Compact"
    case smart = "Smart"

    /// Matches stored values regardless of case, so widgets configured while
    /// the raw values were lowercase identifiers keep their setting.
    init?(storedValue: String?) {
        guard let storedValue else { return nil }
        guard let match = Self.allCases.first(where: {
            $0.rawValue.caseInsensitiveCompare(storedValue) == .orderedSame
        }) else { return nil }
        self = match
    }

    var subtitle: LocalizedStringResource {
        switch self {
        case .comfortable: "Three lines per item"
        case .compact: "Two lines per item"
        case .smart: "Shrinks rows when that lists more items"
        }
    }

    /// Row styles to try, most comfortable first.
    var rowStyles: [WidgetRowStyle] {
        switch self {
        case .comfortable: [.comfortable]
        case .compact: [.compact]
        case .smart: [.comfortable, .compact, .dense]
        }
    }
}
