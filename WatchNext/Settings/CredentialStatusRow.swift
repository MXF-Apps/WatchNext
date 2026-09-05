import SwiftUI

struct CredentialStatusRow: View {
    let name: String
    let isStored: Bool

    var body: some View {
        LabeledContent(name) {
            Label(isStored ? "Stored" : "Missing", systemImage: isStored ? "checkmark.circle" : "xmark.circle")
                .foregroundStyle(isStored ? .green : .red)
        }
    }
}
