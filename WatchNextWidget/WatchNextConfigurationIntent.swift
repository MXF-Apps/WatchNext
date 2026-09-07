import AppIntents
import WatchNextCore

struct WatchNextConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = LocalizedStringResource("widget.configuration.title", defaultValue: "WatchNext")
    static let description = IntentDescription(LocalizedStringResource("widget.configuration.description", defaultValue: "Shows your ready-to-watch and upcoming media."))

    /// The `RowDensity` raw value, stored as a plain String on purpose.
    ///
    /// iOS 26.5 fails to decode `AppEnum` widget parameters: the host sends
    /// `density = comfortable`, the extension logs `Prepared density to
    /// RowDensity(nil)` and silently falls back to the default. The same build
    /// decodes the enum correctly on iOS 26.4. Primitive parameters are
    /// unaffected, so the pickers are provided by options providers and the
    /// values are mapped back through `rowDensity` and `kindFilter`.
    @Parameter(title: LocalizedStringResource("widget.configuration.density.title", defaultValue: "Density"), optionsProvider: RowDensityOptionsProvider())
    var density: String?

    /// A stable media-kind identifier; legacy English display names still decode.
    @Parameter(title: LocalizedStringResource("widget.configuration.content.title", defaultValue: "Content"), optionsProvider: FeedKindOptionsProvider())
    var kind: String?

    @Parameter(title: LocalizedStringResource("widget.configuration.artwork.title", defaultValue: "Show Artwork"), description: LocalizedStringResource("widget.configuration.artwork.description", defaultValue: "Large widget only."), default: true)
    var showsArtwork: Bool

    @Parameter(
        title: LocalizedStringResource("widget.configuration.sectionTitles.title", defaultValue: "Section Titles"),
        description: LocalizedStringResource("widget.configuration.sectionTitles.description", defaultValue: "Small and large widgets. Off replaces the section titles with a divider that carries the overflow counts and the refresh button, which fits more items."),
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
                IntentItem(density.rawValue, title: density.title, subtitle: density.subtitle)
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
                IntentItem(filter.rawValue, title: filter.widgetTitle)
            })
        ])
    }

    func defaultResult() async -> String? {
        FeedKindFilter.all.rawValue
    }
}

extension FeedKindFilter {
    var widgetTitle: LocalizedStringResource {
        switch self {
        case .all: .widgetContentAllTitle
        case .movies: .widgetContentMoviesTitle
        case .shows: .widgetContentShowsTitle
        }
    }
}
