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
### Step 0 (done, 31 unit tests green on simulator iOS 26)
- Items 1-7 done with tests: thumb-write failure removes the full file; `MemoryRecord.scrub()` on soft delete; `deleteConfirmation(for:)` modifier plus "Delete" accessibility action; 1 column at accessibility Dynamic Type; Cancel disabled while saving; `.task(id: pickerItem)` (cancelled loads do not clear the photo); `Memory.Limits` plus `limitedLength` modifier.
- Item 8: store now opens at `Application Support/Store/default.store` via `ModelConfiguration(url:)` (`Persistence/StoreLocation.swift`). The directory and files get `.completeUnlessOpen`. A legacy `default.store` (+ -wal, -shm) from 4cde0ca is moved once, main file last. Move logic is unit tested with temp dirs. NOT verified: the protection class itself (simulator ignores it) and the move on a real device with old data. Pending device check: install 4cde0ca, add memories, install this build, memories still show, and check protection if a tool allows.
- Nits taken: `HomeViewModel.makeCapture()`, photo files removed off-main in `delete` (now async), 100 MP pixel cap in `PhotoStore` (not unit tested: needs a huge image), error colour `MorrowColor.error` plus VoiceOver announcement, error message moved to the top of the Capture form. Tests added: HomeViewModel delete, concurrent double save, corrupt and oversized image, unknown `kindRaw` filtered.
- Files: Domain/Memory.swift, DesignSystem/Tokens/MorrowColor.swift, DesignSystem/Components/{DeleteConfirmation,LimitedText}.swift, Persistence/{PhotoStore,MemoryRecord,SwiftDataMemoryRepository,StoreLocation}.swift, Features/Home/*, Features/Capture/*, tests.

### Step 1 (done, 39 unit tests green on simulator iOS 26)
- `Domain/Coordinate.swift` (failable, Sendable, Hashable, redacted descriptions); `Memory.coordinate`; `MemoryRecord.latitude/longitude: Double?` (`memory` builds a coordinate only when both are present and valid; `scrub()` clears them); `Memory.locatedSamples` under `#if DEBUG` (unused by app code).
- Tests: validity, redaction, equality, add/all round trip, only-lat gives nil, invalid stored value gives nil, soft delete scrubs coordinates.
- DONE 2026-11-12 on the iPhone 11 Pro (iOS 17.4.1), build 93a66d7 installed over the 4cde0ca build: backed up the container first (devicectl, phone unlocked). Before: 3 rows (My school, Aircraft [soft-deleted], My niece) with an un-checkpointed 213 KB WAL, 2 photos. After first launch: store moved to `Store/` (old root files gone), same 3 rows, `pragma integrity_check` ok, new `ZLATITUDE` column present and null, photos untouched, app running. NOT verified: the actual protection class (the DEBUG log was not read; os.Logger is not captured by devicectl). Known gap: rows soft-deleted by the old build (Aircraft) were not scrubbed and still hold their title and photo name; consider a one-time scrub at migration.

## Review outcome (Danny)
- Round 1: CHANGES REQUESTED (S1-S4, N2, N5), fixed in "T-004 review round 1 fixes". S3 on-device check of the protection class is done by the orchestrator and user.
- Round 3 (93a66d7): APPROVED. Deferred, non-blocking: S1 (comment says "touching nothing" but reconcile may move a wal back before throwing; better to check "in both places" for all companions first), N1 (stale test counts above; now 48), N2 (`moved`/`names` declared before reconcile), N3 (permanent crash-loop on `rollbackFailed`, accepted: no common path leads there).
- N3 accepted: delete writes the tombstone first, then removes the file; a kill in between leaves an orphan photo, covered by the orphan sweep in M6.
- Round 2: CHANGES REQUESTED, B1 (skipping an existing wal/shm in the target could pair a wrong wal with main) + N1-N3, fixed in "T-004 review round 2: make store move all-or-nothing".

## Open issues
- Pin uses the position at capture, not where a library photo was taken; reading photo GPS is a later, separate decision.
- Editing the place after saving is not in the MVP.
- Marker clustering waits for measurements.
- "View in AR" waits for T-002.
- Hard-deleting tombstones waits for sync (M5). Orphan photo sweep at M6.

### Step 3 (done, 77 unit tests green on simulator iOS 26)
- Files: `Features/Detail/{MemoryDetailView,MemoryDetailPresentation}.swift`, `Features/Navigation/Route.swift` (only `.memory(UUID)`; `.map` joins at step 4), `DesignSystem/Tokens/DetailMetrics.swift`, `StoredPhotoView` (variant `.thumbnail` / `.display`, optional VoiceOver text, crossfade 0.2 s, none under Reduce Motion), `PhotoStore.displayImage(for:)` (1600 px, decode inside the call, run off-main), `HomeViewModel.memory(id:)` and public `calendar`, `HomeView` now owns `NavigationStack(path:)`, cards are Buttons that push `.memory(id)` (context menu Delete and the "Delete" accessibility action stay on the card). `LeafMark` got `size` and `showsVein`; `CircleIconButton` got `showsShadow`.
- Detail shows only real data: photo (or the coloured header for a note), title, place chip (hidden when empty), "Private" chip (data is on the device only), date `createdAt.formatted(.long, .shortened)` in the model's calendar, full note with text selection, Delete (confirmation, plus a "Delete" action on the title). HIDDEN because the app has no such feature: Share, Save/bookmark, Find in AR / Discover in AR, author row and avatar, map card, Edit note, Report, list items. A "Delete memory" button is NEW (not in the design: the design has no delete); white pill, error colour.
- Detail pops by itself when the memory is gone (`.task(id: memory == nil)` calls `dismiss`), so deleting from Detail returns to Home.
- DEBUG fixture: `-MorrowFixtures -MorrowFixtureOpen <1-8>` opens that fixture's Detail. Fixture 7's note was lengthened for the long-text check.
- Visual check on the iPhone 16e simulator (390pt), screenshots in the session scratchpad (not committed): MATCHES the design for photo height 400 with bottom radius 34, Back 44pt at 16/54, content padding 20, chips row at y 420, title 28/800 with -0.3 tracking, 16pt note with line pitch about 26pt (lineSpacing 7 after measuring 24 with 5), coloured note header (118/24/30, "a note" in #5B3FB8, leaf 35%), Back flat with no shadow. DIFFERENT on purpose: date is one line without avatar/author; date text says "at" ("November 12, 2026 at 6:30 PM"), the design has " · "; secondary grey #5C5C5C instead of #7C7C7C (ADR 0002); system font instead of Inter (user decision); Back stays fixed while scrolling (the design's scrolls away). NOT checked: real photo (fixtures are gradients), the crossfade, Dynamic Type at accessibility sizes (chips stack in code), 375pt.
- NOT verified (no touch injection here): tapping a card opens Detail (only the launch argument path was run), swipe from the left edge to go back (code uses `.toolbar(.hidden, for: .navigationBar)` WITHOUT `navigationBarBackButtonHidden`, which keeps the gesture in theory), context menu and VoiceOver action on the card that is now a Button, VoiceOver reading of Detail, push smoothness with a large photo, memory use of the 1600 px decode. Device only, add to step 5.

