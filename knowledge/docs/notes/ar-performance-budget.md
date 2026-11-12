# AR performance budget and approach

- Date: 2026-11-12
- Topic: convention
- Source: Danny's plan. Thresholds are proposals for an iPhone 12 to 13 class device outdoors; adjust after real measurements.

## Budget

| Metric | Target | Max acceptable | How to measure |
|---|---|---|---|
| Tap "AR" to first camera frame | < 0.7 s | 1.2 s | os_signpost, Instruments Points of Interest |
| Tap to first memory panel visible | < 2 s | 3 s | signpost, 20 runs, median and p90 |
| FPS with 5 panels | 60 (or stable 30 by choice) | never below 30 for 95% of time | Instruments Core Animation FPS, Metal System Trace |
| Memory | < 300 MB | < 500 MB | Allocations, VM Tracker; enter/exit AR 10 times to check leaks |
| Thermal | not above .fair after 3 min | .serious not before 10 min | ProcessInfo.thermalState log, real device, unplugged |
| Battery | < 10% per 10 min | < 15% per 10 min | Energy Log; compare with Camera app |
| Network wait on the way into AR | 0 | 0 | Must work in Airplane mode |

Post-release monitoring: MetricKit (MXMetricManager), custom signpost for "time to first memory". No third-party SDK.

M1 is the decision gate: if "first memory" exceeds 3 s on a real device, stop other work and fix or change approach.

## How to keep AR fast
1. AR reads only from SwiftData (coordinates, title, thumbnail). Backend syncs in the background.
2. Load only a radius (about 150 m) via indexed lat/lng bounding box, then filter by distance.
3. Thumbnails about 256 px, 15 to 30 KB, generated at save time, decoded off the main thread.
4. Cap at 5 to 8 panels, nearest and in view; merge close ones into a "+N" chip; share mesh/material; reuse entities.
5. Request camera and location permission at first Add, start ARSession as soon as the AR screen appears, show panels as soon as GPS is available; "scanning" animation is presentation only.
6. Pause session in background; reduce panels and effects when thermalState >= .serious.

## Positioning
- Default: GPS + compass (ARWorldTrackingConfiguration, gravityAndHeading). Works everywhere, 5 to 20 m error, heading drift.
- Optional upgrade: ARGeoAnchor (ARGeoTrackingConfiguration) only where `checkAvailability(at:)` returns true. Coverage is limited to certain cities; Vietnam is likely unsupported. Needs network and takes seconds to localise.
- Fallbacks in order of cost: smoothing of GPS samples with an accuracy ring; manual nudge; per-place ARWorldMap; non-AR compass list mode.
- Expectation to set: panels appear in the right direction at approximate distance, not metre-exact.

## Resolved
- Region: Vietnam. ARGeoTracking unavailable; GPS + compass default, ARWorldMap per place as the precision option (see T-002).
- Device: iPhone 11 Pro (A13), iOS 17. All budgets are measured on it. The user has a Mac with Xcode.
- Rendering on iOS 17: RealityKit ARView in UIViewRepresentable (RealityView is iOS 18+).
- Spec and measurement protocol: tickets/T-002-ar-spike.md (parked until the user starts AR).
