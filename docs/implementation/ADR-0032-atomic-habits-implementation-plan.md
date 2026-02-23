# Atomic Habits Habits-Module Upgrade — Implementation Plan (ADR-0032)

**Status:** Planned  
**Date:** 2026-02-23  
**Related ADR:** [`ADR-0032`](../adrs/ADR-0032-habits-atomic-system-weekly-review-calendar-sync.md)

---

## Summary

This document is the docs-first implementation plan for the Atomic Habits upgrade to the existing Habits module (`FR-011`).

The upgrade expands the current single-toggle habit tracker into a system-oriented workflow inspired by Atomic Habits:

- identity-based habit design
- cue -> action -> reward modeling
- Minimum Viable Habit (MVH / 2-minute rule)
- dual completion states (`STANDARD` and `MVH`)
- structured weekly review with look-forward planning
- bidirectional synchronization between Weekly Review planned habit blocks and Calendar events

This plan is intentionally decision-complete so implementation can proceed across `frontend`, `backend`, and `contracts` with paired PRs and minimal ambiguity.

---

## Scope

### In Scope (v1)

- Expand habit data model with Atomic Habits fields
- Dual-state completion tracking (`STANDARD`, `MVH`) with same-day mutual exclusivity
- Consistency streak semantics where either completion mode counts
- Multi-state habit analytics and heatmap semantics (`standard`, `mvh`, `none`)
- Habit system setup / design flow UI (identity/cue/action/MVH/reward/temptation bundle)
- Structured Weekly Review UI and persisted review records
- Look-forward anchor planning for next week
- User-triggered week-plan sync to Calendar
- Bidirectional update semantics for habit-generated calendar blocks (move/resize/delete writes back to linked review plan)
- Integration-repo docs sync for FR/traceability/MEMORY + ADR acceptance

### Out of Scope (v1)

- Direct Google Calendar event generation from Habits (sync targets local Cortex `calendar_event` pages only)
- Full habit-to-task auto-generation and task ownership semantics
- Continuous background auto-sync between Habits and Calendar without explicit user sync action
- Mobile-specific UX redesign beyond responsive support in existing shell
- Full behavioral coaching/AI recommendations for habit plans

---

## User-Facing Behaviors

1. Users can design a habit around identity, anchor (cue), action (response), MVH, reward, and optional temptation bundle.
2. Habit cards allow choosing `STANDARD` or `MVH (2m)` completion for a day.
3. `STANDARD` and `MVH` are mutually exclusive for the same day.
4. A consistency streak continues if either `STANDARD` or `MVH` is recorded.
5. Analytics and heatmaps visually distinguish `STANDARD` vs `MVH` completions.
6. Users can complete a structured Weekly Review with:
   - Done
   - Slipped
   - Adjustment (one change)
   - Anchors (next-week look-forward plan)
7. Users can explicitly sync the Weekly Review plan to Calendar.
8. Habit-generated Calendar blocks can be moved/resized/deleted in Calendar, and those edits write back to the linked Weekly Review plan.

---

## Data Model Changes (Persisted Props / Collections)

### `habit` page props (expanded)

Existing fields remain supported; new fields are added with backward-compatible defaults.

- `identity_statement` (`string`)
- `anchor_cue` (`string`)
- `action_response` (`string`)
- `mvh_action` (`string`)
- `reward_signal` (`string`, optional)
- `temptation_bundle_want` (`string`, optional)
- `temptation_bundle_need` (`string`, optional)
- `completed_dates` (`string[]`, existing; interpreted as `STANDARD` completions)
- `mvh_dates` (`string[]`, new)
- `schedule_templates` (`array`, new; weekly anchor planning templates)
- `sync_to_calendar` (`bool`, optional)
- `calendar_block_type` (`string`, optional; expected values `event|task|reminder|deep-work`)
- `streak` (`number`, existing; consistency streak)

#### Compatibility default

- Existing `completed_dates` history is treated as `STANDARD` completion history.
- Missing `mvh_dates` defaults to `[]`.

### `habit_week_review` page props (new kind)

- `week_start_date` (`YYYY-MM-DD`, Monday)
- `done_notes` (structured text/list payload)
- `slipped_notes` (structured text/list payload)
- `adjustment_note` (single text value)
- `anchor_plan_items` (array of planned habit instances / anchor blocks)
- `last_calendar_sync_at` (timestamp, optional)
- `last_calendar_sync_result` (object, optional)

### `habit_system` page props (optional v1 support, single workspace/system config)

- `environment_checklist_items`
- `pinned_habit_ids`
- `weekly_review_day`
- `weekly_review_time`
- `look_forward_horizon_days`

If not implemented as a separate page in the first coding slice, the same shape may be temporarily persisted as Habits view settings, but the contracts/ADR target remains a dedicated persisted entity.

### `calendar_event` linkage props for habit-generated blocks

- `habit_generated` (`bool`)
- `habit_id` (`string`)
- `habit_review_id` (`string`)
- `habit_plan_instance_id` (`string`)

These fields provide deterministic linkage for bidirectional sync and idempotent reconciliation.

---

## IPC / Contract Changes (to lock in `cortex-os-contracts` before coding)

### 1) Upgrade `habits.toggle` (preserve command name)

Command remains `habits_toggle` / `habits.toggle`.

#### Request

- `pageId: string`
- `date: string` (`YYYY-MM-DD`)
- `completionType?: "standard" | "mvh"` (default `standard`)

#### Semantics

- Toggle selected completion mode for the date
- Enforce same-day mutual exclusivity between `completed_dates` and `mvh_dates`
- If the selected mode is already present, remove it (returns to no completion for that day)

### 2) Extend `habits.getSummary` response (backward-compatible)

Preserve existing fields and add split metrics.

#### Existing (retained)

- `pageId`
- `title`
- `streak`
- `completions` (combined consistency total)
- `windowCompletions` (combined consistency total within requested window)

#### New (planned)

- `standardCompletions`
- `mvhCompletions`
- `windowStandardCompletions`
- `windowMvhCompletions`

### 3) Add `habits.syncWeekPlan` command

New command for deterministic sync of Weekly Review planned habit blocks into Calendar.

#### Request

- `reviewId: string`

#### Response

- `created: number`
- `updated: number`
- `deleted: number`
- `skipped: number`
- `eventIds: string[]`

### 4) Extend calendar command semantics (same command names)

No new calendar command names are required for v1, but contracts docs must state linked behavior for habit-generated events:

- `calendar.rescheduleEvent` updates linked `habit_week_review.anchor_plan_items` when `habit_generated=true`
- `calendar.deleteEvent` removes/marks removed the linked planned instance when `habit_generated=true`

---

## Calendar Sync Linkage Model (Bidirectional v1)

### Source of truth model

- Weekly Review plan items are canonical for habit schedule intent.
- Calendar blocks are projections of planned instances.
- Calendar edits are allowed and write back to the linked planned instance, preserving a single logical schedule state.

### Link identity

Each planned instance in `anchor_plan_items` receives a stable `habit_plan_instance_id`.

Generated Calendar blocks store:

- `habit_review_id`
- `habit_id`
- `habit_plan_instance_id`

This supports idempotent upsert and direct reverse lookup on calendar edits.

### Sync lifecycle

1. User edits next-week anchors in Weekly Review.
2. User triggers “Sync to Calendar”.
3. Backend `habits.syncWeekPlan` upserts/deletes local `calendar_event` pages.
4. Calendar UI displays habit-generated blocks (with metadata).
5. Calendar move/resize/delete flows call existing calendar commands.
6. Backend calendar commands detect habit linkage and update Weekly Review plan state.

### Conflict/precedence (v1)

- Weekly Review explicit sync is authoritative for create/update/delete reconciliation runs.
- Calendar edits after sync update the linked plan instance immediately.
- Changing calendar event title/description does not rewrite the habit template or identity fields in v1.

---

## TDD Plan by Repo

### `cortex-os-contracts`

#### Tasks

- Update IPC wiring matrix rows:
  - `habits.toggle`
  - `habits.getSummary`
  - `habits.syncWeekPlan` (new)
  - Calendar linked semantics note for `calendar.rescheduleEvent` / `calendar.deleteEvent`
- Add changelog entry for habits/calendar-linked contract evolution

#### Verification

- Docs review for field naming consistency (camelCase request/response docs)
- Cross-reference handlers/FE usage notes

### `cortex-os-backend`

#### Red (tests first)

- Storage test: `STANDARD` toggle add/remove in `completed_dates`
- Storage test: `MVH` toggle add/remove in `mvh_dates`
- Storage test: same-day mutual exclusivity
- Storage/App test: streak computed from union of `completed_dates` and `mvh_dates`
- App test: `habits_get_summary` returns split + legacy combined counts
- App test: `habits_sync_week_plan` idempotent upsert behavior
- App test: `calendar_reschedule_event` updates linked habit plan
- App test: `calendar_delete_event` updates linked habit plan

#### Green (minimal implementation)

- Extend repository habit toggle to be mode-aware
- Update/extend habit summary DTO and handler
- Add week-plan sync handler and calendar event linkage writes
- Extend calendar reschedule/delete handlers for linked habit behavior

### `cortex-os-frontend`

#### Red (tests first)

- `backend.smoke` for `toggleHabit(..., completionType)` payload
- `backend.smoke` for `syncHabitWeekPlan` payload
- Hook tests for dual-state completion and Weekly Review sync result handling
- UI tests for dual buttons + multi-state heatmap + Weekly Review sections
- Calendar hook/UI tests for habit-generated event metadata handling

#### Green (minimal implementation)

- Extend `types.ts`, `services/backend.ts`, `services/normalization.ts`
- Add/extend Habits controller hooks (ADR-0017)
- Rework `views/Habits.tsx` and supporting components for Atomic Habits + Weekly Review
- Surface habit-generated calendar metadata in existing calendar views

### `cortex-os` (integration)

#### Tasks

- ADR + implementation plan + FR updates + traceability planning note + MEMORY updates
- Final traceability expansion and submodule pin sync after component PR merges

---

## Risks and Rollback Notes

### Key Risks

1. **Bidirectional sync complexity**
   - Calendar edits and Weekly Review sync can drift without stable instance IDs.
2. **Timezone/streak correctness**
   - UTC-based date handling may cause off-by-one streak behavior for local users.
3. **Backward compatibility**
   - Existing FE/BE assumptions around `completed_dates` and `habits_toggle` may break if not defaulted carefully.
4. **UI scope creep**
   - Habits redesign includes substantial UX surface and calendar integration touchpoints.

### Mitigations

- Stable `habit_plan_instance_id` linkage on both sides
- Preserve `habits_toggle` command name with default `completionType`
- Preserve legacy summary fields while adding split metrics
- Ship in paired PR sequence with docs/contracts first and TDD per repo

### Rollback Notes

- If bidirectional sync proves unstable, degrade to one-way sync by disabling linked calendar write-back while preserving generated-block metadata.
- If Weekly Review UI scope slips, ship core Atomic habit model + dual completion first, keeping `habit_week_review` behind feature-flagged UI until stable.

---

## Acceptance Criteria

1. Atomic Habits plan fields (identity/cue/action/MVH/reward) are documented and accepted via ADR-0032.
2. Contracts plan defines mode-aware habit toggle and split summary metrics without breaking existing clients.
3. FR-011 explicitly covers Atomic Habits + Weekly Review + look-forward calendar sync behavior.
4. FR-015 and FR-026 acknowledge habit-generated calendar/schedule blocks.
5. Traceability remains truthful (current implementation preserved; planned expansion clearly marked).
6. MEMORY records ADR acceptance and docs-first kickoff with pending paired PR implementation.
7. Follow-on implementation can proceed without unresolved interface decisions.

---

## PR Sequencing (Paired PR Requirements)

1. `cortex-os` docs PR (this pass):
   - implementation plan
   - ADR-0032 (`ACCEPTED`)
   - FR updates
   - traceability planning note
   - MEMORY update
2. `cortex-os-contracts` PR:
   - habits IPC updates + calendar-linked semantics + changelog
3. `cortex-os-backend` PR:
   - mode-aware habit toggle, summary split metrics, week-plan sync, linked calendar updates
4. `cortex-os-frontend` PR:
   - types/normalization/backend gateway/hooks/views/tests for Atomic Habits + Weekly Review
5. `cortex-os` integration pin/docs sync PR:
   - submodule SHA bumps
   - traceability evidence expansion
   - release-process/MEMORY updates

---

## Doc Sync Checklist Mapping (Integration Repo)

Mapping to `/Users/jdtarriela/.codex/worktrees/df8f/cortex-os/.system/DOC_SYNC_CHECKLIST.md`:

- `docs/traceability.md`:
  - This pass adds a planning note only (no fake implementation evidence)
  - Follow-up pass expands file/test mappings after component merges
- `docs/functional_requirements.md`:
  - `FR-011`, `FR-015`, `FR-026` updated in this pass
- `.system/MEMORY.md`:
  - docs-first kickoff + ADR acceptance recorded in this pass
- Submodule SHAs:
  - deferred until FE/BE/contracts implementation PRs merge

