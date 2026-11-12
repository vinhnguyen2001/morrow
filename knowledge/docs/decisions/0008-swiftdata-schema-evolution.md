# ADR 0008: SwiftData schema evolution

- Status: Accepted
- Date: 2026-11-12
- Deciders: Danny

## Decision
- Additive optional properties use automatic lightweight migration; no `VersionedSchema` yet.
- Every such change must be verified by installing the new build over an old one on a device with data (unit tests cannot cover it reliably).
- Move to `VersionedSchema` + `SchemaMigrationPlan` before any rename or type change, or before M5 sync, whichever comes first. Watch the unique constraint on `id` when doing so.

## Why
Freezing V1 needs an exact copy of the shipped schema and carries iOS 17 bug risk; not worth it for optional columns.
