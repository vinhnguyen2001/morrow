# ADR 0005: Backend candidates (not decided)

- Status: Proposed, awaiting user decision. See ADR 0001 for the swappable design.
- Date: 2026-11-12
- Deciders: user

## Problem
User wants the cheapest workable backend. Candidates compared (figures from memory, verify on official pricing pages before deciding):

| Option | Cost | Fit |
|---|---|---|
| Local only | 0 | Enough to validate AR (M1 to M4). |
| CloudKit | 0; private data counts against the user's own iCloud quota | Best for private-only memories. SwiftData syncs to CloudKit with little code; sign-in is the Apple ID. Apple-only; public content and nearby queries over public data are hard. SwiftData+CloudKit has constraints (attributes need defaults, no unique constraints). |
| Supabase Free | 0 in dev; Pro about 25 USD/month before public launch | Needed if public discovery, web or Android are planned. Free tier limits: about 500 MB DB, 1 GB storage, 5 GB egress/month, project pauses after about a week of inactivity, no automatic backups. |
| Firebase | Free tier limited; storage may require paid plan | Not recommended: extra SDK, NoSQL. |
| Cloudflare R2 for photos | about 10 GB free, no egress fees | Only as an add-on if photos outgrow the main backend. |
| Self-hosted PocketBase on VPS | about 5 USD/month | Cheap but user must operate a server. |

## Recommendation (Danny)
Run local-only first. Add CloudKit if sync between the user's devices is needed and content stays private. Choose Supabase only if public content, web or Android are planned.

## If Supabase is chosen
- Never store images in Postgres; compress on device (long edge about 1600 px, 200 to 400 KB), thumbnail 256 px, strip EXIF GPS.
- Enable Row Level Security on every table and bucket before the first row; private bucket; only the anon key in the app.
- Nearby queries: indexed bounding box; PostGIS only when public content exists.
- Upgrade to Pro before public launch; manual pg_dump while on Free.

## Decision needed from user
- Are web, Android, or public discovery of other people's memories planned?
- When to upgrade (recommended: before public launch), per-user photo cap in test (for example 200), accept manual backups on Free.
