import SwiftUI

/// Maps a domain `MemoryKind` to its visual tint. Kept in the design system so Domain stays UI-free.
struct MemoryKindStyle: Equatable {
    let background: Color
    let ink: Color
    let symbolName: String
    let displayName: String

    static func style(for kind: MemoryKind) -> MemoryKindStyle {
        switch kind {
        case .photo:
            return MemoryKindStyle(background: Color(hex: 0xE9E9E4), ink: MorrowColor.ink,
                                   symbolName: "photo", displayName: "Photo")
        case .note:
            return MemoryKindStyle(background: MorrowColor.noteLavender, ink: MorrowColor.noteInk,
                                   symbolName: "note.text", displayName: "Note")
        }
    }
}
