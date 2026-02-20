# ADR-0018: DayFlow Calendar Integration + Centralized Calendar Workspace

## Status

PROPOSED (2026-02-20)

## Context

Cortex currently renders calendar UX with custom React/Tailwind week/month grids and a separate Today timeline. The behavior is feature-rich (drag/drop, resize, event detail edits, Google source badges), but the rendering layer is bespoke and duplicated across views.

This creates three integration pressures:

1. We need a stronger shared calendar surface for Day, Week, and Month.
2. We need Month view to support continuous month navigation/scrolling.
3. We need to preserve Google two-way sync semantics already implemented in backend integration commands.

Relevant FRs: FR-004, FR-015, FR-026, FR-027 (plus task scheduling overlap with FR-001).

## Decision

We will integrate `dayflow-js/calendar` as the **calendar UI engine** while keeping Cortex as the source of truth for data, sync rules, and permissions.

### 1) Centralized Calendar Workspace (Frontend Architecture)

Create a centralized calendar module in frontend (single owner for calendar state + mapping + rules), then compose views from it:

- `Day` view surface (Today-focused schedule rendering)
- `Week` planner surface
- `Month` surface inside the calendar workspace, with continuous month navigation/scrolling

Views should consume this workspace/controller, not implement independent calendar logic.

### 2) Data Ownership + Adapter Boundary

DayFlow will be treated as a rendering/interaction dependency only.

- Canonical model remains Cortex `CalendarEvent` + backend page props.
- Use an adapter layer to map `CalendarEvent` <-> DayFlow event shape.
- DayFlow callbacks (`drop`, `resize`, `create`, `delete`, `click`) call existing Cortex services/hooks.

This isolates vendor-specific APIs and allows replacement without rewriting domain logic.

### 3) Google Calendar Behavior (No Regression)

DayFlow does not provide built-in Google OAuth/sync orchestration. Google integration remains owned by Cortex backend/frontend integration flows.

Existing behavior to preserve:

- OAuth + calendar discovery + manual sync trigger via `integrations_google_auth`, `integrations_google_calendars`, `integrations_trigger_sync`.
- Inbound external events are rendered as Google-sourced entries.
- Outbound Cortex-managed events continue two-way reconciliation through backend sync logic.

Two-way edits policy in calendar UI:

- `source = google` and non-Cortex-managed events: read-only in UI.
- Cortex-managed events (`source = cortex` and/or sync-managed flags): editable and syncable.
- UI permission flags must be derived from backend-owned metadata, not guessed in the view.

### 4) Month View Requirement

Month view will support:

- week/month toggle in the calendar workspace
- continuous month navigation/scrolling (not single static month only)
- day-cell drill-down to day/week context

### 5) Dependency/Fork Strategy

- Start with upstream DayFlow package (no fork initially).
- Pin to an explicit minor version range; upgrade intentionally after validation.
- Use adapter boundary + integration tests to keep upgrade risk low.
- Fork only if blocked by critical defects/features and upstream turnaround is not viable.

## FR Coverage

| FR | Requirement Linkage | DayFlow Impact |
|----|---------------------|----------------|
| FR-004 | Today dashboard includes today schedule | Day view rendering sourced from centralized calendar workspace |
| FR-015 | Calendar workspace supports day/week/month with drag/update/delete | DayFlow becomes rendering/interaction engine; Cortex remains business logic owner |
| FR-026 | Today schedule timeline of tasks/events | Same event source, now rendered through shared calendar layer |
| FR-027 | Google calendar sync, read-only inbound, outbound Cortex sync | Preserved via existing backend integration; DayFlow only visualizes and dispatches actions |
| FR-001 | Scheduled task edits from calendar | Task-backed event edits continue through existing task update paths |

## Implementation Shape (Planned)

1. Introduce a `calendar workspace` controller/hook layer in frontend.
2. Add DayFlow adapter module for event mapping + permission mapping.
3. Migrate Week view rendering to DayFlow first (keep existing service/store behavior).
4. Add Day view rendering for Today schedule surface.
5. Add Month continuous navigation/scrolling in the same workspace.
6. Enforce Google read-only/editable policy at adapter level.
7. Expand hook/integration tests to lock parity behavior.

## Consequences

### Positive

- Single calendar source for Day/Week/Month UI behavior.
- Lower rendering complexity and less duplicated drag/resize code.
- Clear boundary for upgrades and optional future vendor replacement.

### Risks

- Adapter mistakes could break task-vs-event persistence semantics.
- Vendor upgrades may introduce UI API changes.
- Read-only/editable policy must be explicit to avoid accidental Google edits.

## Paired-PR/Contracts Impact

No new IPC contract is required for this ADR by itself. If calendar payloads or command semantics change during implementation, paired contracts updates are mandatory per repo protocol.
