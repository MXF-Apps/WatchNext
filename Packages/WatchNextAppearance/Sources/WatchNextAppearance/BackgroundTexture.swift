/// Strength of the gradient and grain drawn behind the app's lists and the widgets.
public enum BackgroundTexture: String, CaseIterable, Identifiable, Sendable {
    case off
    case subtle
    case strong

    public var id: Self { self }
}
