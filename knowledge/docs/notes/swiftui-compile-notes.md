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

Learnings from T-005 review round 2 (2026-11-12):
- `@Observable` on iOS 17 notifies observers on every assignment, even of an equal value. Guard assignments in `load()`-style methods (`if new != old { old = new }`); iOS 18 later added equality checks, do not rely on them.
- In `.task(id:)`, a cache hit must be assigned to `@State` straight away and then return. If the body reads the cache directly and NSCache evicts the entry, the view goes blank until the next task run.
- `AttributedString.accessibilitySpeechAnnouncementPriority` exists from iOS 17.0. Whether it really stops VoiceOver cutting an announcement short is NOT verified on a device.
- Long press "Delete" (context menu) lives on the card only, not on the side text or the whole row; the card is the single VoiceOver element of a row.
- `NSCache.countLimit` is not strict; tests may assert that some entries were evicted, never which ones.

Still verify on a Mac: nothing here replaces the first real build.

Learnings from T-004 step 3 review round 1 (2026-11-12):
- `Task.cancel()` in `onDisappear` skips any cleanup after a `guard !Task.isCancelled`, so set the default state (for example `toast = nil`) inside `onDisappear` itself.
- When Detail looks a memory up by id in a shared model, a delete makes it nil in the same render pass: keep a last-shown copy, or let the owner of the path trim it.
- A push from a `Button` needs a duplicate guard (`path.last != route`), or a fast double tap pushes twice.
- `NSCache.countLimit` is not a hard limit: do not unit test eviction.
- ImageIO does not enlarge a small image when `kCGImageSourceThumbnailMaxPixelSize` is larger than the source (tested with 300x200: full, thumb and display stay at 300 or less). Test images must be made with renderer scale 1, or pixels triple.

- A TextField placeholder is its accessibility label. If the placeholder changes with state (for example "Finding your place..."), add a fixed `.accessibilityLabel("Place")`. Announce state changes (located/unavailable) with `AccessibilityNotification.Announcement`.

Learnings from T-004 step 4 review round 2 (2026-11-13):
- Do not reset state that drives sheet content (e.g. the detent) when the selection becomes nil: the sheet is still sliding away and the content changes or disappears mid-motion. Use `.sheet(isPresented:onDismiss:)` so content stays until the sheet has closed. Device check: delete from Detail at .large and watch the slide down.

- `Đ`/`đ` (U+0110/U+0111) have no Unicode decomposition, so `.diacriticInsensitive` and `localizedStandardContains` do not fold them ("da nang" misses "Đà Nẵng"). Every accent-free comparison for Vietnamese goes through `TextMatching.key`. ơ/ư/ô/ê/â/ă fold correctly; NFD input gives the same key.
