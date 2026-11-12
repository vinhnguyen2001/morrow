# ADR 0004: Platform baseline, typography, appearance

- Status: Accepted (Danny's recommendation, applied in M0; user has not objected)
- Date: 2026-11-12
- Deciders: Danny, user

## Decision
- iPhone only, portrait only, iOS 17+ (SwiftData and @Observable). Minimum tested device target: iPhone 12 class (to confirm).
- SwiftUI, @Observable MVVM-lite, no third-party dependencies, no DI container, no generic Repository<T>.
- Font: system SF Pro via a token layer (`MorrowFont`). Inter is not bundled. If brand fidelity is required later, Inter becomes a one-file swap in the token layer.
- Light mode only for v1. All colours go through tokens so dark mode can be added without touching views.
- Secondary text is darkened to at least 4.5:1 contrast.
- Native first: `.sheet` with detents instead of hand-rolled sheets, native `Toggle`, MapKit `Map`, SF Symbols.

## Trade-offs
- Bundling Inter costs about 1 MB, licence file, manual Dynamic Type handling. SF Pro is free and scales natively.
- Light-only is simplest and honest; the design has no dark palette.

## Open
- User to confirm font and light-only (recommended), and the minimum device.
