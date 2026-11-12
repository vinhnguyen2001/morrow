import SwiftUI
import UIKit

/// Shows a stored photo. A cache hit shows at once; a miss reads and decodes off the main actor and fills
/// `ThumbnailCache`. The placeholder colour shows until the image is ready.
/// `.display` (Detail) shows the thumbnail first, then fades to the larger picture (not cached: it is big).
struct StoredPhotoView: View {
    enum Variant { case thumbnail, display }

    let fileName: String
    let store: PhotoStore
    let placeholder: Color
    var variant: Variant = .thumbnail
    /// VoiceOver label. Nil hides the photo from VoiceOver (decorative inside a card that is already labelled).
    var accessibilityText: String?
    var cache: ThumbnailCache = .shared
    @State private var image: UIImage?
    @State private var displayImage: UIImage?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // The image is an overlay so its pixel size never decides the layout size (it made cards
        // wider than their column); the placeholder colour takes the size the parent offers.
        placeholder
            .overlay {
                ZStack {
                    if let shown = cache.image(for: fileName) ?? image { photo(shown) }
                    if let displayImage { photo(displayImage).transition(.opacity) }
                }
            }
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText ?? "")
            .accessibilityAddTraits(.isImage)
            .accessibilityHidden(accessibilityText == nil)
            .task(id: fileName) { await load() }
    }

    private func photo(_ uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
    }

    private func load() async {
        displayImage = nil
        let store = store
        let name = fileName
        // Take a cache hit into state now: if NSCache evicts it later, body must still have it.
        if let cached = cache.image(for: name) {
            image = cached
        } else {
            image = nil
            let decoded = await Self.decode { store.thumbnailData(for: name).flatMap { UIImage(data: $0)?.preparingForDisplay() } }
            if let decoded { cache.insert(decoded, for: name) }
            image = decoded
        }
        guard variant == .display else { return }
        let large = await Self.decode { store.displayImage(for: name).map { UIImage(cgImage: $0) } }
        guard !Task.isCancelled, let large else { return }
        // Reduce Motion: swap without the fade.
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { displayImage = large }
    }

    private static func decode(_ work: @escaping @Sendable () -> UIImage?) async -> UIImage? {
        await Task.detached(priority: .userInitiated, operation: work).value
    }
}
