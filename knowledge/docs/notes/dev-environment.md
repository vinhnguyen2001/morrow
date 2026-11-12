# Development environment and workflow

- Date: 2026-11-12
- Topic: convention

## Machines
- The user works on more than one machine. This folder (knowledge/docs) is the shared context; update it after every decision or completed ticket.
- One machine is Windows with no Xcode or Swift. Code written there is NOT compiled. Every ticket written on Windows must say so, and the first Mac build is expected to need small fixes.
- Building, previews, tests, and the AR spike require a Mac with Xcode 15+ and a physical iPhone.

## Project layout
- `source/` holds all app code and `project.yml` (XcodeGen spec). Generate the project on a Mac with `cd source && xcodegen generate`. XcodeGen is a dev-only tool, not an app dependency. The generated `.xcodeproj` is git-ignored.
- `.claude/agents/danny.md` (Principal Engineer, read-only reviewer) and `.claude/agents/mark.md` (Senior Engineer, implements). `/review-loop` runs Danny review, Mark fix, Danny re-review, max 3 rounds.
- `knowledge/docs/` decisions (ADRs), tickets, notes.

## Working rules (from the user)
- Ship fast and cheap. AR must feel fast.
- Avoid duplicate code, follow SOLID, use design patterns where they solve a real problem (Strategy for backend, Repository, Adapter, Factory at the composition root). No over-engineering.
- Backend must be swappable (ADR 0001); it is not chosen yet (ADR 0005).
- Security is a priority: see notes/security-checklist.md (no secrets in repo, Keychain, file protection, EXIF stripping, RLS, cross-account test).
- The app must feel smooth with no lag: see notes/smooth-ux-rules.md (off-main work, lazy lists, thumbnails, optimistic UI, measure before optimising).
- Record every decision here so other machines and sessions do not re-derive it.
