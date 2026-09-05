import SwiftUI
import WatchNextCore

struct CachedArtworkView: View {
    let cacheKey: String?
    @State private var data: Data?

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "film")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 56, height: 80)
        .background(.quaternary)
        .clipShape(.rect(cornerRadius: 8))
        .task(id: cacheKey) {
            guard let cacheKey else { return }
            data = await ArtworkDataStore.shared.data(for: cacheKey)
        }
    }
}
