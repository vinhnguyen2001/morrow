# Security checklist

- Date: 2026-11-12
- Topic: convention
- Source: user requirement ("security must be a priority"). Danny reviews against it; Mark implements it. Items marked M-n apply from that milestone.

## Secrets and configuration (M0+)
- No API keys, tokens, or service-role keys in source, project.yml, Info.plist, or git history.
- Backend keys live in a gitignored `Config.xcconfig` (with a committed `Config.example.xcconfig`) and are read from the bundle at runtime. The app only ever holds a public/anon key.

## Local data (M2+)
- Auth tokens and sessions in Keychain, never UserDefaults.
- SwiftData store and photo cache protected with file protection (`.completeUnlessOpen` minimum).
- Coordinates are sensitive: never logged, never sent to analytics or crash reports. Use `os.Logger` with `privacy: .private`.

## Photos (M2+)
- Strip EXIF GPS and other metadata before upload or share (ImageIO).
- Compress on device; enforce a maximum image size.

## Network (M5+)
- HTTPS only; App Transport Security stays enabled; no custom TLS trust.
- Signed, short-lived URLs for private files.
- Decode server data with Codable into typed models; limit text lengths.

## Backend authorisation (M5+)
- Row Level Security (or equivalent) on every table and storage bucket before the first row is written.
- Owner-only access; server derives owner from the auth session, never from client input.
- A cross-account access test (two accounts, each must not read the other) is part of the definition of done.
- If "hide exact location" is offered for shared content, fuzz coordinates server-side.

## Permissions and privacy (M1+)
- Camera and location requested at point of use with honest usage strings; When-In-Use only; denied and restricted states handled.
- Privacy Manifest with required-reason APIs declared; privacy nutrition label accurate.
- No third-party SDK that collects data; no new dependencies without an ADR.

## Account (when accounts exist)
- Sign out and delete account (App Store requirement); deletion removes server rows and files.

## Status
- M0 has no network, persistence, or secrets, so nothing applies yet beyond "no secrets in repo". The xcconfig pattern starts at the first backend milestone.
- At the first backend milestone `.gitignore` gains `Config.xcconfig`, and a committed `Config.example.xcconfig` documents the keys.
