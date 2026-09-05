import SwiftUI

struct WidgetArtworkView: View {
    let cacheKey: String?
    let artwork: [String: Data]

    var body: some View {
        Group {
            if let cacheKey, let data = artwork[cacheKey], let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "film")
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 34, height: 48)
        .background(.quaternary)
        .clipShape(.rect(cornerRadius: 6))
    }
}
