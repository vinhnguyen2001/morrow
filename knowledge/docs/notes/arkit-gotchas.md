# ARKit gotchas

- Date: 2026-11-12
- Topic: gotcha
- Source: Danny (T-002 spec). Verify on device.

## Content
- SwiftUI `RealityView` is iOS 18+ on iPhone. On iOS 17 use RealityKit `ARView` inside a `UIViewRepresentable`; this also gives direct `ARSession` access needed for world maps.
- `worldAlignment = .gravityAndHeading`: +x east, -z north, origin at session start. Heading is sampled at session start, so compass drift accumulates over a session. A flipped sign mirrors every panel: check against the Compass app on the first run.
- Flat-earth offsets are fine at memory scale: dN = dLat * 111_320 m; dE = dLon * 111_320 * cos(lat) m.
- `ARWorldMap` has no official size limit or relocalisation time. Forum reports mention 20 MB+ maps lagging or crashing on load: measure size and load time, keep maps per place, not per memory. Relocalisation needs the user near the planting spot, facing the same way, in similar lighting.
- On iOS 17 call `requestWhenInUseAuthorization()` explicitly before iterating `CLLocationUpdate.liveUpdates()`.
- ARGeoTracking (`ARGeoAnchor`) is unavailable in Vietnam; do not plan on it.
- Pause the session on background and on disappear; camera + ARKit + GPS is the most expensive thing the app does.
