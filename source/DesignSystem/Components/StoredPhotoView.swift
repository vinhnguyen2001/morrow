import SwiftUI
import UIKit

/// Shows a stored thumbnail. A cache hit shows at once; a miss reads and decodes off the main actor
/// and fills `ThumbnailCache`. The placeholder colour shows until the image is ready.
struct StoredPhotoView: View {
    let fileName: String
    let store: PhotoStore
    let placeholder: Color
    var cache: ThumbnailCache = .shared
    @State private var image: UIImage?

    var body: some View {
        // The image is an overlay so its pixel size never decides the layout size (it made cards
        // wider than their column); the placeholder colour takes the size the parent offers.
        placeholder
            .overlay {
                if let shown = cache.image(for: fileName) ?? image {
                    Image(uiImage: shown)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
        .accessibilityHidden(true)
        .task(id: fileName) {
            if cache.image(for: fileName) != nil { return } // drawn straight from the cache
            image = nil
            let store = store
            let name = fileName
            let decoded = await Task.detached(priority: .userInitiated) {
                guard let data = store.thumbnailData(for: name) else { return nil as UIImage? }
                return UIImage(data: data)?.preparingForDisplay()
            }.value
            if let decoded { cache.insert(decoded, for: name) }
            image = decoded
        }
    }
}
