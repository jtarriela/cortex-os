# ADR-0021: Full PM Timeline (Gantt) + visx Standardization

**Status:** ACCEPTED
**Date:** 2026-02-22
**Deciders:** Architecture review
**FR:** FR-001, FR-002, FR-007, FR-009, FR-010, FR-011, FR-012
**Related:** ADR-0017 (frontend hooks layer), ADR-0020 (block editor + projects/tasks)

---

## Context

ADR-0020 delivered block-based editing for project/task/notes content and moved milestone editing into markdown body semantics. Remaining planning gaps were:

- no first-class timeline planning model for tasks and milestones
- no dependency scheduling behavior for project timelines
- no unified milestone representation for checklist editing and timeline rendering
- chart stack inconsistency (`recharts` mixed with newer visualization needs)

Project delivery now requires a full PM-capable timeline surface, while preserving canonical page persistence commands and the hooks-layer architecture constraints from ADR-0017.

---

## Decision

### 1) Full PM planning fields on tasks

Task planning metadata is first-class in frontend type + normalization + persistence:

- `plannedStartDate`, `plannedEndDate`
- `baselineStartDate`, `baselineEndDate`
- `actualStartDate`, `actualEndDate`
- `dependencies: TaskDependency[]`

Dependency model is limited to `FS` with optional non-negative `lagDays`.

### 2) Milestones use dual-write synchronization

Milestones are represented in both:

- markerized checklist lines in project body (`<!-- milestone:{id} -->`)
- first-class milestone pages (`project_milestone`)

Synchronization rule:

- run on project body save and milestone CRUD
- milestone page is authoritative on conflict (page-wins rewrite of body line)
- markerized line removal hard-deletes milestone page
- checkbox mapping: checked -> `COMPLETED`, unchecked -> `NOT_STARTED`

### 3) Timeline behavior and computation

Project detail includes a Timeline tab with:

- zoom levels (`day`, `week`, `month`, `quarter`)
- dependency links
- milestone markers
- baseline overlays
- critical-path highlighting
- drag/resize planning edits

Critical path and FS+lag cascade adjustments are computed client-side and are not persisted as derived fields.

### 4) Persistence surface remains canonical page commands

No new backend command family is introduced for timeline/milestones. Persistence remains:

- `vault_create_page`
- `collection_query`
- `page_update_props`
- `vault_delete`

Backend updates are limited to collection kind mapping support for milestone pages.

### 5) visx standardization across app charts

Visualization stack is standardized on visx. Existing `recharts` usage is removed and replaced with shared visx primitives and view-controller hooks for modified views.

---

## Implementation Status (2026-02-22)

- `frontend/types.ts` updated with task planning/dependency fields and `ProjectMilestone`
- `frontend/services/backend.ts` includes project delete + milestone CRUD facade methods
- `frontend/services/normalization.ts` includes planning/milestone normalization + `col_project_milestones`
- `frontend/hooks/useProjectsIndex.ts` implements menu/drag/delete controller behavior (ADR-0017 compliant)
- `frontend/utils/projectMilestones.ts` implements marker parsing/serialization + page-wins reconciliation helpers
- `frontend/hooks/useProjectTimeline.ts` + `frontend/components/projects/GanttChart.tsx` deliver timeline behavior
- `frontend/views/ProjectDetail.tsx` includes Timeline tab + dual-write sync flow
- `backend/crates/core/src/lib.rs` maps `col_project_milestones -> project_milestone`
- `contracts/docs/technical_planning/002_IPC_WIRING_MATRIX.md` documents planning fields, milestone CRUD mapping, dependency model, and dual-write policy
- `frontend/package.json` removes `recharts` and pins visx v4 alpha modules
- `frontend/views/Finance.tsx`, `frontend/views/Goals.tsx`, `frontend/views/Habits.tsx`, `frontend/views/Journal.tsx`, `frontend/views/TodayDashboard.tsx` migrated to visx-based rendering

---

## Consequences

### Positive

- Timeline planning and milestone scheduling are now representable and editable in-project.
- Project checklist UX and first-class milestone entities remain synchronized.
- Contracts/backend stay stable by reusing canonical page mutation/query commands.
- Chart rendering stack is unified, reducing long-term UI dependency drift.

### Risks

- Dual-write synchronization adds reconciliation complexity.
- visx alpha dependency requires stricter compatibility checks.
- Client-side dependency cascade/critical-path logic can diverge if model rules change without tests.

### Mitigations

- Dedicated dual-write parser/conflict/deletion tests.
- Hook/component tests for timeline behavior and rendering contracts.
- visx migration regression tests across migrated dashboard/domain views.
