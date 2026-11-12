# T-002: AR spike on device (M1, parked)

- Status: Todo (parked 2026-11-12: user wants screens first; run this before M4 AR)
- Date opened: 2026-11-12
- Related decisions: ADR 0003 (gate), ADR 0004 (iOS 17), notes/ar-performance-budget.md, smooth-ux-rules.md, security-checklist.md
- Device: iPhone 11 Pro (A13), iOS 17. Region: Vietnam, ARGeoTracking unavailable, not planned.
- Author: Danny (spec). Mark implements when started.

## Rendering note
SwiftUI `RealityView` is iOS 18+ on iPhone. On iOS 17 use RealityKit `ARView` in a `UIViewRepresentable`. Approach B also needs direct `ARSession` access (`getCurrentWorldMap`, `initialWorldMap`). Record as ADR 0007 when the spike starts.

## Goal and decision gate
Answer two questions outdoors on the 11 Pro: how fast a saved memory appears, and how close we get to "open the camera, scan, and it appears where I left it".
- PASS: tap-to-first-panel median < 2 s and p90 < 3 s over 20 warm runs; FPS p95 >= 30 with 8 panels; thermal <= .fair after 3 min unplugged; memory < 300 MB.
- FAIL: p90 > 3 s, or FPS p95 < 30, or .serious before 10 min. Then fix (pre-warm session, fewer panels, cached location) or change approach before any more AR work.
- THIRD OUTCOME: speed passes but placement is unsatisfying (wrong direction or > 20 m off). Then Approach B decides.

Honest expectation for the user: A = right direction, roughly right distance, 5 to 20 m error, heading drift. B = exact spot, but only when standing where it was planted, similar lighting, one map file per place. Neither is "scan anywhere and it appears".

## Approach A (mandatory): GPS + compass
- `ARWorldTrackingConfiguration`, `worldAlignment = .gravityAndHeading`: +x east, -z north, origin at session start. Memory at (east dE, north dN) sits at `SIMD3(dE, 0, -dN)` on an `AnchorEntity(world:)`.
- Offset math is a pure function `GeoOffset.enu(fromLat:lon:toLat:lon:)` (flat earth: dN = dLat * 111_320, dE = dLon * 111_320 * cos(lat)); unit tested; on-device sign check against the Compass app on the first run.
- Fixtures: 8 in-memory memories at fixed offsets (10 m N, 20 m E, 15 m S, 30 m W, 25 m NE, 40 m NW, 12 m SE, 50 m SW). Modes: Speed (offsets from the current fix on every open) and Accuracy (Plant once, walk 50 m away, come back, record observed error).
- Panels: `ModelEntity` plane with `UnlitMaterial`, title via `MeshResource.generateText` generated once off the main actor, width max(0.6 m, 0.06 * distance), billboarded on `SceneEvents.Update`. Cap 8.
- `SpikeMetrics` writes both `OSSignposter` intervals and the HUD: tapToFirstFrame, tapToLocationFix (first fix with accuracy <= 20 m, 5 s timeout then best available), tapToFirstPanel. thermalState logged every 10 s. FPS from `SceneEvents.Update` deltas.

## Approach B (measure if A is unsatisfying): ARWorldMap per place
- Plant: Plant enabled only at `worldMappingStatus` .mapped or .extending; add `ARAnchor(name: "spike-memory")` 1 m ahead; `getCurrentWorldMap` -> NSKeyedArchiver (secure coding) -> Application Support/Spike/place.armap with .completeUnlessOpen, written off-main. Only disk write in M1; deleted with the spike (it is a scan of a real place).
- Return: load off-main, `initialWorldMap = map`, run with [.resetTracking, .removeExistingAnchors], time until trackingState == .normal after .limited(.relocalizing); restored anchors via `session(_:didAdd:)`.
- Record: map size (KB), relocalisation time, success within 15 s, panel within about 1 m (user judgement), 5 attempts same spot same time, 5 at another time of day, and whether compass panels jump when relocalisation lands.
- Limits: must stand within a few metres facing the same way; lighting and scene changes break it; storage and sync cost per place.

## Hybrid if B works
GPS radius (150 m) selects nearby memories; compass-placed panels appear immediately; if the nearest place has a map and the user is within about 15 m of its planting point, attempt relocalisation with a 10 s timeout; on success swap that place's panels to the map anchor. One `initialWorldMap` per session, so maps are per place cluster.

Room to leave in Capture (M2) if B wins: an optional "scan this spot" step at planting time (gated on worldMappingStatus) and an optional per-memory or per-place `worldMapFileName: String?`. Nothing else.

## Permissions and privacy
`INFOPLIST_KEY_NSCameraUsageDescription` ("to show your memories in the camera view") and `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` ("to place memories at the spot you saved them"). Request both on tap of Start AR; call `requestWhenInUseAuthorization()` before `CLLocationUpdate.liveUpdates()` and before `session.run`. Denied: plain screen with Open Settings. HUD and CSV carry accuracy, offsets and timings, never lat/lng. `session(_:didFailWithError:)` shown on the HUD. Delete all spike logging and the map file after M1.

## Smooth UX
Session and location start in parallel on appear after permission; pause on background and disappear; panels as soon as the first fix; archive, unarchive and text meshes off-main; default renderOptions first.

## Measurement protocol (outdoors, unplugged)
Permissions granted before timing; the tap is t0. 20 warm runs, 5 cold runs (app killed), 3 Airplane-mode runs, recorded separately. p90 = nearest rank (18th of 20), same function in HUD and CSV, unit tested. HUD shows last run and running median/p90; `ShareLink` exports spike-runs.csv (run, mode, cold, timestamp, t_first_frame_ms, t_fix_ms, t_first_panel_ms, fix_accuracy_m, fps_avg, fps_p95, thermal_start, thermal_end, relocalised, reloc_ms, map_kb, note).

## Files
Under source/Features/AR/Spike/: ARSpikeHome.swift, ARSpikeView.swift (UIViewRepresentable + ARSessionDelegate coordinator), SpikeSession.swift (@Observable state machine: idle, requestingPermission, denied, starting, locating, placed, relocalizing, failed), SpikeMetrics.swift, GeoOffset.swift, SpikeFixtures.swift, WorldMapStore.swift. Entry via a debug switcher in MorrowApp. Tests: GeoOffsetTests (0.0001 deg lat about 11.1 m N; at lat 16 deg 0.0001 deg lon about 10.7 m E; sign cases), SpikeMetricsTests (CSV, p90). Keep GeoOffset after M1; the rest is throwaway, deleted in M4.

Not built: UI polish, persistence, backend, Map, Capture, photos, manual nudge, clustering, ARGeoTracking.

## Definition of Done
Compiles on the Mac and runs on the 11 Pro; CSV with 20 warm + 5 cold + 3 airplane runs attached here (B: 10 attempts); measured numbers replace the proposals in ar-performance-budget.md; ADR 0007 "AR positioning approach" with outcome A, hybrid, or fail; honest-answer paragraph for the user; spike logging and map file removed or ticketed.
