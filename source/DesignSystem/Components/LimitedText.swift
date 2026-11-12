import SwiftUI

extension View {
    /// Caps a text binding while the user types, so limits are enforced the same way everywhere.
    func limitedLength(_ text: Binding<String>, to limit: Int) -> some View {
        onChange(of: text.wrappedValue) { _, value in
            if value.count > limit { text.wrappedValue = String(value.prefix(limit)) }
        }
    }
}
