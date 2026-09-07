import Foundation

/// How tightly a widget packs its rows. Configured per widget via Edit Widget.
enum RowDensity: String, CaseIterable {
    // Legacy storage identifiers. Never translate these values; use title for display.
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

    var title: LocalizedStringResource {
        switch self {
        case .comfortable: .widgetDensityComfortableTitle
        case .compact: .widgetDensityCompactTitle
        case .smart: .widgetDensitySmartTitle
        }
    }

    var subtitle: LocalizedStringResource {
        switch self {
        case .comfortable: .widgetDensityComfortableDescription
        case .compact: .widgetDensityCompactDescription
        case .smart: .widgetDensitySmartDescription
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
