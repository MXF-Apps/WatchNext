import SwiftUI
import WatchNextAppearance
import WatchNextCore

/// How much detail a row's trailing or secondary hint carries.
enum WidgetHintFormat {
    /// "S04E20", "in 6 days": the large widget has the width.
    case full
    /// "E20", "6d": small and medium, where every point counts and people
    /// already know which season they are on.
    case short
}

struct WidgetItemRow: View {
    @Environment(\.palette) private var palette
    let item: MediaFeedItem
    let artwork: [String: Data]
    let style: WidgetRowStyle
    let showsArtwork: Bool
    let titleFont: Font
    let secondaryFont: Font
    var hintFormat: WidgetHintFormat = .full

    /// Upcoming rows tint their time so the two kinds of row read apart; an
    /// item that is already out but not downloaded shows green instead.
    private var hintColor: Color {
        if item.isAwaitingDownload { return palette.released }
        return isUpcoming ? palette.upcoming : .secondary
    }

    var body: some View {
        Group {
            switch style {
            case .comfortable:
                HStack(alignment: .top, spacing: 8) {
                    if showsArtwork {
                        WidgetArtworkView(cacheKey: item.artworkCacheKey, artwork: artwork)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        title(fixed: false)
                        if let subtitle = item.localizedSubtitle {
                            secondary(subtitle)
                        }
                        WidgetItemStatus(item: item, font: secondaryFont, hintFormat: hintFormat)
                    }
                }
                .accessibilityElement(children: .combine)
            case .compact:
                VStack(alignment: .leading, spacing: 1) {
                    title(fixed: false)
                    if compactBase != nil || item.collapsedEpisodesBadge != nil {
                        secondary(compactBase, badge: item.collapsedEpisodesBadge, color: hintColor, leadingSymbol: awaitingSymbol)
                    }
                }
                .accessibilityElement(children: .combine)
            case .dense:
                denseBody
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var parts = [item.title]
        if let subtitle = item.localizedSubtitle { parts.append(subtitle) }
        if item.availability == .ready {
            parts.append(String(localized: .mediaAvailabilityReadyLabel))
        } else if let time = item.relativeReleaseText(.full) {
            if item.isAwaitingDownload {
                parts.append(String(localized: item.kind == .movie
                    ? .mediaReleaseMovieAccessibilityLabel(time: time)
                    : .mediaReleaseEpisodeAccessibilityLabel(time: time)))
            } else {
                parts.append(time)
            }
        }
        if let count = item.collapsedEpisodeCount {
            parts.append(String(localized: .mediaSeasonAdditionalEpisodesAccessibilityLabel(count: count)))
        }
        return parts.joined(separator: ", ")
    }

    // MARK: Dense

    /// Tries, in order: the full title with the full hint, the full title with
    /// only the essential hint, then a truncated title with the essential hint.
    /// Long titles give up the episode code before they give up characters;
    /// the folded-season count and an upcoming row's time are never dropped.
    @ViewBuilder
    private var denseBody: some View {
        let badge = item.collapsedEpisodesBadge
        let fullDetail = denseDetail
        let essentialDetail = isUpcoming ? denseDetail : nil
        ViewThatFits(in: .horizontal) {
            denseRow(detail: fullDetail, badge: badge, fixedTitle: true)
            if essentialDetail != fullDetail {
                denseRow(detail: essentialDetail, badge: badge, fixedTitle: true)
            }
            denseRow(detail: essentialDetail, badge: badge, fixedTitle: false)
        }
    }

    private func denseRow(detail: String?, badge: String?, fixedTitle: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            title(fixed: fixedTitle)
            Spacer(minLength: 4)
            if detail != nil || badge != nil {
                secondary(detail, badge: badge, color: hintColor, leadingSymbol: awaitingSymbol)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Pieces

    private var isUpcoming: Bool { item.availability != .ready }

    /// A magnifier marks items that aired or released but are not downloaded yet.
    private var awaitingSymbol: String? { item.isAwaitingDownload ? "magnifyingglass" : nil }

    private func title(fixed: Bool) -> some View {
        Text(item.title)
            .font(titleFont.weight(.semibold))
            .lineLimit(1)
            .fixedSize(horizontal: fixed, vertical: false)
    }

    private func secondary(_ text: String, color: Color = .secondary, leadingSymbol: String? = nil) -> some View {
        secondary(text, badge: nil, color: color, leadingSymbol: leadingSymbol)
    }

    /// Secondary text with an optional bold, tinted folded-season badge ("×6")
    /// so the count stands apart from the episode details around it.
    private func secondary(_ text: String?, badge: String?, color: Color = .secondary, leadingSymbol: String? = nil) -> some View {
        HStack(spacing: 3) {
            if let leadingSymbol {
                Image(systemName: leadingSymbol)
                    .accessibilityLabel(String(localized: .mediaDownloadPendingAccessibilityLabel))
            }
            styled(text, badge: badge, color: color)
        }
        .font(secondaryFont)
        // Aired-but-missing rows carry their orange one step heavier.
        .fontWeight(item.isAwaitingDownload ? .semibold : .regular)
        .lineLimit(1)
    }

    private func styled(_ text: String?, badge: String?, color: Color) -> Text {
        let base = text.map { Text($0).foregroundStyle(color) }
        let emphasized = badge.map { Text($0).bold().foregroundStyle(palette.emphasis) }
        switch (base, emphasized) {
        case let (base?, emphasized?): return base + Text(verbatim: " · ").foregroundStyle(color) + emphasized
        case let (base?, nil): return base
        case let (nil, emphasized?): return emphasized
        case (nil, nil): return Text(verbatim: "")
        }
    }

    /// Ready rows keep their subtitle (the section already says "ready");
    /// upcoming rows lead with the time. The folded badge is appended separately.
    private var compactBase: String? {
        let base: [String?] = isUpcoming
            ? [item.relativeReleaseText(hintFormat), item.episodeCode(hintFormat)]
            : [hintFormat == .short ? item.episodeCode(.short).map { subtitleWithout(seasonIn: $0) } ?? item.localizedSubtitle : item.localizedSubtitle]
        return joined(base)
    }

    /// Episode code for ready rows, time for upcoming rows.
    private var denseDetail: String? {
        isUpcoming ? item.relativeReleaseText(hintFormat) : item.episodeCode(hintFormat)
    }

    /// "E20 — Chronoa the Hero" from "S04E20 — Chronoa the Hero".
    private func subtitleWithout(seasonIn code: String) -> String {
        guard let subtitle = item.localizedSubtitle, let range = subtitle.range(of: " — ") else { return code }
        return code + subtitle[range.lowerBound...]
    }

    private func joined(_ parts: [String?], separator: String = " · ") -> String? {
        let present = parts.compactMap { $0 }.filter { $0.isEmpty == false }
        return present.isEmpty ? nil : present.joined(separator: separator)
    }
}
