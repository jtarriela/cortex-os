# ADR-0001: Goals Module

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Frontend implementation (Phase 0)
**FR:** FR-012
**Supersedes:** N/A

---

## Context

The original technical architecture (`002_COLLECTIONS.md`) defines these domain modules as shipped collection templates: Tasks, Projects, Calendar, Travel, Finance, Workouts, Habits, Notes, Reading. **Goals is entirely absent** from the original vision.

During Phase 0 frontend prototyping, a Goals module was implemented to track monthly, yearly, and long-term objectives with progress tracking and optional project linkage.

## Decision

Add a Goals domain module to Cortex OS with:

- **Type:** `Goal` with fields: id, title, description, type (`MONTHLY` | `YEARLY` | `LONG_TERM`), progress (0-100), targetDate, status (`IN_PROGRESS` | `COMPLETED` | `FAILED`), projectId (optional), createdAt
- **View:** `Goals.tsx` -- card-based gallery with progress bars
- **Data:** In-memory CRUD via `dataService.ts` (`getGoals`, `addGoal`, `updateGoal`)
- **Feature flag:** `goals: boolean` (default ON)
- **AI integration:** Agent action `addGoal` creates goals from natural language

## Consequences

- Backend must support a `goal` kind in the Page model or a dedicated collection
- Goals can link to Projects via `projectId` (cross-collection relation)
- AI agent can create goals without HITL approval (divergence from HITL principle; see ADR-0005)
- Collection template needed: `goals.json` with appropriate schema and views

## Migration Path

Phase 1+: Goal CRUD moves from `dataService.ts` to Tauri IPC `goals.*` commands. Backend normalizes to Page model with `kind: goal`. Collection template defines schema, selector, and default views (Gallery, Board by status).
