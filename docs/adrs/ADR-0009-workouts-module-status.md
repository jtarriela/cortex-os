# ADR-0009: Workouts Module — Deferred to Phase 4

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Architecture review
**FR:** FR-019
**Supersedes:** N/A
**Related:** `001_architecture.md` Section 12 (Phase 4), `002_COLLECTIONS.md` (Workouts collection)

---

## Context

The Workouts module exists in a partial state:

- `frontend/views/Workouts.tsx` — exists on disk but is **not imported** in `App.tsx`
- `frontend/constants.ts` — contains `MOCK_WORKOUTS` seed data
- `frontend/services/dataService.ts` — exports `getWorkouts()` function
- `frontend/types.ts` — defines `Workout` interface
- `App.tsx` — the `NavSection.WORKOUTS` route renders an inline "Coming soon" placeholder, not the `Workouts.tsx` component
- Feature flags — `workouts` defaults to `false` (the only module defaulting to OFF)

No ADR previously documented this state.

## Decision

Workouts is **formally deferred to Phase 4** (Polish + Modules) per `001_architecture.md` Section 12. The existing view file and mock data are retained as design artifacts.

## Rationale

- Workouts was in the original architecture vision (unlike Goals, Meals, and Journal which were Phase 0 additions)
- The collection definition in `002_COLLECTIONS.md` is the implementation specification
- The Phase 0 frontend prioritized other modules that had more design clarity
- The feature flag mechanism already handles the deferral gracefully

## Consequences

- `Workouts.tsx` remains on disk but unimported — this is intentional, not a bug
- The "Coming soon" placeholder in `App.tsx` is the expected behavior when `features.workouts = true`
- When Phase 4 work begins, the existing `Workout` type, mock data, and `getWorkouts()` provide a starting point
- The contracts wiring matrix entries (`workouts.list`, `workouts.create`) are valid but low-priority
