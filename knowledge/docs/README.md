# Morrow Knowledge Base

Persistent project context so no one has to re-read old conversations. Read this index first, then only the files you need.

## Structure

- `decisions/` Architecture and technical decisions (ADRs). One file per decision, named `NNNN-short-title.md`.
- `tickets/` Work items and their outcome. One file per ticket, named `T-NNN-short-title.md`.
- `notes/` Domain knowledge, conventions, gotchas, API findings, anything reusable.

## Rules

- One topic per file. Keep it short and factual.
- Update the index below whenever you add a file.
- Do not duplicate what the code or git history already shows. Record the why, not the what.
- Never record secrets, keys, or personal data.
- Danny (read-only) suggests entries. Mark or the main session saves them.

## Index

### Decisions
- [0001 Backend-agnostic persistence](decisions/0001-backend-agnostic-persistence.md): SwiftData is local truth, backend sits behind a Strategy, backend not chosen yet
- [0002 Design source of truth](decisions/0002-design-source-of-truth.md): Chronicle v2 look is canonical, tokens listed, old DesignSystem sheet ignored
- [0003 MVP scope, AR first](decisions/0003-mvp-scope-and-ar-first.md): 4 screens + capture sheet, social and journeys deferred, milestones M0 to M6, M1 AR spike is the gate
- [0004 Platform and typography](decisions/0004-platform-and-typography.md): iOS 17+, iPhone, SF Pro via tokens, light only, no third-party deps
- [0005 Backend candidates](decisions/0005-backend-candidates.md): NOT decided; local-only first, CloudKit vs Supabase compared, Supabase free-tier rules
- [0006 No Rust](decisions/0006-no-rust.md): Swift only; AR bottlenecks are Apple frameworks

### Tickets
- [T-001 Skeleton, tokens, MemoryCard (M0)](tickets/T-001-skeleton-tokens-memorycard.md): Done, approved round 2, not compiled; Mac checklist open

- [T-005 Home per design](tickets/T-005-home-per-design.md): steps 1-5 done, review round 1 fixed (header, timeline, Notes, Places, Search); step 6 dropped; 7-8 pending

### Notes
- [AR performance budget](notes/ar-performance-budget.md): thresholds, how to measure, how to keep AR fast, positioning fallbacks
- [Dev environment and workflow](notes/dev-environment.md): Windows has no Xcode, source/ layout, XcodeGen, agents and review loop, user's working rules
- [Privacy and accessibility checklist](notes/privacy-accessibility-checklist.md): plist keys, EXIF, labels, 44pt, contrast, Reduce Motion
- [Security checklist](notes/security-checklist.md): user requirement; secrets via xcconfig, Keychain, file protection, EXIF, HTTPS, RLS, cross-account test, per milestone
- [Smooth UX rules](notes/smooth-ux-rules.md): user requirement; frame and latency targets, off-main work, lazy lists, thumbnails, optimistic UI, measure before optimising
- [SwiftUI accessibility on Button](notes/swiftui-accessibility-button.md): do not stack accessibilityElement(.ignore)/addTraits(.isButton) on a Button
- [Sample data conventions](notes/sample-data.md): fixture IDs are UUID literals with `!`, fixed dates, nothing the app uses under #if DEBUG
- [SwiftUI compile notes](notes/swiftui-compile-notes.md): API patterns verified safe for iOS 17 when reviewing without a compiler
- [Tilt](notes/tilt.md): FNV-1a 64 pinned to published vectors, Reduce Motion zeroes the tilt by product choice
