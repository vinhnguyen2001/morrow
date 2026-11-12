# ADR 0006: No Rust (or other non-Swift languages) for performance

- Status: Accepted
- Date: 2026-11-12
- Deciders: user asked, main session answered

## Problem
User asked whether Instagram uses Rust and whether Morrow should use Rust for performance.

## Decision
Do not add Rust. Reasons:
- Swift is already compiled and native; for the same algorithm it performs comparably to Rust.
- Morrow's AR bottlenecks are camera, ARKit, GPS, image decoding and GPU, all Apple frameworks that Rust cannot touch.
- Rust adds FFI bridging, a second toolchain, multi-architecture builds and harder debugging, which a solo developer cannot afford.
- Instagram's iOS app is Objective-C and Swift with some shared C++; its backend is Python optimised with Cython and C++. Meta uses Rust in infrastructure tooling, not in the Instagram app. (From memory, not an official statement.)

## Revisit only if
A measured CPU-bound hotspot exists in Swift and the same code must be shared with Android.

## Real performance plan
See notes/ar-performance-budget.md: local data, radius query, thumbnails, panel cap, measure with Instruments before optimising.
