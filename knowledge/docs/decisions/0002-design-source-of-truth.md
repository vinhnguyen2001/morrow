# ADR 0002: Design source of truth is the "Chronicle" v2 look

- Status: Accepted
- Date: 2026-11-12
- Deciders: user, Danny

## Problem
The design canvas (https://claude.ai/code/artifact/8b1554ad-364f-4904-86e8-1d41fa384ba9) contains two looks. `DesignSystem.dc.html` shows an old look (Nunito + Caveat fonts, Forest #425B32, paper #FAF7F2, bottom tab bar). `Main.dc.html` and `MemoryCard.dc.html` show the newer "Chronicle" v2 look.

## Decision
- Chronicle v2 is canonical: Inter-style type, ground #F4F4F1 with dotted grid, white cards, action colour #1E3B2F, round Add button and round white Map button, no tab bar, Settings via gear.
- `DesignSystem.dc.html` and canvas note s3 ("Bottom nav is Home · + · Settings") are stale and ignored.
- Tokens: ink #121212, body #2B2B2B, secondary text #5C5C5C (darkened from the design's #7C7C7C to reach 4.5:1 contrast), card radius 26, image radius 20, sheet radius 34, chips 999. Type tints: note #F0ECFF/#5B3FB8, list #E8F7EC/#2E6B4A, checkin #FFF1E6/#B4541E, discovery #E4F1FB/#1F6FA8.
- Icons: SF Symbols, not the prototype's SVG paths. Only the logo needs a custom asset.

## Open
- Add button: code says #1E3B2F, canvas note says black. Using #1E3B2F until the user confirms.

## Consequences
- The prototype is a web mock: map, AR, photos and all data are simulated. Everything real is new iOS work.
