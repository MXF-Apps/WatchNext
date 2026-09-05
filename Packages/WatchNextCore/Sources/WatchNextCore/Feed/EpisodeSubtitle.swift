enum EpisodeSubtitle {
    static func make(season: Int, episode: Int, title: String?) -> String {
        let code = "S\(padded(season))E\(padded(episode))"
        guard let title, title.isEmpty == false else { return code }
        return "\(code) — \(title)"
    }

    private static func padded(_ value: Int) -> String {
        value < 10 ? "0\(value)" : String(value)
    }
}
