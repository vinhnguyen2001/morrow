# T-003: Local persistence, Capture, Home with real data (M2)

- Status: Implemented slice 1; built, 21 unit tests pass on simulator (iOS 26), launches on iPhone 11 Pro (iOS 17.4.1). NOT yet exercised by hand (capture a photo and a note, kill and relaunch, delete).
- Date opened: 2026-11-12
- Related decisions: ADR 0001 (repository, soft delete), ADR 0002 (Chronicle v2), ADR 0003 (scope), notes/security-checklist.md, notes/smooth-ux-rules.md, notes/swiftdata-gotchas.md
- Design source: knowledge/design/canvas (Main.dc.html)

## Done
- `Domain/MemoryRepository` (main-actor protocol: all, add, soft delete). `Memory` gains `photoFileName`.
- `Persistence/`: `MemoryRecord` (@Model, `isSoftDeleted`, `updatedAt`), `SwiftDataMemoryRepository`, `PhotoStore`.
- `PhotoStore`: input cap 40 MB, full JPEG max 2048 px q0.8, thumbnail max 600 px q0.7, re-encoded via ImageIO without source properties so EXIF/GPS are dropped (tested), written with `.completeFileProtectionUnlessOpen`, encode off the main actor.
- Home: `HomeViewModel`/`HomeView` (2-column lazy grid of `MemoryCard`, tilt, empty state, long-press Delete, round Add button). Cards load thumbnails off-main (`StoredPhotoView`).
- Capture: `CaptureViewModel`/`CaptureSheet`, one step: Photo or Note, title (100), body (2000), optional place (100), saved locally, "Private" label. PhotosPicker needs no permission.
- Composition root in `MorrowApp`. Tests: repository (4), PhotoStore (4), CaptureViewModel (4).

## Deliberately not done (next slices)
- Auto-filled current location and place name (CoreLocation + reverse geocode, When-In-Use string). Place is a plain optional text field for now. Coordinates are not stored yet.
- Map button (M3). Memory detail screen (M3): cards do nothing on tap.
- SwiftData store file protection: uses the iOS default (until first unlock). Stronger protection needs a decision.
- Note card time is not in the VoiceOver label (T-001 open item B).
- Photo and note edit, Settings, Journeys, list/checkin kinds: out of MVP scope (ADR 0003).

## Open / follow-ups
- Hand test on device: capture photo and note, relaunch (persistence), delete, airplane mode, VoiceOver.
- Measure scroll FPS with many photo cards (smooth-ux-rules item 9) before changing the card shadow.
- `CaptureSheet.swift` has a main-actor isolation warning (reads `photoPreview` in a non-isolated closure); becomes an error in Swift 6.
- `fatalError` if the store cannot open: acceptable for now, revisit with a recovery screen before TestFlight.
- Orphaned photo files if the app dies between photo write and DB insert: add a cleanup sweep at hardening (M6).
- Simulator is iOS 26, device is iOS 17.4.1: always run the device after SwiftData changes.
