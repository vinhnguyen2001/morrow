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
- **Store move order (T-004 step 0).** Moving `default.store` from Application Support to `Application Support/Store/`: move `-wal` and `-shm` first, main file last, so an interrupted move is retried (target main missing, legacy main present). Never copy a live SQLite file. If a step throws, roll back the moved files in reverse order; open the legacy location only after a successful rollback (`StoreLocation.MoveError.rolledBack`), otherwise fail loudly.
- **Do not reinstall the old build (4cde0ca) on a device with data** after the store has moved to `Application Support/Store/`: the old build would open a new empty store at the old path.
- `completeUnlessOpen` protects only while the device is locked and the file is not open. Opening the store from a background launch while locked may fail. Relevant to Step 2 (location) and M5 (sync). A DEBUG log prints the protection class at launch to check on a device.
- `Task.detached` does not inherit cancellation. After `await Task.detached {...}.value`, check `Task.isCancelled` before assigning state (done in `CaptureViewModel.setPhoto`).
- `Coordinate` redaction does not cover `dump()`, `Mirror` or printing a `MemoryRecord` (raw lat/lon columns). Never dump or log `Memory` or `MemoryRecord`.
- **Multi-file store move: wal/shm travel with main (T-004 round 2).** Never keep a wal/shm of unknown origin. While main is still in legacy, legacy is the source of truth: a wal/shm only in the target is a leftover of an interrupted run and is moved back to legacy before the move; one in both places is abnormal and stops with `rollbackFailed` (nothing merged, deleted or overwritten). Every step goes into the rollback list so rollback is all-or-nothing, including files from a previous run.
