# T-004: Location at capture, Memory detail, Map (rest of M2 + M3, no AR)

- Status: Todo
- Date opened: 2026-11-12
- Related decisions: ADR 0001, 0002, 0003, 0004, new 0007 (location), 0008 (schema evolution), 0009 (navigation and map). T-002 (AR) stays parked.
- Notes: security-checklist, smooth-ux-rules, privacy-accessibility-checklist, swiftdata-gotchas, corelocation-ios17
- Author: Danny (spec). Mark implements. Rule from the user: commit after each finished screen/step, tests green.

## Acceptance criteria
- Capture: with permission, coordinate and place name fill in without blocking Save and without a spinner. Denied, restricted, timeout or geocode failure still saves. The user can edit the place and remove the location. A late geocode result never overwrites what the user typed. No coordinate is ever logged.
- Detail: full photo, title, note, place, date/time, "Private" chip, Delete with confirmation. No "View in AR" button.
- Map: markers for memories with coordinates, tap shows a peek sheet that expands to Detail; round white Map button on Home next to Add; Map requests no permission.
- Data from the 4cde0ca build survives installing the new build over it. Tests green on simulator (iOS 26) and the app verified on the iPhone 11 Pro (iOS 17.4.1).

## Step 0: fix T-003 review findings (verify with new tests)
1. `PhotoStore.save`: if the thumbnail write fails, remove the full file too (no orphan). Test: force a thumb write failure.
2. Soft delete scrubs title, body, placeName, photoFileName (and coordinates once they exist), keeping id, updatedAt, isSoftDeleted. Test.
3. Delete asks for confirmation (`confirmationDialog`) and has an `.accessibilityAction(named: "Delete")`; shared with Detail later.
4. Home grid collapses to 1 column at accessibility Dynamic Type sizes.
5. Cancel button disabled while saving.
6. Photo picker uses `.task(id: pickerItem)` so older loads are cancelled.
7. Input limits consistent: one helper for title, body, place applied while typing; limits as constants in Domain (`Memory.Limits`).
8. Store file protection: put the SwiftData store in its own directory with `.completeUnlessOpen` (ModelConfiguration(url:)), keep behaviour on first launch and on install-over. Not verifiable on the simulator; record the result honestly in the ticket. If it cannot be made to work, say so and leave the iOS default, updating security-checklist to match.
Nits to take if the code is touched: error colour with 4.5:1 contrast plus VoiceOver announcement; `HomeViewModel.makeCapture()` instead of the view building the Capture VM; pixel cap (about 100 MP) in PhotoStore; error message visible without scrolling; delete file off-main; tests for HomeViewModel (delete removes file), double save, oversized or corrupt image, unknown `kindRaw` filtered from `all()`.

## Step 1: Coordinate and schema (ADR 0007, 0008)
- `Domain/Coordinate.swift`: failable init (rejects NaN and out-of-range), Sendable, Hashable, redacted `description`/`debugDescription`. No CoreLocation import.
- `Memory.coordinate: Coordinate? = nil`; `MemoryRecord.latitude/longitude: Double?` (memory only built when both valid).
- `Memory+Samples`: add located samples under `#if DEBUG` per notes/sample-data.md.
- Tests: validity, redaction, round trip, only-lat gives nil, add/all keeps coordinate, soft delete scrubs.
- Device check: install 4cde0ca data first, install over, old memories still show.

## Step 2: Location at Capture
- Domain protocols `LocationProviding` (authorization, requestWhenInUse, currentCoordinate) and `PlaceNaming`; adapters `SystemLocationProvider` and `CLGeocoderPlaceNamer` in `Platform/` (only files importing CoreLocation); pure `PlaceNameFormatter` (POI first, then street, then locality; trim; 100 chars).
- `CaptureViewModel` takes both protocols (defaults so old tests compile): `coordinate`, `locationState`, `placeEditedByUser`, `startLocating()` from the sheet's `.task`, `clearLocation()`, cancels on dismiss and save.
- `CaptureSheet`: one status line under Place ("Finding your place..." as placeholder, no spinner), small remove-location button, Settings link when denied.
- `project.yml`: `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` ("Morrow uses your location while you create a memory, to pin it on the map and suggest a place name."). No Always key.
- Edge cases: permission changed in Settings while sheet is open (re-check on scenePhase active); Location Services off = denied; airplane mode gives coordinate only; restricted = denied without a Settings link; result arriving after Save is ignored.
- Tests with fakes: authorized fills both; denied still saves; timeout still saves; geocode failure keeps coordinate; user-typed place not overwritten; clearLocation saves nil; save while locating; formatter cases.
- Device only: real GPS fix time and accuracy, approximate-location prompt, deny then re-enable, airplane mode.

## Step 3: Memory detail and navigation (screen, commit when done)
- `Features/Detail/MemoryDetailView.swift`: full photo (rounded bottom 34), heavy title, full note with text selection, place chip, `createdAt.formatted(date: .long, time: .shortened)`, "Private" chip, Delete with the shared confirmation.
- `Route` enum and `NavigationStack(path:)` in `HomeView`; card action pushes `.memory(id)`; Detail looks up by id in `model.memories` and pops if gone. Navigation bar hidden with a `CircleIconButton` Back (check swipe-back; fallback native back button with hidden background).
- `StoredPhotoView` gets a variant (thumbnail or full) rather than a new view; `PhotoStore` gets a display-size read (about 1600 px, off-main). Show the thumbnail first, crossfade to full (0.2 s).
- Accessibility: photo labelled with title, text styles throughout, Back labelled.
- Tests: delete removes file and entry; lookup of a deleted id is nil; Detail label function.
- Device only: swipe-back, push smoothness with a large photo.

## Step 4: Map and Map button (screen, commit when done)
- `Features/Map/MapView.swift` with SwiftUI `Map(position:selection:)`, `Marker(...).tint(action).tag(id)`; peek sheet `.presentationDetents([.height(168), .large])`, `.presentationBackgroundInteraction(.enabled(upThrough: .height(168)))`, drag indicator; peek row (thumbnail, title, place), tap expands to `.large` where `MemoryDetailView` is built; camera recentres on the selected pin so it is not under the sheet.
- Pure `MapPins.pins(from:)` and `MapFraming` (empty = fixed default region, one pin = minimum span, many = bounds + padding), computed outside `body`.
- Home: white `CircleIconButton(systemImage: "map", label: "Map")` next to Add, pushes `.map`. Map takes `memories` and `onDelete` from `HomeViewModel`.
- Edge cases: no located memories shows "No memories with a location yet"; memory deleted while peek is open closes the sheet; identical coordinates overlap (accepted, listed below).
- Tests: MapPins, MapFraming with fake coordinates.
- Device only: pan/zoom FPS with about 200 seeded pins (record the number before any clustering), peek sheet with map gestures.

## Step 5: Manual acceptance on the iPhone 11 Pro
Capture photo and note with location; deny permission and still save; kill and relaunch; open Detail, delete with confirmation; open Map, tap a pin, drag the peek up; VoiceOver through Home, Detail, Map; accessibility Dynamic Type; airplane mode; Instruments for Home scroll and Map pan FPS, numbers written here.

## Implementation summary
(fill in per step)

## Review outcome (Danny)
(pending)

## Open issues
- Pin uses the position at capture, not where a library photo was taken; reading photo GPS is a later, separate decision.
- Editing the place after saving is not in the MVP.
- Marker clustering waits for measurements.
- "View in AR" waits for T-002.
- Hard-deleting tombstones waits for sync (M5). Orphan photo sweep at M6.
