# Tilt (deterministic card rotation)

- Date: 2026-11-12
- Topic: convention

## Content
- `Tilt.degrees(for:maxDegrees:)` hashes the UUID bytes with FNV-1a 64 and maps the result to -maxDegrees...maxDegrees. `hashValue` is not used because it is randomised per process.
- `Tilt.fnv1a` is pinned in TiltTests to the published vectors: empty input = `cbf29ce484222325`, "a" (byte 0x61) = `af63dc4c8601ec8c`. Do not change the constants without updating the test.
- `TiltModifier` reads `accessibilityReduceMotion` and renders 0 degrees when it is on. This is a product choice (Danny, T-001 round 1), not a technical limitation.
