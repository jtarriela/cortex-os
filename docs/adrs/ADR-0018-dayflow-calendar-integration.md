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
6. **v3 rendering boundary changed**: `@dayflow/core` runs on Preact and the React adapter bridges custom UI via content-slot portals. Cortex React context/state assumptions must be explicit at this boundary.

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

### 1.1) Preact Boundary + Context Bridging

DayFlow is mounted through a React adapter over a Preact core renderer. Therefore:

- custom event/detail/header/sidebar UI must go through DayFlow content slots
- any Cortex context-dependent behavior (theme, feature flags, permissions, telemetry hooks) must be explicitly bridged through adapter slot props or controlled callbacks
- do not assume Cortex providers automatically flow into all DayFlow-rendered internals

### 2) Adapter + State Ownership Strategy

Cortex remains canonical for events/tasks/sync policy. DayFlow is rendering + interaction infrastructure.

- Maintain a stable DayFlow app instance per workspace.
- Explicitly install/register required plugins during adapter bootstrap:
  - `@dayflow/plugin-drag` (FR-001/FR-015 interaction parity)
  - `@dayflow/plugin-keyboard-shortcuts` (FR-018 parity)
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
- external task drag from Cortex sidebar into calendar surface (HTML5 `dataTransfer`)

DayFlow drag plugin is internal-pointer optimized; Cortex external drop must be implemented in a wrapper layer (`onDragOver`/`onDrop`) that maps drop coordinates to date/time intent. Integration should use DayFlow-exposed drag/date geometry utilities where possible, with fallback to explicit grid geometry mapping owned by Cortex adapter.

### 5) Google Sync + Editability Policy (No Regression)

DayFlow does not implement Google OAuth/sync. Cortex keeps ownership of all Google flows and two-way sync behavior.

Policy for this ADR:

- inbound Google external events remain read-only in Cortex UI (FR-027 baseline)
- Cortex-managed events remain editable and two-way synced
- permission decisions come from backend metadata, not UI inference

Because DayFlow read-only is currently app-level, mixed editability (some events editable, some not) requires adapter/plugin enforcement and explicit tests.

For production rollout, UI snap-back on forbidden edits is not an acceptable steady-state UX. Preferred path is upstream enhancement (or fork if required) to add per-event drag/resize guards.

### 6) Accessibility and Responsive Constraints

DayFlow keyboard behavior is pluginized (`@dayflow/plugin-keyboard-shortcuts`), so keyboard support and a11y compliance are integration responsibilities.

- a11y and responsive audits are mandatory before week-view replacement
- keyboard plugin activation and verification are required for FR-018 parity

### 7) Dependency and Fork Strategy

- Start upstream, pin to an explicit version range, and upgrade deliberately.
- Keep DayFlow isolated behind adapter + tests so Cortex can update alongside upstream safely.
- For per-event mixed editability, attempt upstream contribution first; fork is acceptable if blocking requirements are not delivered in time.

## Integration Gates (Required Before ACCEPTED)

1. **Performance Gate**: month continuous scroll benchmark passes target FPS/memory/no-freeze thresholds on representative data.
2. **State Sync Gate**: adapter proves O(changed-items) updates without full calendar remount/reset on single-event edits.
3. **External Drop Gate**: prototype demonstrates sidebar task HTML5 drag/drop into week and month surfaces with correct timed/all-day intent mapping and persistence.
4. **Google Policy Gate**: product/design sign-off for inbound Google read-only behavior (or explicit approved exception scope).
5. **Mixed Editability Gate**: implementation proves per-event edit guards (Google inbound locked, Cortex-managed editable) without relying on post-drop snap-back; upstream PR/fork plan must be explicit if needed.
6. **A11y/Mobile Gate**: keyboard navigation + focus + responsive audit passes checklist, with `@dayflow/plugin-keyboard-shortcuts` enabled and tested.

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
2. Implement DayFlow adapter with plugin bootstrap (`drag`, `keyboard`), event/permission mapping, and delta sync.
3. Add content-slot/context bridge strategy for Cortex-specific UI and provider-dependent behavior.
4. Run spike prototype for week view with internal drag + external sidebar task drop.
5. Add month virtual-scroll validation harness with realistic event density.
6. Deliver mixed editability enforcement path (upstream PR or fork) for per-event drag/resize permissions.
7. Run a11y/mobile audit and keyboard parity tests.
8. Migrate views incrementally: Week -> Day -> Month (same workspace/state source).

## Consequences

### Positive

- One calendar architecture for Day/Week/Month and Today schedule.
- Lower duplicated calendar UI logic in Cortex.
- Explicit guardrails against perf and UX regressions.

### Risks

- Adapter complexity can become a bottleneck without strict diff-sync discipline.
- Preact/React boundary can hide context assumptions unless explicitly bridged through slots/adapters.
- Per-event permission behavior likely needs upstream drag-plugin extension or a maintained fork.
- Upstream API/plugin changes can impact integration timing.

### Risk Mitigation Strategy

| Risk | Mitigation Strategy | Verification / Exit Criteria | Fallback / Decision Rule |
|------|---------------------|------------------------------|--------------------------|
| Adapter complexity / diff-sync bottleneck | Keep a strict anti-corruption layer in `CalendarWorkspace`: normalized event index (`id -> event`), delta calculator (`add/update/delete` only), and single adapter-owned mutation path. Prohibit full app re-init on ordinary edits. | State Sync Gate passes with representative load and no full remount on single-event edits. Regression tests cover drag, resize, create, delete, and external drop update paths. | If delta sync cannot remain stable/performant, pause migration after week-view spike and keep existing month/day implementations until adapter complexity is reduced. |
| Preact/React boundary context drift | Treat DayFlow as isolated runtime. Route all Cortex-specific rendering through React content slots and typed bridge props/callbacks. Do not rely on Preact defaults for context-dependent behavior (permissions, theme, feature flags, telemetry). | Context bridge checklist passes in integration tests (theme, permissions, feature toggles, telemetry hooks) for Week/Day/Month surfaces. | If any required behavior cannot be bridged reliably, keep that behavior in Cortex-owned wrapper UI rather than DayFlow internal UI. |
| Per-event mixed editability (Google read-only vs Cortex editable) | Implement this as a hard gate: upstream contribution request for per-event drag/resize guards (for example event-level draggable/resizable callbacks). Prepare maintained patch/fork only if upstream SLA misses release needs. No snap-back UX as steady-state. | Mixed Editability Gate passes: read-only events cannot enter drag/resize interaction; Cortex-managed events remain editable; no visible forbidden move then revert pattern. | If event-level guards are unavailable in time, block full replacement for mixed-source editing scenarios and continue on existing calendar for that scope until upstream/fork path is ready. |
| Upstream API/plugin churn | Pin DayFlow versions, run adapter contract tests in CI, and upgrade in scheduled windows only. Keep adapter surface small and versioned to isolate upstream changes. | CI contract suite passes against pinned version and target upgrade candidate before merge. Upgrade checklist is completed per release window. | Freeze on last known-good DayFlow version and defer upgrades when breaking changes are detected without approved migration bandwidth. |

### Execution Plan (Mitigation-Oriented)

1. Build adapter/core invariants first (delta sync + no-remount policy + test harness).
2. Implement React content-slot bridge and validate context-dependent behaviors.
3. Complete external sidebar task-drop prototype and persistence parity checks.
4. Resolve mixed editability via upstream PR (preferred) or controlled fork decision.
5. Run pinned-version CI contract suite and promote only when all gates pass.

## Paired-PR / Contracts Impact

No new IPC contract is required by this ADR alone. If implementation changes calendar payloads, permissions fields, or command behavior, paired updates across contracts/frontend/backend are mandatory per repo protocol.
