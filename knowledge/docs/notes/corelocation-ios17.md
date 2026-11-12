# CoreLocation on iOS 17

- Date: 2026-11-12
- Topic: gotcha
- Source: Danny (T-004 spec). Verify on device (iOS 17.4.1).

## Content
- Call `requestWhenInUseAuthorization()` and wait for `locationManagerDidChangeAuthorization` before iterating `CLLocationUpdate.liveUpdates()`; without authorization the stream yields nothing.
- Wrap the authorization continuation so it resumes exactly once, including on task cancellation (user dismisses the sheet while the prompt is up).
- Reduced accuracy ("approximate") makes `horizontalAccuracy` large forever: always keep a "best fix when the timeout hits" branch.
- `CLServiceSession` and `authorizationDenied` are iOS 18+. Do not call `locationServicesEnabled()` on the main thread.
- Never log coordinates. `Coordinate.description` is redacted on purpose.
- The Simulator only fakes location via Features > Location.
