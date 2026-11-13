import Foundation

/// The one way Morrow compares text without case, accents or width (search, place grouping, city names).
enum TextMatching {
    /// Lowercase, accent-free, trimmed form of `text`: "Đà Nẵng", "ĐÀ NẴNG" and "da nang" give "da nang".
    /// `Đ`/`đ` (U+0110/U+0111) have no Unicode decomposition, so `.diacriticInsensitive` leaves them; they are
    /// replaced by "d" before folding. A string in NFD (e.g. pasted from macOS) gives the same result because
    /// folding splits the marks off. The rare "D + U+0335" (a combining stroke) is not handled.
    /// `locale: nil` keeps the result independent of the device language.
    static func key(_ text: String) -> String {
        text.replacingOccurrences(of: "Đ", with: "d")
            .replacingOccurrences(of: "đ", with: "d")
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
