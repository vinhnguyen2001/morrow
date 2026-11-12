# SwiftData gotchas

- Date: 2026-11-12
- Topic: gotcha
- Source: found while building T-003 on the Mac (Xcode 26, simulator iOS 26, device iOS 17.4.1).

## Content
- **Keep the `ModelContainer` alive.** A `ModelContext` (including `container.mainContext`) traps inside SwiftData on its first operation if the container was released. A repository that stores only the context, built from a local `let container`, crashes at the first `fetch` with `EXC_BREAKPOINT` and no message. Store the container in the repository (done in `SwiftDataMemoryRepository`). Tests must do the same, which the repository now guarantees.
- **Do not name a `@Model` property `isDeleted`.** `PersistentModel` already has one. Soft delete uses `isSoftDeleted`.
- A fresh install has no `Library/Application Support`. Create it before opening a store, or CoreData logs "Failed to stat path default.store".
- Predicates use `$0.isSoftDeleted == false` rather than `!$0.isSoftDeleted` (harmless, kept for safety; the crash was not caused by it).
- When the app is the test host, a crash at launch shows only "test runner crashed before establishing connection". Read `~/Library/Logs/DiagnosticReports/Morrow-*.ips` for the stack. `log show` needs the PID of the new process, not the test host's.
- Soft delete must scrub content (title, body, place, photo name, coordinates) and keep only a tombstone (id, updatedAt, isSoftDeleted); otherwise "Delete" leaves personal data in the store.
- Adding optional columns migrates automatically, but always verify by installing over an old build on a device with data (ADR 0008).
