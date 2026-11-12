# ADR 0003: MVP scope, AR validated first

- Status: Accepted (user goal: ship fast and cheap; AR must feel fast or nobody uses it)
- Date: 2026-11-12
- Deciders: user, Danny

## Problem
The prototype includes journeys, friends, collaboration, sharing, notifications, public discovery and a 4-step create flow. For a solo developer on a small budget that is a social network. The core hypothesis is: "capture a moment at a place, come back, open AR and see it fast."

## Decision
MVP keeps 4 screens and 1 sheet:
1. Home: simple list of own memories (MemoryCard), Map button, Add button.
2. Capture sheet, one step: photo (PhotosPicker) or note + title, current location auto-filled, private by default, saved locally immediately.
3. Map: MapKit with own pins and a peek sheet, button to open AR.
4. AR: 4 states (permission, scanning, live, nothing nearby).
5. Memory detail with "View in AR".

Deferred: journeys, place detail, Notes/Places tabs, search, detailed settings (keep minimum: sign out, delete account, privacy), multi-step create, list and checkin kinds, notifications, share, friends, public discovery and moderation, dark mode, tilt/leaf polish.

Milestones (reordered 2026-11-12 by the user: screens first, AR later. Danny's concern is recorded: AR is the riskiest part and may force a change to Capture, for example an optional scan step when planting; Home, Capture, Detail and Map are needed under any AR approach so the waste is small):
- M0 skeleton, tokens, MemoryCard (done, built and tested on Mac; see T-001).
- M2 local persistence (SwiftData) + Capture + Home with real data (slice 1 done, see T-003; location auto-fill next).
- M3 Memory detail, Map.
- M1 AR spike on the iPhone 11 Pro with fake data (parked; spec in T-002). Decision gate: if "time to first memory" is above 3 s, fix or change approach before M4.
- M4 AR complete.
- M5 backend sync (backend not chosen yet, see ADR 0001).
- M6 hardening, accessibility, privacy manifest, TestFlight.

## Consequences
- Only two memory kinds (photo, note) in the model for now; enum is extensible.
- No PostGIS, no push, no moderation until public content exists.
