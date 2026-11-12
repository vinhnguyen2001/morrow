# SwiftUI accessibility on Button

- Date: 2026-11-12
- Topic: convention

## Content
- A `Button` is already one accessibility element with the button trait. Do not stack `.accessibilityElement(children: .ignore)` or `.accessibilityAddTraits(.isButton)` on it. Apply `.accessibilityLabel(...)` only (Danny, T-001 round 1).
- Combined custom labels (MemoryCard) should read "<Kind>, <title>, at <place>, button" in VoiceOver. Verify on a Mac.
- Icon-only buttons (CircleIconButton) take a mandatory `label` parameter.
- Decorative symbols inside a combined element get `.accessibilityHidden(true)` so the label is not read twice (Chip).
