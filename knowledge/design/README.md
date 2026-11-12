# Design source (Claude Design canvas)

- Source: https://claude.ai/artifact/JB8MtWskk4vGUSVqVaF7PN (version 1794487399-933b, pulled 2026-11-12).
- `canvas/` is a snapshot of the canvas files. Do not edit here; edit on the canvas, then re-pull.
- Current look is "Look v2 - Chronicle" (graph-paper ground, white tilted cards, Inter, deep green #1E3B2F as action colour, round black Add button, round white Map button, no tab bar).
- ALL screens live in `canvas/Main.dc.html` as one prototype. The other artboards (HomeNotes, EmptyHome, ARLive, ...) are 1-line wrappers that import Main with props like `start-screen="home" start-tab="notes"`.
- `canvas/MemoryCard.dc.html` is current (Inter, v2).
- `canvas/DesignSystem.dc.html` is STALE (v1: Nunito + Caveat, Forest #425B32, Home/Map/+/Settings nav). Do not use it for tokens.
- Photos in the design are placeholders (`/_blob/...` URLs do not resolve locally).
