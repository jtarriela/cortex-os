# Travel v2 Stage 6 — Calendar Push + Release Hardening Implementation Plan (ADR-0031)

**Status:** Completed (Merged + Pinned)
**Date:** 2026-02-24
**Related ADR:** [`ADR-0031`](../adrs/ADR-0031-travel-v2-stage6-calendar-push-and-release-hardening.md)

---

## Summary

This document is the decision-complete implementation plan for Travel v2 Stage 6.

Stage 6 delivers:

- one-way Travel -> Calendar push for itinerary items
- idempotent upsert semantics with safe overwrite behavior
- Travel UI support for day-based calendar push
- WeekDashboard visibility hardening so local `calendar_event` pages (including Habits/Travel-generated events) appear in Week/DayFlow
- release hardening gates (functional, reliability, docs/evidence)

Core design choice (locked):

- Travel push creates/updates **local** `calendar_event` pages (`source="cortex"`, `read_only=false`)
- Travel remains source of truth
- Calendar edits do **not** write back to Travel in v1

---

## Scope

### In Scope (v1)

- New `travel.pushItemsToCalendar` IPC contract + backend handler
- Day-based Travel UI push flow (calendar tab)
- Batch/idempotent create/update/skip/error result reporting
- `trip_item.calendar_event_id` linkage persistence
- Travel-generated calendar metadata props (`travel_generated`, `travel_trip_id`, `travel_item_id`, etc.)
- WeekDashboard local-event visibility hardening (preserving task mirror dedupe + Google filtering)
- Contracts/backend/frontend test coverage for Stage 6 core paths
- Integration docs kickoff (ADR status + implementation plan doc)

### Out of Scope (v1)

- Reverse sync from Calendar edits/deletes into Travel items
- Trip-timezone-aware projection semantics (uses device/system local wall-time interpretation at push time)
- Per-item checkbox selection UI (contract supports `itemIds[]`; UI is day-based first)
- Direct "open linked calendar event" navigation from Travel items

---

## Cross-Repo PR Matrix (Planned Merge Order)

1. `cortex-os-contracts`
   - add `travel.pushItemsToCalendar` wiring row
   - Stage 6 semantics notes + additive props notes
   - changelog `0.10.6`
2. `cortex-os-backend`
   - implement `travel_push_items_to_calendar`
   - idempotent local `calendar_event` projection + tests
3. `cortex-os-frontend`
   - wrapper/types/normalization
   - `useTravelCalendarPush` + `TravelCalendarPushPanel`
   - `Travel.tsx` calendar tab and linked indicators
   - WeekDashboard hardening + tests
4. `cortex-os` (integration)
   - FR / traceability / MEMORY / release process / ADR status finalization
   - submodule SHA pinning after merges

---

## Contract-First Interfaces (Locked)

### New Command

- `travel.pushItemsToCalendar` -> backend handler `travel_push_items_to_calendar`

### Request (v1)

- `tripId: string`
- `dayDate?: string` (`YYYY-MM-DD`)
- `itemIds?: string[]`
- `overwriteExisting?: boolean` (default `false`)
- `syncExternal?: boolean` (optional tri-state)

### Selection Validation

- At least one of `dayDate` or non-empty `itemIds[]` is required.
- If both are provided, backend applies intersection.

### Response (v1)

- `created: number`
- `updated: number`
- `skipped: number`
- `errors: number`
- `results: TravelCalendarPushItemResult[]`
- `warnings: string[]`

### `TravelCalendarPushItemResult`

- `itemId: string`
- `eventId?: string`
- `status: "created" | "updated" | "skipped" | "error"`
- `reasonCode?: string`
- `message?: string`

### Semantics Notes (Contracts Docs)

- One-way projection only (no reverse sync from calendar to travel).
- `overwriteExisting=false` skips linked existing events.
- `overwriteExisting=true` updates only Travel-managed fields and preserves user-owned fields.
- Travel-generated events are local `calendar_event` pages (`source="cortex"`, `read_only=false`).

### Additive Props Notes

- `trip_item.calendar_event_id`
- `calendar_event.travel_generated`
- `calendar_event.travel_trip_id`
- `calendar_event.travel_item_id`
- `calendar_event.travel_item_type`
- `calendar_event.travel_day_date`

---

## Backend Architecture + Data Model

### Command Surface

- Add `#[tauri::command] fn travel_push_items_to_calendar(...) -> CmdResult<TravelCalendarPushResult>` in `backend/crates/app/src/lib.rs`
- Delegate implementation to `backend/crates/app/src/travel_calendar_push.rs`

### Responsibilities

- Validate selection (`dayDate` / `itemIds[]`)
- Load `trip_item` rows scoped by trip
- Project item times (`day_date`, `start_time`, `end_time`) into calendar datetimes
- Resolve linked event by `trip_item.calendar_event_id`
- Fallback resolve by `calendar_event.travel_item_id` when link is stale
- Create/update/skip/error row accounting
- Persist/relink `trip_item.calendar_event_id`
- Emit page events for created/updated items/events
- Maintain indexing parity for travel-item relinks and calendar-event writes

### Projection Rules (Locked)

- Missing `day_date` -> `skipped` (`reasonCode="missing_day_date"`)
- `start_time` present -> timed event
- missing `end_time` -> default `+60m`
- parsed `end <= start` -> clamp to `start + 60m` + warning/message
- missing `start_time` -> all-day event (`all_day=true`, exclusive next-day end)

### Overwrite Rules (Locked)

- `overwriteExisting=false`: create unlinked items; skip linked items
- `overwriteExisting=true`: update linked Travel-owned events if managed fields differ; skip unchanged

### Managed vs Preserved Fields

Managed on overwrite:

- `title`, `start`, `end`, `all_day`, `type`, `source`, `read_only`
- Travel linkage props (`travel_*`)
- `sync_external` only when request explicitly provides `syncExternal`

Preserved on overwrite:

- `description`, `location`, `linked_note_id`, `color`, `body`
- Google linkage props (`google_event_id`, `google_calendar_id`, `google_calendar_name`)

### Ownership Safety Checks

- Never overwrite non-`calendar_event` page
- Never overwrite read-only event (`read_only=true`)
- Never overwrite linked event not Travel-owned for the same `travel_item_id`
- If linked ID is stale/missing, fallback lookup by `travel_item_id` and relink if exactly one match

### Path Convention

- Created events under `calendar_event/travel/...`

---

## Frontend Architecture + UX

### Types / Normalization / Wrapper

- Add `TripItem.calendarEventId?: string`
- Add `TravelCalendarPushResult` and `TravelCalendarPushItemResult`
- Map `trip_item.props.calendar_event_id` -> `TripItem.calendarEventId`
- Add `pushTravelItemsToCalendar(params)` wrapper in `frontend/services/backend.ts`

### Controller (ADR-0017)

- `frontend/hooks/useTravelCalendarPush.ts`
- Responsibilities:
  - derive day options from Travel workspace items
  - day selection state
  - overwrite + advanced `syncExternal` toggle state
  - execute push command
  - store loading/error/result state
  - refresh selected trip after successful push

### View / Panel

- `frontend/components/travel/TravelCalendarPushPanel.tsx`
- `frontend/views/Travel.tsx`
  - add `calendar` tab
  - mount `TravelCalendarPushPanel`
  - update header label to Stage 1-6
  - surface minimal linked indicator on Travel items via `calendarEventId`

### WeekDashboard Hardening (Required)

- `frontend/hooks/useWeekDashboard.ts`
- Include local non-task `calendar_event` pages in `calendarItems`
- Preserve:
  - Google calendar filtering
  - Google mirror suppression for scheduled task pages
  - local task-bridge dedupe where task pages already represent schedule

---

## TDD Matrix by Repo

### `cortex-os-contracts`

- Verify wiring row names match backend command/handler
- Verify request/response field names are camelCase in docs
- Verify one-way semantics + overwrite behavior + additive props notes
- Verify changelog entry `0.10.6`

### `cortex-os-backend`

Projection/parsing tests:

- timed item (`start_time`/`end_time`) -> timed event
- missing `end_time` -> default `+60m`
- reversed end -> clamp + warning
- untimed item -> all-day event
- missing `day_date` -> skipped row

Idempotence/safety tests:

- first push creates event + writes `calendar_event_id`
- re-push `overwriteExisting=false` skips linked event
- re-push `overwriteExisting=true` updates managed fields only
- unchanged overwrite path -> skipped (`unchanged`)
- stale link -> recreate/relink or fallback relink by `travel_item_id`
- non-Travel-owned / read-only linked event -> error row, no mutation
- preserve existing `sync_external` when request omits `syncExternal`
- preserve user-owned fields/body on overwrite

Regression tests:

- Travel workspace still loads `trip_item` pages with additive `calendar_event_id`
- Calendar behavior for non-Travel events unchanged

### `cortex-os-frontend`

Wrapper/normalization tests:

- `pushTravelItemsToCalendar` sends camelCase payload fields
- response normalizes row fields/counts
- `TripItem.calendarEventId` normalizes from `calendar_event_id`

Hook tests (`useTravelCalendarPush`):

- defaults (`overwriteExisting=false`, `syncExternal` off/omitted)
- day selection + payload build
- successful push refreshes selected trip
- command failure surfaces error state
- result rows remain renderable across rerenders/refreshes

WeekDashboard tests:

- local non-task `calendar_event` pages appear in `calendarItems`
- local task-bridge event duplicates remain deduped when scheduled task page exists
- Google filtering / read-only protections unchanged

Panel/UI tests (targeted):

- `TravelCalendarPushPanel` renders day selector, toggles, CTA, result summary
- `Travel.tsx` calendar tab mount path smoke test (optional if covered by integration/manual QA)

---

## Release Hardening Gates + Evidence Checklist

### Functional Gates

- Mixed legacy + v2 data loads and edits without regressions
- Imported reservations remain visible and survive reloads
- Travel push create/update/skip/error flows deterministic
- Google Maps unsupported export fallback remains explicit/actionable

### Reliability Gates

- Push failures do not corrupt Travel items or unrelated calendar events
- Network/provider failures (import/routing/AI) surface actionable errors
- Offline/local-only use still supports Travel editing + local calendar push

### UI Hardening Gates

- Travel-pushed events visible in Calendar workspace and WeekDashboard/DayFlow
- Read-only Google events remain protected
- No duplicate task bridge events introduced by WeekDashboard changes

### Documentation / Evidence Gates

- Contracts wiring row + changelog updated
- Traceability updated with Stage 6 code/tests
- ADR status + MEMORY + release process synchronized
- Integration repo pins updated after submodule merges

---

## Merge Order, Pinning, and ADR Lifecycle

### Merge Order (Locked)

1. Contracts
2. Backend
3. Frontend
4. Integration docs + pinning

### ADR Status Transitions

- `PROPOSED` -> `ACCEPTED` when implementation begins
- `ACCEPTED` -> `IMPLEMENTED` only after tests/evidence/docs sync + submodule pinning are complete

### Pinning Notes (Integration Repo)

After component PRs merge:

- bump submodule SHAs in `cortex-os`
- record SHAs + merged PR links in:
  - `docs/integration/002_RELEASE_PROCESS.md`
  - `.system/MEMORY.md`

---

## Explicit Defaults / Assumptions (Locked)

- Canonical implementation doc path is `docs/implementation/` (not `docs/implmentation/` typo path)
- v1 UI exposes **day-based push** only
- Contract supports `itemIds[]` for future selective push UI
- `overwriteExisting` default is `false`
- `syncExternal` omitted means:
  - create -> defaults false
  - update -> preserve existing value
- Travel -> Calendar remains one-way in v1 (no reverse write-back hooks)
- Projection uses device/system local timezone wall-time at push time
- WeekDashboard hardening is in ADR-0031 scope because Travel/Habits local events must be visible in Week/DayFlow

---

## Implementation Status (Current Workspace Snapshot)

Completed and merged/pinned:

- Contracts PR `cortex-os-contracts#30` merged (`d4d905b`) with Stage 6 wiring/changelog docs
- Backend PR `cortex-os-backend#46` merged (`c6204a4`) with `travel_push_items_to_calendar` command/module/tests
- Frontend PR `cortex-os-frontend#56` merged (`f2ea7ff`) with Travel calendar push UI/controller, wrapper/types/normalization, and WeekDashboard hardening/tests
- Integration repo submodule SHAs pinned to the merged component commits
- Integration docs synchronized (`FR`, traceability, MEMORY, release log)
- ADR-0031 status finalized to `IMPLEMENTED`
