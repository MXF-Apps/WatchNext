import SwiftUI

struct CredentialStatusRow: View {
    let name: String
    let isStored: Bool

    var body: some View {
        LabeledContent(name) {
            Label(isStored ? String(localized: .settingsCredentialsStoredLabel) : String(localized: .settingsCredentialsMissingLabel), systemImage: isStored ? "checkmark.circle" : "xmark.circle")
                .foregroundStyle(isStored ? .green : .red)
        }
    }
}
