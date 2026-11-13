# Privacy and accessibility checklist

- Date: 2026-11-12
- Topic: convention
- Source: Danny's design review. Apply before TestFlight (M6).

## Privacy
- Info.plist: NSCameraUsageDescription, NSLocationWhenInUseUsageDescription (no Always). Microphone only if video is added.
- Strip EXIF GPS from uploaded photos; location lives in the database column, not in the file.
- Privacy manifest and App Store privacy nutrition label (location, photos, user content).
- Sign in with Apple is mandatory if any other social login is offered.
- If public content ever ships: report, block and content filtering are required by App Store guideline 1.2; "hide exact location" must be enforced server-side with fuzzed coordinates.
- Settings minimum when accounts exist: sign out, delete account.

## Accessibility
- Every icon button has an accessibilityLabel (CircleIconButton requires it).
- Cards are one combined element with a meaningful label (title, place, time).
- Tap targets at least 44 pt (design's 17 pt checkbox and 30 pt badge are too small).
- Contrast at least 4.5:1 for small text; secondary ink is #5C5C5C, not #7C7C7C or #9A9A9A.
- Reduce Motion: disable tilt, rotating Add button and scan sweep animations.
- Dynamic Type: fonts use text styles; two-column layouts collapse to one column at accessibility sizes.
- Native sheets for VoiceOver; the "tap handle to toggle" gesture needs an accessible action.

- Reverse geocoding sends the coordinate to Apple: declare it in the privacy nutrition label (M6). `Coordinate` redacts its value when printed.

## Location in Capture (T-004 step 2)
- Usage string is in project.yml. The user can remove the location and edit the place; the status line has text, not colour only; remove button is 44pt and labelled "Remove location". Not checked: VoiceOver reading order and accessibility Dynamic Type on a device.
- No privacy manifest entry needed for CoreLocation itself; geocoding goes to the nutrition label (M6).

## MapKit (T-004 step 4)
- The device loads map tiles from Apple, so Apple sees the area being viewed (approximate). Memory content and pins are drawn on the device and are not sent anywhere.
- The Map asks for no location permission and does not show the user's location. Offline, tiles do not load (empty background is normal).
- Declare this in the App Store privacy label (M6) together with reverse geocoding.
- Privacy Manifest: still no separate MapKit entry needed (re-check at M6).
- Pin VoiceOver: `Marker` has no accessibility modifiers on iOS 17, so the screen posts `AccessibilityNotification.Announcement` with kind, title and place on selection. Improvement, needs listening on a device.
