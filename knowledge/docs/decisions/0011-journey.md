# ADR 0011: Journey

- Status: Proposed
- Date: 2026-11-12
- Deciders: Danny, user (Q3 pending)

## Problem
The design shows Journeys, but there is no backend, no friends and no collaboration.

## Decision
`Journey` is its own entity (UUID made by the app, title, destination?, startedAt, endedAt?, updatedAt, soft delete with scrub) in SwiftData. Membership is derived from the date range, with no journeyID column on Memory. At most one running journey, none overlapping. Own `JourneyRepository` (@MainActor) with a contract test suite; no generic `Repository<T>`. A future backend syncs Journey as its own entity; derived membership is the same on every device.

## Alternatives
`Memory.journeyID`: flexible (reassign later) but adds a column, a choice at Capture and more to sync. No Journey at all: the row stays empty and Home does not look like the design. Date range chosen: no change to MemoryRecord, least UI, no duplicated data.

## Limits
Memories cannot be moved into a journey after the fact; editing journey dates would shift membership (no editing yet); changing timezone shifts date labels; cover is a photo of a memory in range (no picker); no route map, members or collaboration.
