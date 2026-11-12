# Sample data conventions

- Date: 2026-11-12
- Topic: convention

## Content
- Fixture IDs are fixed UUID literals written as `UUID(uuidString: "...")!`. The force unwrap is intended for compile-time constants; do not add `?? UUID()` fallbacks (they hide typos and break determinism).
- Nothing that the app target uses may sit under `#if DEBUG` until a real composition root exists, otherwise Release/Archive fails to compile.
- Tests use fixed IDs too, never `UUID()`, so hash-based tests (tilt) stay deterministic.
- Fixture dates are fixed `Date(timeIntervalSince1970:)` literals with distinct offsets per sample, never `Date()`, so previews and tests render the same time every run.
