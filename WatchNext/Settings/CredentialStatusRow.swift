import SwiftUI
import WatchNextAppearance

struct CredentialStatusRow: View {
    @Environment(\.palette) private var palette
    let name: String
    let isStored: Bool

    var body: some View {
        LabeledContent(name) {
            Label(isStored ? String(localized: .settingsCredentialsStoredLabel) : String(localized: .settingsCredentialsMissingLabel), systemImage: isStored ? "checkmark.circle" : "xmark.circle")
                .foregroundStyle(isStored ? palette.ready : palette.alert)
        }
    }
}
