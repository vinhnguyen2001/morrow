# ADR 0009: Navigation and Map

- Status: Accepted
- Date: 2026-11-12
- Deciders: Danny

## Decision
- One `NavigationStack` with `enum Route: Hashable { case memory(UUID), map }`. Detail receives an id and looks the memory up in the shared `HomeViewModel.memories`, so it is never stale and pops if the memory is gone.
- Map uses SwiftUI `Map` with `Marker`, no clustering until measured with ~200 pins (smooth-ux rule 10). Clustering later means `MKMapView` in a `UIViewRepresentable`.
- Peek is a native `.sheet` with detents (`.height(168)`, `.large`); the large detent shows the same `MemoryDetailView` as Home.
- Map does not request location permission. No embedded mini-map in Detail (a live Map view inside a scroll view hitches and fights gestures; use `MKMapSnapshotter` off-main if ever needed).
- "View in AR" is hidden, not disabled, until T-002.

Update (T-004 step 3 review round 1): `HomeView`, which owns the path, trims it with `.onChange(of: model.memories)` and drops `.memory(id)` routes whose memory is gone; Detail also keeps its last shown memory while popping. Pushes from a card are de-duplicated (`path.last != .memory(id)`).

Update (T-004 step 4): `Route.map` pushed from the white Map button on Home. `MapView` takes the `HomeViewModel` (needs it for Detail), one `.sheet(isPresented:)` driven by the selection, detent state, Detail built only at `.large`, no Back button inside the sheet. Pure `MapPins`, `MapFraming` (default region, minimum span about 2 km, padding 1.6, clamps) and `Route.trimmed`. Camera span is read with `onMapCameraChange(.onEnd)`. The "N nearby" badge on the Home Map button is placeholder chrome (ADR 0010).
