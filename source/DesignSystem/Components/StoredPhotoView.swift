import SwiftUI
import UIKit

/// Shows a stored thumbnail. File read and image decode happen off the main actor;
/// the placeholder colour shows until the image is ready.
struct StoredPhotoView: View {
    let fileName: String
    let store: PhotoStore
    let placeholder: Color
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            placeholder
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipped()
        .accessibilityHidden(true)
        .task(id: fileName) {
            let store = store
            let name = fileName
            image = await Task.detached(priority: .userInitiated) {
                guard let data = store.thumbnailData(for: name) else { return nil as UIImage? }
                return UIImage(data: data)?.preparingForDisplay()
            }.value
        }
    }
}
