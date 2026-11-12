# ADR 0001: Backend-agnostic persistence

- Status: Accepted
- Date: 2026-11-12
- Deciders: user, Danny

## Problem
The user has not chosen a backend yet. Candidates: local-only, CloudKit, Supabase (free tier). The product must ship fast and cheap, and AR speed is critical.

## Decision
- SwiftData is the local source of truth. UI and AR read only from it, never from the network.
- Backend sits behind a Strategy protocol (remote store for memories and photos). Implementations: no-op/local-only first, then CloudKit or Supabase when chosen.
- Repository protocol for the UI side. Adapters/mappers convert backend DTOs to domain types. One composition root (Factory) selects the implementation.
- App-generated UUIDs, `updated_at`, soft delete flag. Images compressed and thumbnailed on device.
- One shared contract test suite for all implementations.
- No generic `Repository<T>`, no DI container.

## Trade-offs
- Costs one protocol and one mapper per entity. Avoids rewriting UI and AR when the backend changes.
- Backend choice stays open: CloudKit is cheapest for private-only memories, Supabase fits public content or web/Android later.

## Consequences
- First MVP can run local-only to validate AR speed.
- Switching backend means writing a new implementation plus a one-time migration of users and data.
