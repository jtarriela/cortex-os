# ADR-0018: DayFlow Calendar Integration + Centralized Calendar Workspace

## Status

PROPOSED (revised 2026-02-20)

## Context

Cortex currently renders calendar UX with custom React/Tailwind week/month grids and a separate Today timeline. The behavior is feature-rich (drag/drop, resize, event detail edits, Google source badges), but the rendering layer is bespoke and duplicated across views.

The DayFlow upstream repository was cloned locally and evaluated from source (`/Users/jdtarriela/proj/calendar`, commit `aca8f8f`). This changed the ADR in five important ways:

1. **Month scrolling/virtualization is present upstream** (`useVirtualMonthScroll`, buffered visible window, dynamic week loading).
2. **DayFlow is not a pure controlled-events component by default**: `useCalendarApp` keeps a persistent `CalendarApp` instance; `updateConfig()` does not reconcile `events`.
3. **Drag-and-drop is plugin-based** (`@dayflow/plugin-drag`) and emits event mutations, not a rich external drop-intent contract by default.
4. **Read-only controls are app-level** (`readOnly`, `ReadOnlyConfig`), not first-class per-event permissions.
5. **Google integration is not built into DayFlow**; Cortex backend/frontend remains system-of-record for OAuth/sync/reconciliation.

Existing Cortex Google sync implementation already provides:

- OAuth + discovery + sync commands: `integrations_google_auth`, `integrations_google_calendars`, `integrations_trigger_sync`
- inbound Google event ingestion and reconciliation
- outbound Cortex calendar create/update/delete with `cortex_page_id` mapping and conflict handling

Relevant FRs: FR-001, FR-004, FR-015, FR-017, FR-018, FR-026, FR-027.

## Decision

We will keep the DayFlow adoption direction, but **change from direct migration to a gated integration strategy** centered on a single frontend calendar workspace.

### 1) Frontend Architecture: Centralized Calendar Workspace

Create one calendar domain/controller area in frontend (workspace-level state + adapter + permission policy), and have Day/Week/Month views render from it.

- Day view (Today timeline)
- Week planner
- Month view with continuous scroll/navigation in the same workspace

Views remain thin and consume hooks/controllers (ADR-0017), not direct service calls.

### 2) Adapter + State Ownership Strategy

Cortex remains canonical for events/tasks/sync policy. DayFlow is rendering + interaction infrastructure.

- Maintain a stable DayFlow app instance per workspace.
- Sync event changes via delta operations (`add/update/delete`), not full app recreation.
- Use an adapter boundary for:
  - `CalendarEvent` <-> DayFlow event mapping
  - permission mapping (`source`, `sync_external`, `read_only`)
  - callback translation (`create/move/resize/delete`) into Cortex update paths

### 3) Month View Performance Requirement

DayFlow’s virtual month scrolling can satisfy FR-015 only if Cortex datasets remain performant under realistic load.

- Validate continuous month scrolling with dense data before rollout.
- Treat virtualization as a prerequisite pass/fail gate, not an assumption.

### 4) Task/Event Drag Semantics Gate

Before full migration, we must prove that task and event interactions remain unambiguous:

- task drop into timed slot
- task drop/create in all-day context
- existing event move/resize in week and month views

If required drop-intent precision is unavailable from current callbacks, integration must add an extension layer (or upstream contribution) before rollout.

### 5) Google Sync + Editability Policy (No Regression)

DayFlow does not implement Google OAuth/sync. Cortex keeps ownership of all Google flows and two-way sync behavior.

Policy for this ADR:

- inbound Google external events remain read-only in Cortex UI (FR-027 baseline)
- Cortex-managed events remain editable and two-way synced
- permission decisions come from backend metadata, not UI inference

Because DayFlow read-only is currently app-level, mixed editability (some events editable, some not) requires adapter/plugin enforcement and explicit tests.

### 6) Accessibility and Responsive Constraints

DayFlow keyboard behavior is pluginized (`@dayflow/plugin-keyboard-shortcuts`), so keyboard support and a11y compliance are integration responsibilities.

- a11y and responsive audits are mandatory before week-view replacement
- keyboard plugin activation and verification are required for FR-018 parity

### 7) Dependency and Fork Strategy

- Start upstream, pin to an explicit version range, and upgrade deliberately.
- Keep DayFlow isolated behind adapter + tests so Cortex can update alongside upstream safely.
- Fork only if blocking defects/features (for Cortex requirements) are not solved upstream in acceptable time.

## Integration Gates (Required Before ACCEPTED)

1. **Performance Gate**: month continuous scroll benchmark passes target FPS/memory/no-freeze thresholds on representative data.
2. **State Sync Gate**: adapter proves O(changed-items) updates without full calendar remount/reset on single-event edits.
3. **Drag Semantics Gate**: prototype confirms task vs event intent disambiguation (timed vs all-day) and correct persistence.
4. **Google Policy Gate**: product/design sign-off for inbound Google read-only behavior (or explicit approved exception scope).
5. **A11y/Mobile Gate**: keyboard navigation + focus + responsive audit passes defined checklist.

## FR Coverage

| FR | Requirement Linkage | DayFlow Integration Impact |
|----|---------------------|----------------------------|
| FR-001 | Task management / scheduling edits | Task-backed calendar actions must keep existing task update semantics |
| FR-004 | Today dashboard schedule | Day timeline draws from centralized calendar workspace |
| FR-015 | Day/Week/Month calendar + continuous month scroll | DayFlow used as UI engine behind gated performance validation |
| FR-017 | Responsive navigation/layout | DayFlow views must preserve mobile/desktop behavior in Cortex shell |
| FR-018 | Keyboard shortcuts/accessibility behaviors | Requires explicit keyboard plugin and audit for parity |
| FR-026 | Schedule timeline of tasks/events | Shared event source preserved through adapter layer |
| FR-027 | Google sync + inbound read-only + outbound two-way | Preserved in Cortex backend; DayFlow remains presentation/interaction layer |

## Implementation Shape (Planned)

1. Build `CalendarWorkspace` hook/controller as the single frontend calendar state boundary.
2. Implement DayFlow adapter with event/permission mapping and delta sync.
3. Run spike prototype for week view + task/event drag semantics.
4. Add month virtual-scroll validation harness with realistic event density.
5. Add permission guards for mixed editability behavior (Google inbound vs Cortex-managed).
6. Run a11y/mobile audit and keyboard parity tests.
7. Migrate views incrementally: Week -> Day -> Month (same workspace/state source).

## Consequences

### Positive

- One calendar architecture for Day/Week/Month and Today schedule.
- Lower duplicated calendar UI logic in Cortex.
- Explicit guardrails against perf and UX regressions.

### Risks

- Adapter complexity can become a bottleneck without strict diff-sync discipline.
- Per-event permission behavior may need extension work due global read-only model.
- Upstream API/plugin changes can impact integration timing.

## Paired-PR / Contracts Impact

No new IPC contract is required by this ADR alone. If implementation changes calendar payloads, permissions fields, or command behavior, paired updates across contracts/frontend/backend are mandatory per repo protocol.
