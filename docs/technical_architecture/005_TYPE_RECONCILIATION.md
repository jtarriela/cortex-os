# Cortex Life OS — Phase 0 → Phase 1 Type Reconciliation

**Status:** Draft v1
**Date:** 2026-02-19
**Parent:** `001_architecture.md`
**Scope:** Field-by-field mapping between Phase 0 frontend TypeScript interfaces and canonical Page model properties

---

## 0) Purpose

The Phase 0 frontend defines domain types as bespoke TypeScript interfaces in [types.ts](../../frontend/types.ts). The canonical architecture uses the **"Everything is a Page"** model where all entities are markdown files with YAML frontmatter, indexed into EAV properties.

This document maps every frontend field to its architectural equivalent, identifies mismatches, and specifies the migration action for Phase 1 IPC wiring. It replaces scattered "Phase 0 Divergence" notes with one authoritative reference.

**Legend:**

| Status | Meaning |
|--------|---------|
| ✅ Match | Frontend field maps 1:1 to a Page property |
| 🔄 Rename | Same concept, different name — rename during migration |
| ➕ Add | Architectural property not yet in frontend — add during Phase 1 |
| ➖ Drop | Frontend field has no architectural equivalent — remove or relocate |
| 🔀 Restructure | Fundamental model difference — requires code changes |

---

## 1) Task (`kind: task`)

**Frontend:** `Task` interface ([types.ts:93-108](../../frontend/types.ts#L93-L108))
**Architecture:** `003_TASKS_AND_PLANNING.md` Section 1, `002_COLLECTIONS.md` Section 1

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `title` | string | `title` | text | ✅ Match | |
| `description` | string? | Body content | markdown | ✅ Match | Moves to markdown body below frontmatter |
| `status` | `'TODO'\|'DOING'\|'DONE'\|'ARCHIVED'` | `status` | select (5 values) | ➕ Add | Add `BLOCKED` per ADR-0008 |
| `priority` | `'HIGH'\|'MEDIUM'\|'LOW'\|'NONE'` | `priority` | select | ✅ Match | |
| `dueDate` | string? | `due` | date | 🔄 Rename | `dueDate` → `due` |
| `projectRef` | string? | `project` | relation | 🔄 Rename | `projectRef` → `project` (path-based relation) |
| `linkedNoteId` | string? | Not in task schema | — | ➖ Drop | Use wiki-links in body or `graph_edges` |
| `assignee` | string? | `assignee` | text | ✅ Match | |
| `type` | string? | `area` | select | 🔄 Rename | `type` → `area`. Map: 'Dev'→'engineering', 'Work'→'work', etc. |
| `tags` | string[]? | `tags` | multi_select | ✅ Match | |
| `comments` | Comment[]? | Separate pages | kind: comment | 🔀 Restructure | Inline comments become linked comment pages. Phase 4. |
| `createdDate` | string | `created` | datetime | 🔄 Rename | `createdDate` → `created` |
| `boardColumnId` | string? | — | — | ➖ Drop | Board columns are view config, not page property. Status determines column. |
| — | — | `scheduled` | date | ➕ Add | Date when task is scheduled (distinct from due) |
| — | — | `start_time` | text | ➕ Add | Time of day when scheduled |
| — | — | `duration_min` | number | ➕ Add | Expected duration in minutes |
| — | — | `area` | select | ➕ Add | work, health, home, personal, learning, finance |
| — | — | `energy` | select | ➕ Add | high, medium, low |
| — | — | `recurring` | boolean | ➕ Add | Is this a recurring task? |
| — | — | `recurrence_rule` | text | ➕ Add | daily, weekdays, weekly:mon,wed, monthly:15 |
| — | — | `blocked_by` | multi_select | ➕ Add | IDs of blocking tasks (ADR-0008) |
| — | — | `completed_at` | datetime | ➕ Add | Timestamp of completion |

**`TaskStatus` type change:** `'TODO' | 'DOING' | 'DONE' | 'ARCHIVED'` → `'TODO' | 'DOING' | 'BLOCKED' | 'DONE' | 'ARCHIVED'`

---

## 2) Project (`kind: project`)

**Frontend:** `Project` interface ([types.ts:117-128](../../frontend/types.ts#L117-L128))
**Architecture:** `003_TASKS_AND_PLANNING.md` Section 2, `002_COLLECTIONS.md` Section 1

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `title` | string | `title` | text | ✅ Match | |
| `description` | string? | Body content | markdown | ✅ Match | Moves to markdown body |
| `status` | 5-value enum | `status` | select | ✅ Match | Same values |
| `priority` | 3-value enum | `priority` | select | ✅ Match | Architecture adds NONE option |
| `dateRange` | string? | `start` + `target_end` | date + date | 🔀 Restructure | Split "Jan 12 → May 11" into two date fields |
| `progress` | number | `progress` | number | ✅ Match | 0-100 |
| `milestones` | array | `milestones` | YAML array | ✅ Match | Frontend adds `tags` on milestones — not in arch spec |
| `artifacts` | array? | — | — | ➖ Drop / Define | AI-generated images. Store as `assets/` paths. Needs spec. |
| `columns` | array? | — | — | ➖ Drop | Board columns are view config, not page property |
| — | — | `area` | select | ➕ Add | work, health, home, personal, learning, finance |

---

## 3) CalendarEvent (`kind: event`)

**Frontend:** `CalendarEvent` interface ([types.ts:205-216](../../frontend/types.ts#L205-L216))
**Architecture:** `003_TASKS_AND_PLANNING.md` Section 3

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `title` | string | `title` | text | ✅ Match | |
| `start` | Date | `start` | datetime | 🔄 Rename | Use ISO string, not JS Date object (IPC serialization) |
| `end` | Date | `end` | datetime | 🔄 Rename | Same — ISO string |
| `type` | 4-value enum | Not in arch | — | ➖ Drop / Define | Consider as `event_type` select property or remove |
| `color` | string? | — | — | ➖ Drop | Move to view config or derive from event_type |
| `description` | string? | Body content | markdown | ✅ Match | Moves to markdown body |
| `location` | string? | `location` | location | ✅ Match | Arch expects lat/lng; frontend uses display name |
| `linkedNoteId` | string? | `linked_notes` | multi_select | 🔀 Restructure | Singular → plural array of relation paths |
| `taskId` | string? | `linked_tasks` | multi_select | 🔀 Restructure | Singular → plural array of relation paths |
| — | — | `all_day` | boolean | ➕ Add | Default false |
| — | — | `location_name` | text | ➕ Add | Human-readable location string |
| — | — | `calendar_source` | select | ➕ Add | cortex, google, outlook, caldav |
| — | — | `recurrence_rule` | text | ➕ Add | Recurring events |
| — | — | `reminder_min` | number | ➕ Add | Minutes before event |

**ScheduleItem** (defined in `dataService.ts:31-38`, not `types.ts`): Eliminated per ADR-0007. Replace all ScheduleItem usage with CalendarEvent filtered by today's date.

---

## 4) Habit (`kind: habit` + `kind: habit_log`)

**Frontend:** `Habit` interface ([types.ts:37-43](../../frontend/types.ts#L37-L43))
**Architecture:** `002_COLLECTIONS.md` Section 5

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `title` | string | `habit_name` | text | 🔄 Rename | `title` → `habit_name` |
| `frequency` | `'DAILY'\|'WEEKLY'` | `frequency` | select (4 values) | ➕ Add | Add `weekdays` and `custom` options |
| `streak` | number | `streak` | number | ✅ Match | |
| `completedDates` | string[] | Separate `habit_log` pages | kind: habit_log | 🔀 Restructure | **Major change.** Frontend stores completions inline. Architecture uses separate log pages per day. |

**Model difference:** The architecture splits habits into two page kinds:
- `kind: habit` — definition (name, frequency, target, streak)
- `kind: habit_log` — daily entries linked to the habit via relation

The frontend stores all completions as an inline `completedDates[]` array. Phase 1 migration must extract each date into a separate `habit_log` page, or the architecture must accept the inline model (requires an ADR amendment).

---

## 5) Goal (`kind: goal`)

**Frontend:** `Goal` interface ([types.ts:45-55](../../frontend/types.ts#L45-L55))
**Architecture:** `002_COLLECTIONS.md` Section 7, ADR-0001

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `title` | string | `title` | text | ✅ Match | |
| `description` | string? | `description` | text | ✅ Match | |
| `type` | 3-value enum | `goal_type` | select | 🔄 Rename | `type` → `goal_type` (avoid JS keyword) |
| `progress` | number | `progress` | number | ✅ Match | 0-100 |
| `targetDate` | string | `target_date` | date | 🔄 Rename | camelCase → snake_case |
| `status` | 3-value enum | `status` | select | ✅ Match | Same values |
| `projectId` | string? | `project` | relation | 🔄 Rename | `projectId` → `project` (path-based relation) |
| `notes` | string? | Body content | markdown | ✅ Match | Moves to markdown body |

---

## 6) Meal (`kind: meal`)

**Frontend:** `Meal` interface ([types.ts:57-64](../../frontend/types.ts#L57-L64))
**Architecture:** `002_COLLECTIONS.md` Section 8, ADR-0002

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `date` | string | `date` | date | ✅ Match | |
| `type` | 4-value enum | `meal_type` | select | 🔄 Rename | `type` → `meal_type` |
| `recipeId` | string? | `recipe` | relation | 🔄 Rename | `recipeId` → `recipe` (path-based) |
| `description` | string | `description` | text | ✅ Match | |
| `calories` | number? | `calories` | number | ✅ Match | |

> **Critical gap:** No `dataService.ts` functions exist for meals. CRUD is in-view state only. Must extract before Phase 1 IPC wiring.

---

## 7) Recipe (`kind: recipe`)

**Frontend:** `Recipe` interface ([types.ts:66-74](../../frontend/types.ts#L66-L74))
**Architecture:** `002_COLLECTIONS.md` Section 8, ADR-0002

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `title` | string | `title` | text | ✅ Match | |
| `ingredients` | string[] | `ingredients` | multi_select | ✅ Match | Array → multi_select mapping |
| `instructions` | string | `instructions` | text | ✅ Match | Could also be markdown body |
| `calories` | number? | `calories` | number | ✅ Match | |
| `tags` | string[]? | `tags` | multi_select | ✅ Match | |
| `imageUrl` | string? | `image_url` | url | 🔄 Rename | camelCase → snake_case |

> **Same gap as Meal:** No `dataService.ts` functions exist.

---

## 8) JournalEntry (`kind: journal_entry`)

**Frontend:** `JournalEntry` interface ([types.ts:29-35](../../frontend/types.ts#L29-L35))
**Architecture:** `002_COLLECTIONS.md` Section 9, ADR-0003

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `date` | string | `date` | date | ✅ Match | |
| `content` | string | Body content | markdown | 🔀 Restructure | `content` field → markdown body below frontmatter |
| `mood` | 5-value enum? | `mood` | select | ✅ Match | |
| `tags` | string[]? | `tags` | multi_select | ✅ Match | |

---

## 9) Trip (`kind: trip`)

**Frontend:** `Trip` interface ([types.ts:158-168](../../frontend/types.ts#L158-L168))
**Architecture:** `002_COLLECTIONS.md` Section 2

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `destination` | string | `destination` | text | ✅ Match | |
| `status` | 3-value enum | `status` | select (5 values) | ➕ Add | Arch adds `dreaming`, `in_progress` options |
| `path` | string | File path | — | ✅ Match | Vault path |
| `dates` | string? | `start` + `end` | date + date | 🔀 Restructure | Single display string → two date fields |
| `budget` | string? | `budget_usd` | currency | 🔄 Rename | String → number + rename |
| `imageUrl` | string? | `cover_image` | text | 🔄 Rename | `imageUrl` → `cover_image` |
| `cards` | Note[] | Child pages | kind: trip_item | 🔀 Restructure | Typed as Note[] but should be trip_items |

---

## 10) Workout (`kind: workout`)

**Frontend:** `Workout` interface ([types.ts:196-202](../../frontend/types.ts#L196-L202))
**Architecture:** `002_COLLECTIONS.md` Section 4, ADR-0009

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `name` | string | `title` | text | 🔄 Rename | `name` → `title` (Page convention) |
| `date` | string | `date` | date | ✅ Match | |
| `exercises` | number | — | — | ➖ Drop | Derived from body content (exercise table rows) |
| `duration` | string | `duration_min` | number | 🔀 Restructure | String "65 min" → number 65 |

> Module deferred to Phase 4 (ADR-0009). Feature flag defaults to OFF.

---

## 11) Finance Types

### ManualAccount (`kind: account`)

**Frontend:** `ManualAccount` interface ([types.ts:188-194](../../frontend/types.ts#L188-L194))
**Architecture:** `002_COLLECTIONS.md` Section 3

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `name` | string | `account_name` | text | 🔄 Rename | |
| `type` | 4-value enum | `account_type` | select | ✅ Match | Add `budget_category` option |
| `balance` | number | `balance` | currency | ✅ Match | |
| `path` | string | File path | — | ✅ Match | |

### Transaction (`kind: transaction`)

**Frontend:** `Transaction` interface ([types.ts:178-186](../../frontend/types.ts#L178-L186))
**Architecture:** `002_COLLECTIONS.md` Section 3

| Frontend Field | Type | Arch Property | Type | Status | Migration Note |
|---------------|------|--------------|------|--------|----------------|
| `id` | string | `id` | text | ✅ Match | |
| `merchant` | string | `vendor` | text | 🔄 Rename | `merchant` → `vendor` |
| `amount` | number | `amount` | currency | ✅ Match | |
| `category` | string | `category` | select | ✅ Match | |
| `date` | string | `transaction_date` | date | 🔄 Rename | |
| `account` | string | — | relation | 🔄 Rename | Should be relation to account page |
| `cleared` | boolean | — | — | ➕ Add / Define | Not in architecture schema — add or derive |

---

## 12) AI Types

**Frontend:** `AISettings` interface ([types.ts:229-242](../../frontend/types.ts#L229-L242))
**Architecture:** `004_AI_INTEGRATION.md` Section 2, ADR-0013

| Frontend Field | Type | Arch Property | Status | Migration Note |
|---------------|------|--------------|--------|----------------|
| `geminiKey` | string | OS Keychain (encrypted) | 🔀 Restructure | Keys move to encrypted backend storage (Section 3) |
| `openaiKey` | string | OS Keychain | 🔀 Restructure | Same |
| `claudeKey` | string | OS Keychain | 🔀 Restructure | Same |
| `activeModelId` | string | `default_chat_model` | 🔄 Rename | |
| `voiceEnabled` | boolean | Derived | ➖ Drop | Implied by stt/tts provider selection |
| `autoSpeak` | boolean | `auto_speak` | ✅ Match | |
| `preferredVoice` | 5-value Gemini enum | `preferred_voice` | 🔀 Restructure | Becomes provider-specific (ADR-0013) |
| `enableChat` | boolean | — | ➖ Drop | Always enabled when provider configured |
| `enableAgent` | boolean | — | ➖ Drop | Controlled by tool availability |
| `enableTranscription` | boolean | Derived | ➖ Drop | Enabled when STT provider is set |
| `enableSpeech` | boolean | Derived | ➖ Drop | Enabled when TTS provider is set |
| `enableLive` | boolean | — | ➖ Drop | Phase 5+ feature |
| — | — | `stt_provider` | ➕ Add | 'local_whisper' \| 'openai' \| 'gemini' |
| — | — | `tts_provider` | ➕ Add | 'gemini' \| 'openai' \| 'local' |
| — | — | `default_embed_model` | ➕ Add | |
| — | — | `default_quick_model` | ➕ Add | |

---

## 13) Types with No Page Equivalent

These frontend types are UI/infrastructure concerns, not vault pages:

| Type | Purpose | Phase 1 Action |
|------|---------|----------------|
| `NavSection` (enum) | View routing | Keep as-is (frontend-only) |
| `FeatureFlags` | Module toggles | Moves to `AppSettings.features` |
| `NoteRef` | Cross-reference hint | Unused — remove |
| `Comment` | Embedded on Task | Extract to separate pages or keep inline (needs decision) |
| `ProjectTemplate` | Template catalog | Moves to app config / `.cortex/templates/` |
| `Area` | Dashboard widget | UI concern — keep as-is |
| `FileNode` | Vault file tree | Replace with vault IPC response type |
| `Note` | Generic note display | Maps to `kind: note` Page |
| `YNABBudgetMonth` | YNAB API response | Keep as API-specific type |
| `SearchResult` | Search UI | Replace with `collection_query` result + FTS response |
| `AIModel` | Model picker | Keep, populate from provider auto-detection |
| `AgentAction` | Tool call dispatch | Replace with provider-agnostic `ToolDef` / `ToolCall` |
| `FocusTarget` | Right drawer routing | Keep as-is (frontend-only) |
| `AppState` | Root UI state | Migrates to Zustand stores |

---

## 14) Naming Convention Summary

| Phase 0 (Frontend) | Phase 1 (Architecture) | Rule |
|--------------------|-----------------------|------|
| `camelCase` fields | `snake_case` properties | All frontmatter properties use snake_case |
| `*Id` suffix for relations | Path-based or `*` relation | Relations use vault paths, not bare IDs |
| `Date` objects | ISO 8601 strings | All dates/datetimes are ISO strings across IPC |
| Inline arrays (comments, completedDates) | Separate pages via relations | Complex sub-entities become their own pages |
| String enums with mixed case | Lowercase or UPPER_CASE selects | Consistent per collection schema definition |
