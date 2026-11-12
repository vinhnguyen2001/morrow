# ADR 0010: Full Home per design (reopens ADR 0003 for Home)

- Status: Accepted with the user's changes (2026-11-12): system font kept (ADR 0004 unchanged), Journeys row hidden (ADR 0011 deferred), notification button and "nearby" badge shown as placeholder chrome
- Date: 2026-11-12
- Deciders: user (asked for "full as the design"), Danny

## Decision
Replaces these parts of ADR 0003 only:
- Home is no longer "simple list + Map + Add". It becomes: header with logo, Journey / Notes / Places tabs, Journeys row, "Recent moments" timeline, local search, floating Map and Add buttons (T-005).
- Journeys, Notes/Places tabs, search and tilt/leaf polish leave the deferred list.
- Still deferred: notifications, share, friends, collaboration, public discovery, moderation, dark mode, list/checkin kinds, multi-step create, detailed settings.
- Rules: no fake data shown as real (simulation only in previews and DEBUG fixtures); an element that cannot be real is hidden, not shown dead.
Other ADRs: 0002 (icons are not SF-Symbols-only; leaves, sprout, empty illustration and connectors are custom Shapes; Add colour #1E3B2F), 0004 (only if Inter is chosen: bundle Inter OFL, `Font.custom(_:size:relativeTo:)`, and correct the wrong claim that Inter needs manual Dynamic Type handling), 0008 (a new @Model entity is also lightweight migration, still install-over verified), 0009 (`Route` gains `.journey(UUID)` and `.place(String)`).

## Consequences
Home becomes the largest screen: more accessibility and performance surface; measure FPS before optimising.

## Known deviation from "no fake data"
At the user's explicit request the notification button ("2 new", red dot) and the Map "nearby" badge are placeholders. They are gathered in one constant, are release blockers for TestFlight (M6), and must not be described to VoiceOver as real data.

## Deviations from the design (T-005 steps 1-2)
- Date badge is centred on the spine (the design's margin-left -23 made the spine run through the text).
- The first memory row can be on the right: the left/right index counts from the OLDEST memory so adding a memory never moves old rows.
- Header shadow is slightly darker than the design (the app's card shadow is reused).
- Empty state drops the phrase "planted where you are".
- The logo is off-centre exactly as in the design (space-between); rebalance at step 5 when Search fills the left slot.

