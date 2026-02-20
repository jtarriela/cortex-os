# ADR-0017: Frontend Hooks Layer — Controller Pattern for View Logic Extraction

**Status:** PROPOSED
**Date:** 2026-02-20
**Deciders:** Architecture review
**FR:** Frontend (cross-cutting)
**Related:** `frontend/docs/frontend_architecture/000_OVERVIEW.md`, `002_STATE_MANAGEMENT.md`, Epic #25

---

## Context

The frontend follows a 3-layer pattern: services → stores → views. In practice, views contain all business logic inline: data fetching (`useEffect` + service calls), derived state computation, drag-drop handling, keyboard event management, and modal lifecycle.

This created four classes of bugs in Phase 5:

1. **Feedback loops** — TipTapEditor's `useEffect` reset cursor on every keystroke because the parent view's state update flowed back as a prop change
2. **Component identity instability** — `PropertyRow` defined inside render body caused React to unmount/remount inputs on every state change, losing focus
3. **Missing cleanup** — Drag-drop handlers in 2/3 views had no `onDragEnd`, leaving stuck drag state on cancelled drags
4. **Ad-hoc keyboard handling** — Each modal implemented its own Escape logic (or didn't), with no shared pattern for focus trapping or event priority

All four trace to the same root cause: views are too thick. They combine rendering with controller logic, making bugs invisible and testing impractical.

## Decision

Introduce a **hooks layer** (`frontend/hooks/`) as the controller between stores/services and view components.

### Rules

1. **One hook per feature/view**: `useWeekDashboard`, `useTaskDetail`, `useTodayDashboard`, etc.
2. **Views may only contain**: hook calls, JSX, and trivial event wiring (e.g., `onClick={handlers.save}`). No `useEffect`, no service imports, no derived state computation in views.
3. **Hooks own all logic**: data fetching, loading/error state, `useMemo` for derived data, event handlers, cleanup. They return a typed API surface that the view consumes.
4. **Shared utility hooks**: `useModalKeyboard` (Escape + focus trap), `useDragDrop` (drag state machine). These are composed into feature hooks, not used directly in views.
5. **Hook tests are mandatory**: Each hook gets a test file using `renderHook()` from `@testing-library/react`. Tests mock `services/backend` and assert state transitions.

### Layer Responsibility Matrix

| Layer | Imports from | Tested via | Contains |
|-|-|-|-|
| `services/` | `@tauri-apps/api` | Mock `invoke`, verify payloads | IPC adapter, retry, error mapping |
| `stores/` | `services/` | Unit test state transitions | Global shared state, optimistic updates |
| `hooks/` | `services/`, `stores/` | `renderHook()` + mock services | Data fetch, derived state, handlers, cleanup |
| `views/` | `hooks/`, `components/` | React Testing Library | Pure JSX rendering |
| `components/` | (props only) | React Testing Library | Shared presentational UI |

### Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│  Rust Backend (Tauri Commands)                      │
└──────────────────────┬──────────────────────────────┘
                       │ invoke()
┌──────────────────────▼──────────────────────────────┐
│  services/backend.ts          DATA ADAPTER          │
│  - Wraps invoke(), types results                    │
│  - Error mapping, retry (via retry.ts)              │
│  - Normalization (services/normalization.ts)        │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│  stores/*.ts                  GLOBAL STATE          │
│  - Cross-view shared data (tasks, projects, notes)  │
│  - Optimistic updates with rollback                 │
│  - Shell UI state (appStore)                        │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│  hooks/*.ts                   CONTROLLER            │
│  - One hook per feature/view                        │
│  - Data fetching, derived state (useMemo)           │
│  - Event handlers, keyboard, drag-drop              │
│  - Loading/error state machines                     │
│  - Shared: useModalKeyboard, useDragDrop            │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│  views/ + components/         VIEW                  │
│  - Pure JSX render from hook return values          │
│  - No useEffect, no service imports                 │
│  - Trivial event wiring only                        │
└─────────────────────────────────────────────────────┘
```

## Rationale

1. **Testability**: Hook logic can be tested without DOM rendering. View tests become trivial (pass props, check output).
2. **Bug surface reduction**: Cleanup logic (`onDragEnd`, keyboard listener removal) lives in one place per feature, not scattered across JSX.
3. **Reusability**: `useModalKeyboard` replaces 4 ad-hoc Escape implementations. `useDragDrop` replaces 3 drag implementations.
4. **Incremental migration**: Views can be migrated one at a time. A view that calls `useWeekDashboard()` and a view with inline logic can coexist during the transition.

## Consequences

- New directory `frontend/hooks/` added to project structure
- `frontend_architecture/000_OVERVIEW.md` updated with hooks layer in structure diagram
- `frontend_architecture/001_COMPONENTS.md` updated with data flow showing hooks
- `frontend_architecture/002_STATE_MANAGEMENT.md` updated to reflect hooks as the primary consumer of stores/services (not views)
- All new views MUST use a companion hook — no inline `useEffect` data fetching in views
- Existing views migrated incrementally (3 highest-traffic views first: WeekDashboard, TodayDashboard, TaskDetailModal)

## Migration Path

1. **Phase 5a:** Create shared utility hooks (`useModalKeyboard`, `useDragDrop`) + tests
2. **Phase 5b:** Extract `useTaskDetail` from `TaskDetailModal` + tests
3. **Phase 5c:** Extract `useWeekDashboard` from `WeekDashboard` + tests
4. **Phase 5d:** Extract `useTodayDashboard` from `TodayDashboard` + tests
5. **Phase 5e:** Remaining views migrated as they are touched for feature work

## Enforcement

When reviewing PRs that add or modify views:
- New views MUST have a companion `hooks/use*.ts` file
- Views must not import from `services/` directly
- Views must not contain `useEffect` calls that fetch data or manage subscriptions
- All hooks must have corresponding test files in `tests/hooks/`
