# ADR-0003: Journal with Mood Tracking

**Status:** ACCEPTED
**Date:** 2026-02-19
**Deciders:** Frontend implementation (Phase 0)
**FR:** FR-010
**Supersedes:** N/A

---

## Context

The original architecture mentions `Notes/daily/` as a location for daily notes and an end-of-day journal prompt in the Today Dashboard (`003_TASKS_AND_PLANNING.md`, Section 4.4). However, it does not define a dedicated Journal module or structured mood tracking. Daily notes are simply `kind: note` pages.

During Phase 0, a distinct Journal module was implemented with structured mood classification, separate from the Notes module.

## Decision

Add a dedicated Journal module (not just daily notes) with:

- **Type:** `JournalEntry` with fields: id, date, content, mood (`Happy` | `Neutral` | `Sad` | `Stressed` | `Energetic`), tags (optional)
- **View:** `Journal.tsx` -- reverse-chronological feed with mood selector
- **Data:** CRUD via `dataService.ts` (`getJournalEntries`, `addJournalEntry`)
- **Feature flag:** `journal: boolean` (default ON)
- **AI integration:** Agent action `addJournalEntry` creates entries from natural language

## Consequences

- Journal entries are structurally distinct from Notes (they have `mood` as a first-class property)
- Backend should implement as `kind: journal_entry` pages with mood in frontmatter
- The mood enum becomes a `select` property in the collection schema
- Mood data enables future analytics (mood trends over time, correlation with habits/workouts)
- AI agent can create journal entries without HITL approval (see ADR-0005)

## Migration Path

Phase 1+: Journal CRUD moves to Tauri IPC. Backend normalizes to Page model with `kind: journal_entry`. Mood selector maps to a `select` property. Collection template defines schema with mood enum, reverse-chronological default sort.
