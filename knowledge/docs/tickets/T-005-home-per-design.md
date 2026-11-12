# T-005: Home per design (full Home, reopens ADR 0003 scope)

- Status: In progress. Step 1 done, step 2 next (see "Implementation summary"). User decisions applied 2026-11-12 (see "User decisions").
- Author: Danny (spec). Mark implements. User rules: one screen/step = one commit, tests green; no dead buttons; no fake data shown as real.
- Related: ADR 0001-0004, 0007-0009, new 0010 (Home scope), 0011 (Journey). Design: knowledge/design/canvas/Main.dc.html (HOME lines 18-209, JOURNEYS 991, rows/segs 1241-1290, TILTS/OFFS 1085-1086), MemoryCard.dc.html.
- Nothing here is compiled; measurements are read from the HTML. Mark re-checks while building.

## User decisions (2026-11-12, override the spec where they differ)
- Font: SYSTEM SF Pro (not Inter). ADR 0004 stays. Still move every `.system(` into `MorrowFont`, choosing the nearest text styles to the design sizes (a small mismatch is accepted). No Inter files, no UIAppFonts.
- Journeys: row HIDDEN. No `Journey` entity, no schema change, no journey marker cards, step 6 is dropped (ADR 0011 deferred). The first tab, which the design calls "Journey", is named "Moments" (orchestrator's assumption: the tab holds the timeline; tell the user) so the control is Moments / Notes / Places.
- Notification button with "2 new" and the "N nearby" badge on the Map button: SHOWN like the design, as PLACEHOLDER chrome. The count and the red dot are not real data. Rules: all placeholders live behind one constant (`MorrowPlaceholders`) with a comment, tapping the notification button shows a small "Notifications are coming soon" message (no fake content), the gear opens a minimal real Settings sheet (app version, "Your memories are stored on this device"), the "nearby" count is a fixed placeholder. Release blocker for TestFlight (M6): remove or make real, and their VoiceOver labels must not claim data that does not exist.
- Order: Home first (steps 1-2), then T-004 step 3-4, then T-005 step 3-5 and 7-8.
- Q6-Q9 defaults apply: mood = computed day part, secondary text #5C5C5C, search on all tabs, Add colour #1E3B2F.

## Order
T-005 step 1-2 (display only) -> T-004 step 3-4 (Detail, Map; adds `Route`) -> T-005 step 3-8. Map button and card taps are wired at step 7, hidden before (same rule as "View in AR").

## Decisions per design element
- Dotted ground: already matches.
- Header: logo (M swoosh `MorrowMark` as Shape, viewBox 34x26, stroke 4 round, #1E3B2F) + "Morrow" 22/800 tracking -0.5, centred; 46pt side slots; reuse `CircleIconButton(diameter: 46)`.
- Search (46pt round button + field): REAL, local filter on title, placeName, body (`localizedStandardContains`, so "hoi an" matches "Hội An"). Step 5. Applies to all 3 tabs (design only filters the timeline).
- Notifications "2 new": HIDDEN everywhere (no notification system, a red dot would be fake data). Settings gear: HIDDEN until a Settings screen exists (M6).
- Segmented Journey / Notes / Places (track #E9E9E9, 40pt pill): REAL UI, `HomeTab`, selected trait for VoiceOver.
- Journeys row ("N journeys", 186pt cards, photo fan max 3, "Travelling now" pill #FFF3C4): REAL from local data via new `Journey` entity (ADR 0011). Start sheet (title, optional destination); End via context menu + accessibility action. Cover = thumbnails of memories inside the date range, glyph if none. No friends/collab/route map.
- "Recent moments" + "since <oldest shown date>": computed.
- Timeline: sprout, spine, day badge 46pt #1E3B2F ("Today" for today, grouped by device calendar), journey begin/end marker cards (#1E3B2F tilt -1.5 / #2B2B2B tilt 1.2), memory rows alternating left/right with tilt, vertical offset, curved connector, dot, leaf, "where it all began" origin. Photo and note only; list, checkin, discovery, place cards DEFERRED (enum has no such kinds).
- Opposite column: time (real) + mood. Mood has no data: replaced by day part computed from the time (morning/afternoon/evening/night) unless the user wants a mood field (Q6).
- Notes tab: "Notes" (no lists yet), "New note" opens Capture with kind note, 2 columns offset 26, lavender, every 3rd peach, tilts [0.6,-0.8,0.3,-0.4].
- Places tab: group by normalised placeName (trim, case and diacritic insensitive); display name = most recent spelling; cover = latest photo else `mappin` glyph; "Last: <date>" replaces the region line; no coordinates needed yet.
- Empty state "Your garden is waiting": drawn with Shapes; copy says "a photo or a note" (no "list"); button opens Capture. "See what travelers left nearby": HIDDEN (public discovery, deferred).
- FABs: Add 64pt #1E3B2F right 20 / bottom 30 (no 45 degree rotation, Reduce Motion); Map 56pt white left, wired at step 7, no "N nearby" badge. Add opens Capture directly (no 5-item menu).
- Secondary text stays #5C5C5C (design #7C7C7C is about 3.7:1, #6E6E6E on #E9E9E9 about 4.2:1; ADR 0002). Deliberate difference, tell the user.
- Font: see below. Add button colour #1E3B2F (code is the source; canvas note says black).

## Data (ADR 0011)
- `Journey { id, title, destination?, startedAt, endedAt? }`, limits title 60, destination 100. `JourneyRecord` @Model (unique id, updatedAt, isSoftDeleted, `scrub()` keeps tombstone). Membership is derived: `memory.createdAt >= startedAt && (endedAt == nil || createdAt < endedAt)`; no change to `MemoryRecord`. At most one running journey, none overlapping; starting one ends the running one in the same save. Queries filter `isSoftDeleted == false` BEFORE reading `endedAt == nil` (a deleted journey must not count as running).
- `JourneyRepository` (@MainActor, own protocol, no generic Repository<T>) + `SwiftDataJourneyRepository` + shared contract test suite. `makeContainer` gains `JourneyRecord`.
- Schema: new entity is additive/lightweight (ADR 0008) but REQUIRES install-over on the iPhone with data: back up the container first (phone unlocked), install over, old 3 memories and 2 photos intact, `integrity_check` ok, `ZJOURNEYRECORD` exists and empty. Never seed the real store.
- Pure functions in `Features/Home/Projection/` (no SwiftUI): `TimelineBuilder.rows(memories:journeys:calendar:now:)` with stable IDs ("sprout", "day-yyyy-MM-dd", "j-<uuid>-begin|end", "m-<uuid>", "origin"), deterministic sort (createdAt desc, then id), days = days with memories plus days with journey markers (a journey starting on an empty day still shows), empty -> []. `Stagger`, `DayPart`, `MemorySearch`, `PlaceGrouping`, `NoteCards`, `JourneySummary`. Left/right, tilt, offset and leaf use the index counted from the OLDEST memory so adding a memory never makes old rows flip or jump (design counts from the top). Tables TILTS [-3, 2.4, -2.2, 3], OFFS [0, 18, 6]; "tall" photo = `k % 3 == 0 ? 150 : 116` (decorative rhythm).
- `HomeViewModel` keeps `init(repository:photoStore:)` (new params default); computes `timelineRows`, `noteCards`, `placeCards`, `journeyCards` once in `refresh()`, not in `body`. Selected tab is `@State` in the view.

## View architecture
New components (reuse `MemoryCard`, `StoredPhotoView`, `CircleIconButton`, `GroundView`, `deleteConfirmation`; do not duplicate card views): `MorrowMark`, `MorrowHeader`, `SproutMark`, `LeafMark`, `GardenIllustration`, `CategorySegmentedControl`, `TimelineConnector`, `DateBadge`, `JourneyMarkerCard`, `TimelineMemoryRow`, `TimelineOrigin`, `JourneyCard`, `JourneyStartTile`, `NoteTile`, `PlaceTile`, `FloatingActionBar`. `MemoryCard` takes an `imageHeight` and its VoiceOver label gains the time (closes T-001 item B).
- Performance: `LazyVStack`, small row views, stable IDs, connectors are `Shape`s (no GeometryReader, no per-item blur, no `drawingGroup` before measuring), shadow on the background shape; watch for sub-point gaps between rows. Measure before optimising (rule 10).
- Accessibility: at accessibility Dynamic Type sizes the timeline becomes one column (spine at the left, no tilt); decorative leaves, spine, sprout hidden from VoiceOver; day badge is one header element ("Thursday, November 12"); marker "Journey begins, <title>"; 44pt targets; Reduce Motion: no tilt, no tab animation.
- Privacy: never log the search query, place names or coordinates; screenshot fixtures never come from the real store.
- Pin the design measurements as `HomeMetrics` constants (with the Main.dc.html line numbers in comments) plus a small test of the key values.

## Font (open question Q2)
- Design uses odd fixed sizes (14.5, 12.5, 11.5, 15.5). SF text styles are 0.5-1pt off everywhere; `Font.system(size:)` has the right size but does not scale with Dynamic Type.
- `Font.custom("Inter-...", size: 14.5, relativeTo: .subheadline)` gives the exact size AND Dynamic Type. ADR 0004's claim that Inter needs manual Dynamic Type handling is wrong; ADR 0010 corrects it.
- Inter is OFL font asset, not an SDK. Cost: file size (measure with `du -h`, not estimated), licence file in repo, `UIAppFonts` via `project.yml`, static weights 600/700/800 (variable font weights are unreliable in SwiftUI). Check Vietnamese diacritics ("Thu Bồn", "Hội An", "Đà Nẵng") on a real screenshot.
- Recommendation: Inter. Regardless of the choice: move every remaining `.system(` (HomeView, MemoryCard bypass `MorrowFont`) into `MorrowFont`, and add a test that each Inter name resolves with `UIFont(name:size:) != nil` (`Font.custom` silently falls back to system).
- Size tokens (px -> MorrowFont): logo 22/800; section 18/800; section meta 13/600; segment 14.5/800 selected, 700 off; date num 19/800; day name 14/800; month-year 12/600; time 14/800; mood 12.5/600; journey title 14/800; dates 12/600; summary 11.5/700; pill 11/800; marker title 15/800; note title 15.5/800; empty h2 24/800; CTA 16/800. New colours: leaf #7CC48A, leafLight #A9DDB2, segmentTrack #E9E9E9, journeyEnd #2B2B2B, nowPill #FFF3C4.

## Key measurements (390pt)
Page padding 54 top (inside safe area), 16 sides, 130 bottom. Header 48 high, buttons 46. Segmented: margin 12, padding 4, gap 4, buttons 40. Journeys: margin top 22, cards 186 wide, gap 12, radius 22, image area 118 (radius 17), fan photos 112x86 with 2pt white border, dx +-26, rotate +-9. Recent moments: margin 8; sprout block 46 high. Date row padding 16/0/12, spine 1.6pt #7CC48A, badge 46 with 4pt ground-coloured ring, offset -23, gap 10. Marker card 270 wide, radius 24, 5pt ring. Memory row padding 6/0/10, dot 12 at top 40, leaf 18, side text padding top 38. Origin: spine 18, dot 10, text 13/600. FABs: Map 56, Add 64, 20 from the side and 30 from the bottom. Notes cards radius 24, padding 15/15/14, column gap 12, second column offset 26. Places cards padding 6, radius 24, image radius 19, second column offset 30, gap 14.

## Steps (one commit each, tests green)
Visual check for every step: `#Preview` plus a DEBUG-only `-MorrowFixtures` launch argument (in-memory container, temp photo directory, generated gradient images, fixed IDs and dates; never touches the real store; Release has no such path). Reference images exported from the canvas into `knowledge/design/reference/` (layout and colour compared, not photos). Capture the simulator at 390x844 (`xcrun simctl io <udid> screenshot`), tick the measurement list in the ticket, also check 375pt. No snapshot-testing library (new dependency needs an ADR).
1. Tokens + font + header (medium): `MorrowFont/MorrowColor/HomeMetrics`, `MorrowMark`, `MorrowHeader`, Inter + OFL + `UIAppFonts` if Q2 = Inter, fixtures. Tests: font names resolve, metrics.
2. Timeline with real data (large): `TimelineBuilder`, `Stagger`, `DayPart`, marks, connector, `DateBadge`, rows, origin, empty state, FAB Add, `MemoryCard` imageHeight and time in label. Tests: day grouping, "Today", deterministic ties, oldest-first stability when adding, stable IDs, empty, midnight boundary, fixed timezone, day-part edges. Measure scroll FPS with 200 memories with photos and `refresh()` time on the iPhone 11 Pro; change shadows only if the numbers are bad. Risks: gaps between rows, A13 render cost of tilt+shadow, scroll jumps. STOP after this step and do T-004 step 3-4.
3. Segmented control + Notes (medium): `CategorySegmentedControl`, `NoteTile`, `NoteCards`, `CaptureViewModel(initialKind:)`.
4. Places tab (medium): `PlaceGrouping` ("Hội An", "hội an ", "Hoi An" become one place; memories without a place skipped; plural "1 memory").
5. Search (small): `MemorySearch`; filter computed in `refresh()`; empty result copy; never logged.
6. Journeys (large, schema change): domain, records, repository, contract tests, membership, summary, cards, start sheet, markers in the timeline, install-over check on the device (mandatory, recorded honestly).
7. Wire Map and detail (medium, after T-004 step 3-4): taps to `.memory(id)`, Map button to `.map`, `Route.journey(UUID)` and `Route.place(String)`, one `FilteredTimelineView` reused for journey and place, visible End button on journey detail.
8. Device acceptance (small): screenshots of 3 tabs, empty, search; accessibility Dynamic Type; Reduce Motion; VoiceOver; Instruments FPS (timeline 200, notes 300, places); numbers into this ticket.

## Questions for the user (defaults if unanswered)
Q1 order: T-005 step 1-2 first, then T-004 step 3-4. Q2 font: Inter. Q3 Journey = trip you start and end, memories in that period belong to it, no friends or collaboration: yes. Q4 Journey/Place detail screens at step 7: yes. Q5 Notifications and Settings gear hidden: yes. Q6 mood: computed day part. Q7 keep #5C5C5C: yes. Q8 search on all tabs: yes. Q9 Add button #1E3B2F: yes.

## Open / risks
- Assumptions not verified: real Inter file sizes; 390pt simulator runtime available (else iPhone 17 at 393pt, note the 1.5pt difference); `localizedStandardContains` with Vietnamese on iOS 17.4.1 (test on both simulator and device).
- Grouping by text can split places typed differently; coordinates later (T-004 step 2).
- Timezone: days follow the device calendar; travelling shifts displayed days (accepted).
- Possible dead code after step 3: `Tilt`/`TiltModifier` if unused (update notes/tilt.md).

## Implementation summary / Review outcome
### Step 1 (Mark, tokens + header)
Files: `DesignSystem/Tokens/HomeMetrics.swift` (new), `MorrowMetrics.swift` (MorrowFont: all `.system(` now live here; new tokens logo, emptyTitle, notice, actionLabel, iconLarge; icon 17 -> 20), `MorrowColor.swift` (notificationDot), `Components/MorrowMark.swift` (Shape + `MorrowLogo`), `Components/FloatingActionBar.swift`, `Components/Toast.swift`, `Components/CircleIconButton.swift` (iconFont param, reused at 46 and 64), `Features/Home/MorrowHeader.swift`, `MorrowPlaceholders.swift`, `HomeView.swift`, `Features/Settings/SettingsSheet.swift`, `Features/Capture/CaptureSheet.swift` (font token only), `App/LaunchFixtures.swift` (DEBUG only), `App/MorrowApp.swift`, `MorrowTests/HomeMetricsTests.swift`.
Deliberate step shift: the Add button moved from the header to `FloatingActionBar` in step 1 (otherwise Add would vanish between steps). The Map button, its badge and `nearbyCount` are NOT built (no destination until step 7; no dead constant).
Decisions: header top = safe area + 7 (design 54 minus the 47pt status bar), not 54 below the safe area. Add/bell/gear use the one `CircleIconButton`. Bell label is "Notifications" (hint "Coming soon"), the dot is decorative and hidden from VoiceOver. Bell tap shows a `Toast` and posts a VoiceOver announcement.
Fixtures: `-MorrowFixtures` (add `empty` for no memories), DEBUG only, returns before `makeContainer`, in-memory SwiftData, temp photo folder, generated gradients, fixed IDs/dates ("now" = 2026-11-12 20:30 UTC+7). Release build compiled and the binary has no "MorrowFixtures" string.
Tests: 52 pass on iPhone 17 simulator (was 47; +5 HomeMetricsTests).
Visual check on iPhone 16e simulator (390pt, iOS 26 runtime; the phone runs iOS 17.4, so system chrome differs). Screenshot taken by `simctl io`, viewed by eye, crops not measured to the pixel:
- Match: header buttons 46pt, top of buttons about 55pt, bell dot position (26pt from button left, top-right), logo mark + "Morrow" green, logo placed by space-between as in the design, Add 64pt 20pt from the right and 30pt from the bottom, #1E3B2F, no rotation.
- Differences: system font instead of Inter (accepted), search slot empty (step 5), Journeys/segments/"Recent moments"/timeline not yet (step 2+), shadows are the app's `morrowCardShadow` not the lighter header shadow.
- Not checked: Settings sheet and toast appearance (no UI automation here); VoiceOver; 375pt width.
