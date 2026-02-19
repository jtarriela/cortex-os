# ADR-0007: Schedule/Calendar Convergence

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Architecture review
**FR:** FR-008 (Calendar), FR-026 (Today Schedule)
**Supersedes:** N/A
**Related:** ADR-0006 (Schema Strategy), `003_TASKS_AND_PLANNING.md` Section 4.3

---

## Context

Two parallel time-tracking systems exist in the Phase 0 frontend:

### System 1: CalendarEvent

Defined in `frontend/types.ts`:

```typescript
interface CalendarEvent {
  id: string;
  title: string;
  start: Date;
  end: Date;
  type: 'event' | 'task' | 'reminder' | 'deep-work';
  color?: string;
  description?: string;
  location?: string;
  linkedNoteId?: string;
  taskId?: string;
}
```

Used by: `WeekDashboard` view. Powered by `dataService.getCalendarEvents()`.

### System 2: ScheduleItem

Defined inline in `frontend/services/dataService.ts` (not in `types.ts`):

```typescript
interface ScheduleItem {
  id: string;
  title: string;
  startTime: string;       // "HH:mm"
  durationMinutes: number;
  type: 'event' | 'task';
  taskId?: string;
}
```

Used by: `TodayDashboard` schedule timeline. Powered by `dataService.getTodaySchedule()` and `dataService.addToSchedule()`.

### The Conflict

These are functionally the same concept — a time-blocked entry on a timeline — but with different data shapes, different storage, and no synchronization. A task scheduled via the Today timeline doesn't appear on the Week calendar, and vice versa. The backend schema (`001_SCHEMA.md`) mirrors this by defining both `calendar_events` and `schedule_items` tables.

## Decision

**ScheduleItem is eliminated as a separate concept.** A scheduled item is a `CalendarEvent` (or, under the EAV model per ADR-0006, a page with `kind: event`).

### Mapping

| ScheduleItem field | CalendarEvent equivalent |
|---|---|
| `startTime: "09:00"` | `start: 2026-02-20T09:00` (full datetime with today's date) |
| `durationMinutes: 90` | `end: 2026-02-20T10:30` (computed from start + duration) |
| `type: 'task'` | `type: 'task'` (already exists in CalendarEvent) |
| `taskId` | `taskId` (already exists in CalendarEvent) |

### How It Works

1. **When a task is dragged onto the Today timeline**, a CalendarEvent page is created with:
   - `kind: event`
   - `type: task` (or `calendar_source: schedule` in the arch schema)
   - `taskId: <the task's page_id>` (relation property)
   - `start` / `end` computed from the drop position + estimated duration

2. **The Today Dashboard's timeline** queries the calendar collection filtered to today:
   ```
   collection_query("col_calendar", filters: [
     { key: "start", op: "gte", value: "today 00:00" },
     { key: "start", op: "lt", value: "tomorrow 00:00" }
   ], sorts: [{ key: "start", dir: "asc" }])
   ```

3. **The Week Dashboard** uses the same collection with a week-range filter. Both views see the same data.

4. **Duration** is derived: `end - start`. If the frontend needs `durationMinutes` for display, it computes it client-side. No separate field needed.

## Rationale

- **Data integrity:** One source of truth for "what's happening when." No drift between Today and Week views.
- **ADR-0006 alignment:** Under the EAV/Page model, ScheduleItem would need to be a page with its own `kind` — but it's functionally identical to an event. Creating a separate `kind: schedule_item` violates the DRY principle.
- **Simpler backend:** One collection query engine, one event collection. No `schedule_items` table.
- **Architecture alignment:** `003_TASKS_AND_PLANNING.md` Section 3 already defines the event schema with `start`, `end`, `linked_tasks`, and a calendar collection. The ScheduleItem is an accidental duplication.

## Consequences

- **Frontend migration (Phase 1):** `getTodaySchedule()` and `addToSchedule()` in `dataService.ts` are replaced by `getCalendarEvents()` filtered to today. `ScheduleItem` type is removed.
- **Phase 0 coexistence:** Until Phase 1, the divergence is accepted. The Today timeline continues to use `ScheduleItem` internally.
- **Backend schema (`001_SCHEMA.md`):** The `schedule_items` table is eliminated (already superseded by ADR-0006).
- **`003_TASKS_AND_PLANNING.md` Section 4.3:** Update the Phase 0 Divergence note to reference this ADR.

## Migration Path

Phase 1: When `dataService.ts` is replaced with Tauri IPC invokes, the `ScheduleItem` interface is removed. The Today timeline component receives `CalendarEvent[]` and renders them identically (extracting hour/duration from `start`/`end`). The drag-to-schedule interaction calls `vault_create_page(kind: "event", ...)` instead of `addToSchedule()`.
