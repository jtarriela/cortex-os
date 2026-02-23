# ADR-0032 Implementation Audit (Local Workspace)

**ADR:** [`ADR-0032`](../adrs/ADR-0032-habits-atomic-system-weekly-review-calendar-sync.md)  
**Plan:** [`docs/implementation/ADR-0032-atomic-habits-implementation-plan.md`](../implementation/ADR-0032-atomic-habits-implementation-plan.md)  
**Status:** Implemented in local workspace (pre-merge / pre-pin)  
**Date:** 2026-02-23

---

## Purpose

This file exists in `docs/implmentation/` (intentional path per audit request) as a durable audit artifact for the local ADR-0032 implementation pass.

It records what was implemented, where it was implemented, and what was validated before opening paired PRs.

---

## Implemented Scope (ADR-0032)

- Atomic Habits data model expansion on `habit` pages (identity/cue/action/MVH/reward/temptation bundle fields)
- Dual daily completion states: `STANDARD` and `MVH` with same-day mutual exclusivity
- Consistency streak semantics that count either `STANDARD` or `MVH`
- Split habit analytics metrics (`standard` vs `mvh`) while preserving legacy combined totals
- Weekly Review persisted workflow (`Done`, `Slipped`, `Adjustment`, `Anchors`)
- Weekly Review look-forward plan item persistence and sync metadata
- Idempotent Weekly Review → Calendar sync (`habits_sync_week_plan`)
- Bidirectional linked behavior for habit-generated calendar blocks:
  - calendar move/resize writes back to linked habit plan item
  - calendar delete marks/removes linked habit plan item
- Habits UI redesign for Atomic Habits workflow (ATOMS header/cards, dual actions, heatmaps, weekly review + planning UI)
- Contracts documentation updates for new/changed IPC semantics

---

## File-Level Implementation Summary

### Integration repo (`cortex-os`)

- `docs/adrs/ADR-0032-habits-atomic-system-weekly-review-calendar-sync.md` (ACCEPTED)
- `docs/implementation/ADR-0032-atomic-habits-implementation-plan.md` (planning source)
- `docs/functional_requirements.md` (`FR-011`, `FR-015`, `FR-026` expanded for ADR-0032)
- `docs/traceability.md` (implementation mapping updated for local workspace delivery)
- `.system/MEMORY.md` (current focus + append-only progress entries)
- `docs/implmentation/ADR-0032-implementation-audit.md` (this audit artifact)

### Backend repo (`backend/`)

- `backend/crates/storage/src/repo.rs`
  - mode-aware habit toggle (`standard` / `mvh`)
  - same-day mutual exclusivity across `completed_dates` and `mvh_dates`
  - streak recompute from union of completion sets
- `backend/crates/storage/tests/repo_integration.rs`
  - MVH mutual exclusivity test
  - consistency streak union test
- `backend/crates/app/src/lib.rs`
  - `habits_toggle` accepts `completion_type`
  - `habits_get_summary` split metrics + compatibility totals
  - `habits_sync_week_plan`
  - linked habit-plan write-back on `calendar_reschedule_event` / `calendar_delete_event`

### Frontend repo (`frontend/`)

- `frontend/types.ts`
  - Atomic Habits types + Weekly Review + habit-generated calendar metadata
- `frontend/services/normalization.ts`
  - Atomic habit fields, `mvh_dates`, weekly review normalization, calendar linkage metadata
- `frontend/services/backend.ts`
  - `toggleHabit(..., completionType)`
  - `updateHabit`, weekly review CRUD helpers, `syncHabitWeekPlan`
- `frontend/services/backend.extensions.ts`
  - calendar linkage metadata hydrate/dehydrate support
- `frontend/hooks/useHabitsView.ts`
  - Atomic Habits controller (dual-state tracking, weekly review, planning, sync)
- `frontend/views/Habits.tsx`
  - ATOMS UI, design modal, dual actions, analytics heatmap, weekly review/planner
- `frontend/tests/backend.smoke.test.ts`
- `frontend/tests/hooks/useHabitsView.test.ts`

### Contracts repo (`contracts/`)

- `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md`
  - `habits.toggle` `completionType?`
  - `habits.getSummary` split metrics note
  - `habits.syncWeekPlan` command row
  - calendar reschedule/delete linked-habit semantics
- `contracts/CHANGELOG.md`
  - ADR-0032 contract additions/changes documented (unreleased section)

---

## Validation (Local Workspace)

The following validation commands were run during the local ADR-0032 implementation pass:

- `cd /Users/jdtarriela/.codex/worktrees/df8f/cortex-os/backend && cargo check -p cortex-app`
- `cd /Users/jdtarriela/.codex/worktrees/df8f/cortex-os/backend && cargo test -p cortex-storage --test repo_integration habit_toggle_`
- `cd /Users/jdtarriela/.codex/worktrees/df8f/cortex-os/frontend && npm test -- tests/backend.smoke.test.ts tests/hooks/useHabitsView.test.ts`
- `cd /Users/jdtarriela/.codex/worktrees/df8f/cortex-os/frontend && npm run build`

If additional contract/backend/frontend regressions are found during PR review, this audit file should be updated with follow-up fixes and re-validation commands.

---

## Follow-On (Not part of this local audit completion)

- Open paired PRs in:
  - `cortex-os-contracts`
  - `cortex-os-backend`
  - `cortex-os-frontend`
- Merge component PRs and then update integration submodule pins
- Final integration doc sync pass (`traceability`, release log, MEMORY) with merged PR links and pinned SHAs
