# SwiftUI compile notes (reviewing without a compiler)

- Date: 2026-11-12
- Topic: api

## Content
Patterns Danny verified as safe for iOS 17 during the T-001 review, so later sessions on Windows do not re-check them:
- `Font.system(_:weight:)` with a text style: iOS 16+.
- `Text(_:format:)` with `Date.FormatStyle` (for example `.dateTime.hour().minute()`): iOS 15+.
- A `ViewModifier` struct can have a memberwise init alongside a `private @Environment` property (the environment property is excluded from the memberwise init).
- Non-inout `withUnsafeBytes(of:)` over a `uuid_t` tuple yields an `UnsafeRawBufferPointer`, which is a `Sequence` of `UInt8` and can feed a generic `Sequence<UInt8>` parameter.
- `Color` is `Equatable`, so `XCTAssertEqual` on two `Color` values compiles.

Still verify on a Mac: nothing here replaces the first real build.
