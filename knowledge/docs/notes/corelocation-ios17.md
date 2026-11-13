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
- Implemented in `Platform/SystemLocationProvider.swift`: authorization is read from `manager.authorizationStatus` (Location Services off reports denied, so no `locationServicesEnabled()` call). A cancellation handler can run before the body: check `Task.isCancelled` first, or the continuation is never resumed. The stream is ended by leaving the loop or cancelling the task; the cancel path is unverified on a device.
- `CLGeocoder` has an async `reverseGeocodeLocation`; `cancelGeocode()` from `onCancel`. A new geocoder per call avoids sharing a non-Sendable object.
- Swift 5.9: a `@MainActor` class used as a default argument needs a `nonisolated init` (default arguments are evaluated outside the actor).

Learnings from T-004 step 2 review round 1 (2026-11-13):
- Set `.locating` synchronously in `startLocating()` before creating the Task; set inside the Task it lets two quick calls start two lookups.
- `stopLocating()` returns the state to `.idle` when it was `.locating`, so a failed Save (or a dismissed sheet) never leaves a dead "locating". A failed Save reopens the search it cut short.
- A failed Save must restore `locationClosed` to its value BEFORE Save, never hard-set false (a removed location must stay removed). Reopen the search only when Save cut it short at `.locating`.
