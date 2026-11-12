# T-001: Skeleton, design tokens, shared components, MemoryCard (M0)

- Status: Done (approved round 2, not compiled)
- Date opened: 2026-11-12
- Related decisions: ADR 0001 (Domain stays free of SwiftUI and backend SDKs), ADR 0002 (Chronicle v2 tokens), ADR 0004 (iOS 17, iPhone, SF Pro via tokens)

## Requirement / acceptance criteria
- iPhone only, portrait, iOS 17+, light only, SwiftUI, no third-party deps.
- Chronicle v2 tokens (colours, radii, shadow, type tints), system font behind a token layer.
- CircleIconButton, Chip, shadow modifier, per-ID tilt, GroundView, MemoryCard (photo + note, compact + wide), preview gallery, unit tests.
- No persistence, backend, map or AR.

## Implementation summary
- All code lives in `source/`. XcodeGen `source/project.yml` (dev-only tool; no hand-written pbxproj). Info.plist keys set through build settings.
- `MemoryKind` enum (photo, note); every switch is exhaustive so adding list/checkin is compiler-guided.
- `MemoryKindStyle` (DesignSystem) maps kind to tint, keeping Domain UI-free.
- `Tilt` uses FNV-1a over UUID bytes (stable; `hashValue` is not).
- Photo cards show a placeholder until persistence supplies images.
- Card shadow second layer approximates CSS spread -12 (SwiftUI has no spread).

## Files touched
source/project.yml, source/App/MorrowApp.swift, source/Domain/*, source/DesignSystem/Tokens/*, source/DesignSystem/Components/*, source/Features/Gallery/MemoryCardGallery.swift, source/MorrowTests/*

## Review outcome (Danny)
Round 1: changes requested, fixed items 1-13 (no `#if DEBUG` on app-used fixtures, TiltModifier honours Reduce Motion, no redundant a11y modifiers on Button, UUID literals, pinned FNV-1a test vectors, icon/glyph font tokens, deduplicated colour literals, Chip takes colours not a kind style, `label` param on CircleIconButton, type scale tweak, note time, test scheme, nits).
Round 2: APPROVED, no compile blockers found. Follow-up C applied (fixed `createdAt` literals in samples).

## Open issues
- NOTHING WAS COMPILED OR RUN (written on Windows). First Mac build may need small fixes.
- (A) On Mac decide the `body` font, likely `.footnote` (13pt): `cardTitleCompact` and `body` now differ only by weight.
- (B) Note card shows a time the accessibility label does not read. Deliberate deferral; becomes a requirement of the M3 Home ticket with a MemoryStyleTests update.
- Mac verification checklist (Danny):
  - Build Release once.
  - Run `xcodebuild test` via the Morrow scheme.
  - Compare card shadow second layer at opacity 0.18-0.22 vs current 0.30.
  - VoiceOver reads a card as "<Kind>, <title>, at <place>, button".
  - Reduce Motion renders cards untilted.
  - Check the type scale side by side with the design (headline/subheadline choice).
  - Confirm `Color(hex:)` equality works in MemoryStyleTests (tint tests compare `Color` values).
- M3 Home inherits: time in card label, LazyVStack, measure scroll FPS of the two-layer card shadow before changing it (candidate fix: shadow on background shape, then compositingGroup), two-column collapse at accessibility sizes.
- Preview and visual match to design not checked.
- Chip is non-interactive; tappable chips need a Button wrapper with 44pt area.
