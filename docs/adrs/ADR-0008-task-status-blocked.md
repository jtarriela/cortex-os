# ADR-0008: Task BLOCKED Status Is Required

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Architecture review
**FR:** FR-001 (Task Management)
**Supersedes:** N/A
**Related:** `003_TASKS_AND_PLANNING.md` Sections 1.1, 1.2, 8

---

## Context

The architecture defines 5 task statuses:

```
TODO | DOING | BLOCKED | DONE | ARCHIVED
```

The Phase 0 frontend `types.ts` defines 4:

```typescript
type TaskStatus = 'TODO' | 'DOING' | 'DONE' | 'ARCHIVED';
```

The `BLOCKED` status is absent from the frontend. The backend schema (`001_SCHEMA.md`) follows the frontend's 4-value set.

The `BLOCKED` status is architecturally significant because it enables:

1. **Dependency tracking** (`blocked_by: page_id[]` property) — `003_TASKS_AND_PLANNING.md` Section 8
2. **Auto-unblocking** — when all blocking tasks reach `DONE`, the blocked task transitions `BLOCKED → TODO` via a backend hook
3. **Visibility** — blocked tasks are distinguishable in the Kanban board and are excluded from "available work" queries
4. **Status lifecycle** — the state machine in Section 1.2 includes `TODO → BLOCKED`, `DOING → BLOCKED`, and `BLOCKED → DOING` transitions

## Decision

`BLOCKED` is a **required first-class status**, not a computed state. It must be added to the frontend `TaskStatus` type when Phase 1 implementation begins.

### Specification

- `BLOCKED` is a status value like any other — it can be set manually or automatically.
- **Manual:** User marks a task as blocked (e.g., from the Kanban board or task inspector).
- **Automatic:** When `blocked_by` contains page_ids of tasks that are not `DONE`, the backend sets status to `BLOCKED` on save.
- **Auto-unblock:** When all `blocked_by` tasks reach `DONE`, the backend transitions the task from `BLOCKED` to `TODO` and emits a `page_indexed` event.
- The `blocked_by` property is a `multi_select` of page_ids, indexed in the EAV table per ADR-0006.

### Phase 0 Acceptance

The Phase 0 frontend may continue without `BLOCKED` — this is acceptable because:
- Data is ephemeral (in-memory, resets on reload)
- No persistent dependency tracking exists
- The Kanban board has no `BLOCKED` column

The frontend `TaskStatus` type is updated in Phase 1 when Tauri IPC is wired.

## Consequences

- **Frontend type update (Phase 1):** `TaskStatus` union type in `types.ts` gains `'BLOCKED'`.
- **Kanban board (Phase 1):** A new column for `BLOCKED` tasks appears between `DOING` and `DONE`.
- **Task collection schema:** Already includes `BLOCKED` in `003_TASKS_AND_PLANNING.md` Section 1.3 — no change needed.
- **Backend hook:** The `on_task_completed` hook in `003_TASKS_AND_PLANNING.md` Section 8 is the implementation specification.
- **Contracts wiring matrix:** Task status enum in command payloads must include `BLOCKED`.

## Enforcement

When the frontend `TaskStatus` type is modified in Phase 1, `BLOCKED` must be included. Any PR that adds task status handling without `BLOCKED` must be rejected with a reference to this ADR.
