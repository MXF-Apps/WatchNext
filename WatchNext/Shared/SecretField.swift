import SwiftUI

/// A masked text field with an eye button that shows or hides what was
/// typed, so a key can be checked before saving and stays hidden on screen
/// (and in screen recordings) otherwise.
struct SecretField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType? = nil
    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(contentType)
            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
            // Borderless, so the row itself does not become the button.
            .buttonStyle(.borderless)
            .accessibilityLabel(String(localized: isRevealed ? .settingsCredentialsConcealAccessibilityLabel : .settingsCredentialsRevealAccessibilityLabel))
        }
    }
}
