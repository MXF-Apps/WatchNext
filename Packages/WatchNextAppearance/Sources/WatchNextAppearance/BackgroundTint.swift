import SwiftUI

/// Hue pair for the background gradient: `primary` at the top-left corner,
/// `secondary` at the bottom-right. Names are palettes, not raw colors, so a
/// choice stays meaningful if the exact hues are tuned later.
public enum BackgroundTint: String, CaseIterable, Identifiable, Sendable {
    case indigo
    case ocean
    case orchid
    case sunset
    case forest
    case ember
    case graphite
    /// Neutral washes: grain without a hue, brighter or darker than the base.
    case white
    case black

    public var id: Self { self }

    public var primary: Color {
        switch self {
        case .indigo: .indigo
        case .ocean: .blue
        case .orchid: .purple
        case .sunset: .orange
        case .forest: .green
        case .ember: .red
        case .graphite: .gray
        case .white: .white
        case .black: .black
        }
    }

    public var secondary: Color {
        switch self {
        case .indigo: .teal
        case .ocean: .cyan
        case .orchid: .pink
        case .sunset: .pink
        case .forest: .mint
        case .ember: .orange
        case .graphite: .gray
        case .white: .white
        case .black: .black
        }
    }
}
