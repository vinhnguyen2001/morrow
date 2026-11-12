# ADR 0007: Location at capture, coordinate storage

- Status: Accepted (Danny proposal 2026-11-12; file protection point decided by orchestrator, see Open)
- Date: 2026-11-12
- Deciders: Danny, user

## Problem
Map pins and an auto-filled place name need coordinates, without tying the app to one SDK or leaking location.

## Decision
- Domain has `Coordinate` (validated, no CoreLocation import, `description` is redacted so accidental logging leaks nothing).
- CoreLocation and CLGeocoder sit behind two small protocols, `LocationProviding` and `PlaceNaming`, one adapter each. Those adapters are the only files importing CoreLocation.
- Full-precision coordinates stay in the local store. If shared content ever exists, fuzz server-side (security-checklist).
- When-In-Use only, requested once when Capture first opens. Denied or unavailable location never blocks saving.
- `CLLocationUpdate.liveUpdates()` (iOS 17) after an explicit `requestWhenInUseAuthorization()`; wait up to 5 s for accuracy <= 100 m, then use the best fix seen (reduced accuracy never reaches 100 m).
- Do not use `CLServiceSession` or `authorizationDenied` (iOS 18).

## Trade-offs
- `CLGeocoder` is deprecated on iOS 26 but the target is iOS 17. Behind `PlaceNaming`, switching to `MKReverseGeocodingRequest` later is a one-file change.
- Geocoding sends the coordinate to Apple: list it in the privacy nutrition label (M6).
- The pin is the user's position at capture time, not where a library photo was taken (EXIF is stripped). The user can edit or remove the location.

## Open
- Store file protection: see T-004 step 0 item 8.
