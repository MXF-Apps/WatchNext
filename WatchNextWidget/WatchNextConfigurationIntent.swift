import AppIntents
import WatchNextCore

struct WatchNextConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "WatchNext"
    static let description = IntentDescription("Shows your ready-to-watch and upcoming media.")

    /// The `RowDensity` raw value, stored as a plain String on purpose.
    ///
    /// iOS 26.5 fails to decode `AppEnum` widget parameters: the host sends
    /// `density = comfortable`, the extension logs `Prepared density to
    /// RowDensity(nil)` and silently falls back to the default. The same build
    /// decodes the enum correctly on iOS 26.4. Primitive parameters are
    /// unaffected, so the pickers are provided by options providers and the
    /// values are mapped back through `rowDensity` and `kindFilter`.
    @Parameter(title: "Density", optionsProvider: RowDensityOptionsProvider())
    var density: String?

    /// A `FeedKindFilter` display name ("All", "Movies", "Shows"); see `density`.
    @Parameter(title: "Content", optionsProvider: FeedKindOptionsProvider())
    var kind: String?

    @Parameter(title: "Show Artwork", description: "Large widget only.", default: true)
    var showsArtwork: Bool

    @Parameter(
        title: "Section Titles",
        description: "Small and large widgets. Off replaces the section titles with a divider that carries the overflow counts and the refresh button, which fits more items.",
        default: true
    )
    var showsSectionTitles: Bool

    var rowDensity: RowDensity {
        RowDensity(storedValue: density) ?? .smart
    }

    var kindFilter: FeedKindFilter {
        FeedKindFilter(storedValue: kind) ?? .all
    }
}

/// Static choices for the Density parameter, with the enum's titles and subtitles.
struct RowDensityOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        IntentItemCollection(sections: [
            IntentItemSection(items: RowDensity.allCases.map { density in
                IntentItem(density.rawValue, title: LocalizedStringResource(stringLiteral: density.rawValue), subtitle: density.subtitle)
            })
        ])
    }

    func defaultResult() async -> String? {
        RowDensity.smart.rawValue
    }
}

/// Static choices for the Show parameter: All, Movies, Shows.
struct FeedKindOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> IntentItemCollection<String> {
        IntentItemCollection(sections: [
            IntentItemSection(items: FeedKindFilter.allCases.map { filter in
                IntentItem(filter.displayName, title: LocalizedStringResource(stringLiteral: filter.displayName))
            })
        ])
    }

    func defaultResult() async -> String? {
        FeedKindFilter.all.displayName
    }
}

extension FeedKindFilter {
    /// Matches a stored display name or raw value regardless of case.
    init?(storedValue: String?) {
        guard let storedValue else { return nil }
        guard let match = Self.allCases.first(where: {
            $0.displayName.caseInsensitiveCompare(storedValue) == .orderedSame
                || $0.rawValue.caseInsensitiveCompare(storedValue) == .orderedSame
        }) else { return nil }
        self = match
    }
}
