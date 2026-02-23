# ADR-0032: Habits Atomic System, Weekly Review, and Bidirectional Calendar Sync

**Status:** ACCEPTED  
**Date:** 2026-02-23  
**Deciders:** Architecture review  
**FR:** FR-011, FR-015, FR-026  
**Related:** ADR-0007 (Schedule -> Calendar convergence), ADR-0012 (TDD-first), ADR-0017 (frontend hooks layer), ADR-0018 (calendar workspace / DayFlow), [`ADR-0032 implementation plan`](../implementation/ADR-0032-atomic-habits-implementation-plan.md)

---

## Context

The current Habits module implements a baseline tracker:

- habits can be created with frequency
- completion is toggled by date using a single `completed_dates` history
- streak and summary analytics exist

This is insufficient for the desired system-based workflow for consistency building.

Product direction is to upgrade Habits to an Atomic Habits-inspired system centered on:

- identity-based behavior tracking
- cue -> action -> reward design
- Minimum Viable Habit (MVH / 2-minute rule)
- consistency-first tracking (showing up counts)
- weekly review and look-forward planning

The requested v1 scope also requires habit planning to integrate with the existing Calendar workspace and support bidirectional edits:

- Weekly Review look-forward plans can be synced into calendar blocks
- calendar move/resize/delete on habit-generated blocks updates the linked habit weekly plan

This crosses module boundaries (`Habits`, `Calendar`, `Schedule`) and therefore requires an explicit ADR rather than ad hoc feature notes.

---

## Decision

The Habits module is expanded to a system-oriented Atomic Habits model with structured Weekly Review and bidirectional Calendar sync for planned habit blocks.

### 1) Habit completion supports two mutually exclusive daily states

Each habit day can be in one of:

- `STANDARD`
- `MVH`
- no completion

`STANDARD` and `MVH` are mutually exclusive for the same date.

### 2) Streak semantics are consistency-based

Visible streaks count a day as successful if either `STANDARD` or `MVH` completion exists.

This preserves the "show up first" product principle and avoids penalizing MVH days.

### 3) Existing completion history remains valid and maps to `STANDARD`

Backward compatibility defaults:

- existing `completed_dates` remain supported
- existing `completed_dates` are interpreted as `STANDARD` completions
- new `mvh_dates` defaults to empty when absent

### 4) Weekly Review is a first-class persisted habit workflow

Habits includes structured Weekly Review records that persist:

- Done
- Slipped
- Adjustment (one change)
- Anchors / look-forward plan items

Weekly Review is not limited to a markdown template in v1; it is modeled and persisted for future analytics and synchronization.

Weekly Review and Weekly Prep are separated in the UI/interaction model:

- `Weekly Review` is reflection-only (`Done`, `Slipped`, `Adjustment`) with historical review browsing
- `Weekly Prep` is planning-oriented and supports per-habit preparation data for the current review week

Global environment checklist text remains supported only as a legacy compatibility field during the transition to per-habit prep snapshots.

### 5) Weekly Review look-forward plans sync to Calendar as linked projections

Habit look-forward plan items generate local `calendar_event` blocks with explicit linkage metadata:

- `habit_generated`
- `habit_id`
- `habit_review_id`
- `habit_plan_instance_id`

The linkage enables deterministic sync, re-sync, and reverse lookup.

Habit-generated calendar blocks also carry a synced snapshot of per-habit Weekly Prep data (environment checklist + prep notes) so prep context is visible inside Calendar event details without requiring a live join back to the Habits UI.

### 6) Calendar edits on habit-generated blocks write back to the linked plan

Existing calendar mutation semantics are extended for habit-generated events:

- move/resize (`calendar.rescheduleEvent`) updates the linked planned habit instance
- delete (`calendar.deleteEvent`) removes/marks removed the linked planned habit instance

This delivers bidirectional editing while preserving a single logical schedule state.

On re-sync (`habits.syncWeekPlan`), backend sync preserves user-owned event note fields (notably `description`, plus non-managed props such as `location`/`linked_note_id`) while updating managed habit schedule/linkage/prep projection fields.

### 7) Contracts and implementation sequencing follow paired PR governance

Because this work changes backend command behavior and adds new habit IPC, implementation must use paired PRs:

- `cortex-os-contracts` (IPC wiring matrix/changelog)
- `cortex-os-backend` (commands/storage logic)
- `cortex-os-frontend` (types/services/hooks/views/tests)
- `cortex-os` integration pin/doc sync follow-up after component merges

---

## Public Interface Direction (Locked for Follow-on Contracts PR)

### Habits IPC

- Upgrade `habits.toggle` / `habits_toggle` request payload to accept optional `completionType` (`standard|mvh`; default `standard`)
- Preserve command name for compatibility
- Enforce same-day mutual exclusivity between `completed_dates` and `mvh_dates`

### Habits Summary

- Extend `habits.getSummary` response with split `STANDARD` / `MVH` metrics
- Preserve existing combined totals (`completions`, `windowCompletions`) for compatibility

### New Habits Week Sync Command

- Add `habits.syncWeekPlan` (final command name to be locked in contracts PR)
- Command performs idempotent sync of Weekly Review plan items into local `calendar_event` pages and returns create/update/delete/skip counts

### Calendar Linked Behavior

- No new calendar command names are required in v1
- Existing calendar reschedule/delete commands gain linked-habit update semantics when `habit_generated=true`

---

## Consequences

### Positive

- Aligns Habits UX with system/identity-based behavior design
- Makes MVH a first-class concept without losing current history
- Enables practical planning continuity by connecting Habits Weekly Review to Calendar
- Preserves compatibility by evolving existing command names and response fields

### Tradeoffs

- Bidirectional sync increases complexity and test surface area
- Calendar and Habits now share linked behaviors that require stronger contract discipline
- Weekly Review persistence introduces new collection/entity shapes beyond current habits baseline

---

## Implementation Plan Reference

Implementation details, sequencing, TDD matrix, risks, and acceptance criteria are defined in:

- [`docs/implementation/ADR-0032-atomic-habits-implementation-plan.md`](../implementation/ADR-0032-atomic-habits-implementation-plan.md)

This ADR is `ACCEPTED` based on that plan; code implementation remains pending paired PRs across contracts/backend/frontend.
