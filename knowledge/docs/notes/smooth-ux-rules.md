# Smooth UX rules (no lag)

- Date: 2026-11-12
- Topic: convention
- Source: user requirement ("the app must feel smooth, no lag"). AR-specific numbers are in ar-performance-budget.md.

## Targets
- Scrolling: no dropped frames on an iPhone 12 class device (60 fps, never under 50 for 95% of the time).
- Tap response: visible feedback within 100 ms; screen transition under 350 ms.
- Capture save: card appears in Home immediately (optimistic), under 300 ms after tapping Save.
- Cold launch to first screen with local data: under 1.5 s.
- AR: see ar-performance-budget.md (first memory under 3 s max).

## Rules
1. Main actor stays free: image decoding, file IO, large fetches, geocoding, hashing go off-main.
2. Lists are lazy, IDs are stable UUIDs, row views are small, no per-row blur.
3. Images: thumbnails generated at save time, decoded off-main via CGImageSource, cached; full-resolution only in detail.
4. Scoped @Observable state; derived values computed once.
5. Optimistic UI: save locally first, sync later; placeholders instead of spinners for short waits; no blocking alerts on the critical path.
6. Transitions 0.2 to 0.35 s ease-out, deliberate withAnimation, Reduce Motion honoured.
7. Native sheets with detents; no custom drag physics.
8. Nothing heavy in App.init.
9. os_signpost around user-visible waits; measure in Instruments (Time Profiler, SwiftUI body counts, Core Animation FPS) before and after any optimisation.
10. No optimisation without a measurement. Complexity added for speed must cite a number.

## Verification
- Requires a Mac with Xcode and a real iPhone. Record measurements in the ticket that touched the screen.
- MemoryCard (from T-001, owed by M3 Home): measure scroll FPS of the two-layer card shadow before changing it. Candidate fix if it drops frames: put the shadow on the background shape, then `compositingGroup()`.
- Map (T-004 step 4): FPS of pan/zoom with 200 pins on the iPhone 11 Pro is still owed; consider clustering only after that number exists.
